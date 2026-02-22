import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ca_entry.dart';
import '../services/ca_scan_service.dart';
import '../main.dart' show scanCacheServiceProvider;
import 'folder_scan_providers.dart';

// ═══════════════════════════════════════════════════════════
// CA SCAN SERVICE — derived from project path
// ═══════════════════════════════════════════════════════════

final caScanServiceProvider = Provider<CaScanService>((ref) {
  return CaScanService(ref.watch(projectPathProvider));
});

// ═══════════════════════════════════════════════════════════
// SCANNED CA ENTRIES — auto-populated from folder structure
// Falls back to cached data when network drive is unreachable.
// ═══════════════════════════════════════════════════════════

/// Factory: creates a cached CA scan provider — eliminates 12-line boilerplate.
/// CACHE-FIRST: CA scans return cached data instantly, rescan when background sync signals.
FutureProvider<List<CaEntry>> _cachedCaScan(String type, String path, String cacheKey) {
  return FutureProvider<List<CaEntry>>((ref) async {
    ref.watch(scanRefreshProvider);
    ref.keepAlive();
    final cache = ref.watch(scanCacheServiceProvider);
    final liveData = ref.watch(backgroundFileDataProvider);
    final cached = cache.loadCaEntries(cacheKey);
    // Return cache instantly if no live scan data yet
    if (cached != null && cached.isNotEmpty && (liveData == null || liveData.isEmpty)) {
      return cached;
    }
    final svc = ref.watch(caScanServiceProvider);
    try {
      final result = await svc.scanCaFolder(type, path);
      await cache.saveCaEntries(cacheKey, result);
      return result;
    } catch (_) {
      return cached ?? [];
    }
  });
}

final scannedCaRfisProvider = _cachedCaScan('RFI', r'0 Project Management\Construction Admin\RFIs', 'caRfis');
final scannedCaAsisProvider = _cachedCaScan('ASI', r'0 Project Management\Construction Admin\ASIs', 'caAsis');
final scannedCaChangeOrdersProvider = _cachedCaScan('CO', r'0 Project Management\Construction Admin\Change Orders', 'caCOs');
final scannedCaSubmittalsProvider = _cachedCaScan('SUB', r'0 Project Management\Construction Admin\Submittals', 'caSubs');
final scannedCaPunchlistsProvider = _cachedCaScan('PL', r'0 Project Management\Construction Admin\Punchlist Documents', 'caPLs');

// ═══════════════════════════════════════════════════════════
// AGGREGATE: Total CA counts for dashboard
// ═══════════════════════════════════════════════════════════

final caCountsProvider = Provider<Map<String, int>>((ref) {
  final rfis = ref.watch(scannedCaRfisProvider).valueOrNull ?? [];
  final asis = ref.watch(scannedCaAsisProvider).valueOrNull ?? [];
  final cos = ref.watch(scannedCaChangeOrdersProvider).valueOrNull ?? [];
  final subs = ref.watch(scannedCaSubmittalsProvider).valueOrNull ?? [];
  final pls = ref.watch(scannedCaPunchlistsProvider).valueOrNull ?? [];
  return {
    'RFI': rfis.length,
    'ASI': asis.length,
    'CO': cos.length,
    'SUB': subs.length,
    'PL': pls.length,
    'total': rfis.length + asis.length + cos.length + subs.length + pls.length,
  };
});

// Force-invalidate all keepAlive CA scan providers on project switch.
void invalidateAllCaScanProviders(WidgetRef ref) {
  ref.invalidate(scannedCaRfisProvider);
  ref.invalidate(scannedCaAsisProvider);
  ref.invalidate(scannedCaChangeOrdersProvider);
  ref.invalidate(scannedCaSubmittalsProvider);
  ref.invalidate(scannedCaPunchlistsProvider);
}
