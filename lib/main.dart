import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/storage_service.dart';
import 'services/scan_cache_service.dart';
import 'state/folder_scan_providers.dart';

final storageServiceProvider = Provider<StorageService>((ref) => StorageService());
final scanCacheServiceProvider = Provider<ScanCacheService>((ref) => ScanCacheService());

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = StorageService();
  await storage.init();

  final scanCache = ScanCacheService();
  await scanCache.init();

  // Load saved projects and active project
  final savedActiveId = storage.loadActiveProjectId();
  final savedProjects = storage.loadProjects();

  // Resolve project path: use active project's folder, fall back to saved path
  String savedPath = storage.loadProjectPath();
  if (savedActiveId != null && savedProjects.isNotEmpty) {
    try {
      final active = savedProjects.firstWhere((p) => p.id == savedActiveId);
      savedPath = active.folderPath;
    } catch (_) {
      // Active ID not found in projects list — use saved path as-is
    }
  }

  // Set per-project namespacing on both services
  if (savedActiveId != null) {
    storage.setProjectId(savedActiveId);
    scanCache.setProjectId(savedActiveId);
  }

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
        scanCacheServiceProvider.overrideWithValue(scanCache),
        projectPathProvider.overrideWith((ref) => savedPath),
        activeProjectIdProvider.overrideWith((ref) => savedActiveId),
      ],
      child: const App(),
    ),
  );
}
