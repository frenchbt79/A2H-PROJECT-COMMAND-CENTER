import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scanned_file.dart';
import '../main.dart' show scanCacheServiceProvider;
import '../state/folder_scan_providers.dart';

/// Background sync engine — scans I: drive without blocking the UI.
///
/// The app shows cached data instantly on launch. This service runs
/// in the background to refresh the cache and update providers
/// incrementally as new data arrives.
class BackgroundSyncService {
  static bool _isRunning = false;
  static DateTime? _lastSyncTime;

  /// Whether a background sync is currently in progress.
  static bool get isRunning => _isRunning;

  /// When the last successful sync completed.
  static DateTime? get lastSyncTime => _lastSyncTime;

  /// Run a full background sync. Safe to call multiple times — only one
  /// sync runs at a time.
  static Future<void> sync(
    ProviderContainer container, {
    void Function(String status, double progress)? onProgress,
  }) async {
    if (_isRunning) {
      debugPrint('[SYNC] Already running, skipping');
      return;
    }
    _isRunning = true;
    debugPrint('[SYNC] Starting background sync...');
    container.read(syncStatusProvider.notifier).state = const SyncStatus(
      state: SyncState.syncing, message: 'Starting sync...', progress: 0.0,
    );

    try {
      final svc = container.read(folderScanServiceProvider);
      final cache = container.read(scanCacheServiceProvider);

      // ── Phase 1: Full file scan ──
      onProgress?.call('Scanning project files...', 0.1);
      container.read(syncStatusProvider.notifier).state = const SyncStatus(
        state: SyncState.syncing, message: 'Scanning files...', progress: 0.1,
      );
      final stopwatch = Stopwatch()..start();

      List<ScannedFile> freshFiles;
      try {
        freshFiles = await svc.scanFolderRecursive('');
      } catch (e) {
        debugPrint('[SYNC] File scan failed: $e');
        _isRunning = false;
        container.read(syncStatusProvider.notifier).state = SyncStatus(
          state: SyncState.error, message: 'Scan failed: $e',
        );
        return;
      }

      debugPrint('[SYNC] Scanned ${freshFiles.length} files in ${stopwatch.elapsedMilliseconds}ms');
      onProgress?.call('Processing ${freshFiles.length} files...', 0.4);

      // ── Phase 2: Check if anything changed ──
      final cachedFiles = cache.loadFiles('allProjectFiles');
      final bool filesChanged = _hasChanged(cachedFiles, freshFiles);

      if (!filesChanged) {
        debugPrint('[SYNC] No changes detected, marking online');
        container.read(offlineModeProvider.notifier).state = false;
        _lastSyncTime = DateTime.now();
        _isRunning = false;
        onProgress?.call('Up to date', 1.0);
        container.read(syncStatusProvider.notifier).state = SyncStatus(
          state: SyncState.done, message: 'Up to date', progress: 1.0, lastSync: _lastSyncTime,
        );
        return;
      }

      // ── Phase 3: Save new cache and push live data ──
      onProgress?.call('Updating cache...', 0.6);
      container.read(syncStatusProvider.notifier).state = const SyncStatus(
        state: SyncState.syncing, message: 'Updating cache...', progress: 0.6,
      );
      await cache.saveFiles('allProjectFiles', freshFiles);

      // Push fresh data — this triggers allProjectFilesProvider and all
      // derived providers to re-evaluate with the new file list
      container.read(offlineModeProvider.notifier).state = false;
      container.read(backgroundFileDataProvider.notifier).state = freshFiles;

      debugPrint('[SYNC] Cache updated, ${freshFiles.length} files (was ${cachedFiles?.length ?? 0})');
      onProgress?.call('Refreshing metadata...', 0.8);

      // ── Phase 4: Invalidate providers that do their own I: drive scans ──
      // These need to re-scan since backgroundFileDataProvider signals "live data available"
      container.invalidate(discoveredMilestonesProvider);
      container.invalidate(phaseFileDatesProvider);
      container.invalidate(contractMetadataProvider);
      container.invalidate(feeWorksheetsProvider);
      container.invalidate(infoFormsProvider);

      // ── Phase 5: Check if G-sheets changed → re-extract codes ──
      final lastCodesScan = cache.lastCacheTime('gSeriesCodes');
      final gSheets = freshFiles.where((f) {
        final rel = f.relativePath.toLowerCase();
        return rel.contains('scanned drawings') &&
            f.name.toLowerCase().startsWith('g') &&
            f.extension.toLowerCase() == '.pdf';
      }).toList();

      final bool gSheetsChanged = lastCodesScan == null ||
          gSheets.any((f) => f.modified.isAfter(lastCodesScan));

      if (gSheetsChanged) {
        debugPrint('[SYNC] G-sheets changed, invalidating code extraction');
        container.invalidate(gSeriesCodesProvider);
        container.invalidate(projectDataSheetProvider);
        container.invalidate(sheetIndexProvider);
      }

      // Drawing metadata will auto-refresh since it watches backgroundFileDataProvider
      container.invalidate(drawingMetadataProvider);

      _lastSyncTime = DateTime.now();
      stopwatch.stop();
      debugPrint('[SYNC] Complete in ${stopwatch.elapsedMilliseconds}ms');
      onProgress?.call('Sync complete', 1.0);
      container.read(syncStatusProvider.notifier).state = SyncStatus(
        state: SyncState.done, message: 'Sync complete', progress: 1.0, lastSync: _lastSyncTime,
      );
    } catch (e, stack) {
      debugPrint('[SYNC] ERROR: $e\n$stack');
      container.read(syncStatusProvider.notifier).state = SyncStatus(
        state: SyncState.error, message: 'Sync error: $e',
      );
    } finally {
      _isRunning = false;
    }
  }

  /// Quick check: did the file list change since last cache?
  static bool _hasChanged(List<ScannedFile>? cached, List<ScannedFile> fresh) {
    if (cached == null || cached.isEmpty) return true;
    if (cached.length != fresh.length) return true;

    // Compare newest modified date (fast heuristic)
    final cachedNewest = cached
        .map((f) => f.modified)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final freshNewest = fresh
        .map((f) => f.modified)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    return freshNewest.isAfter(cachedNewest);
  }
}
