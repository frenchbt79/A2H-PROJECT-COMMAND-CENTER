import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project_models.dart';
import '../main.dart' show storageServiceProvider, scanCacheServiceProvider;
import '../services/background_sync_service.dart';
import 'folder_scan_providers.dart';
import 'ca_scan_providers.dart';

/// Consolidates all steps needed to switch active project.
///
/// Uses staggered invalidation to prevent UI freeze:
/// 1. Core state updates (instant)
/// 2. Primary data provider (triggers cascade)
/// 3. Background: heavy providers after frame
class ProjectSwitcher {
  static void switchProject(WidgetRef ref, ProjectEntry project) {
    final storage = ref.read(storageServiceProvider);
    final cache = ref.read(scanCacheServiceProvider);
    final stopwatch = Stopwatch()..start();

    // 1. Update service-level project scope
    storage.setProjectId(project.id);
    cache.setProjectId(project.id);

    // 2. Reset state flags
    ref.read(backgroundFileDataProvider.notifier).state = null;
    ref.read(offlineModeProvider.notifier).state = false;

    // 3. Update active project providers
    ref.read(activeProjectIdProvider.notifier).state = project.id;
    ref.read(projectPathProvider.notifier).state = project.folderPath;

    // 4. Persist to storage
    storage.saveActiveProjectId(project.id);
    storage.saveProjectPath(project.folderPath);

    // 5. Invalidate ONLY the root provider — derived providers cascade automatically
    ref.invalidate(allProjectFilesProvider);
    ref.invalidate(rootAccessibleProvider);
    ref.read(scanRefreshProvider.notifier).state++;

    // 6. CA providers (lightweight, mostly in-memory)
    invalidateAllCaScanProviders(ref);

    debugPrint('[SWITCH] Phase 1 complete in ${stopwatch.elapsedMilliseconds}ms');

    // 7. Stagger heavy providers — run AFTER current frame paints
    Future.delayed(const Duration(milliseconds: 100), () {
      // Phase 2: metadata + enrichment (these open PDFs)
      ref.invalidate(gSeriesCodesProvider);
      ref.invalidate(projectDataSheetProvider);
      ref.invalidate(sheetIndexProvider);
      ref.invalidate(drawingMetadataProvider);
      ref.invalidate(enrichProjectInfoProvider);
      ref.invalidate(autoPopulateProjectInfoProvider);
      debugPrint('[SWITCH] Phase 2 (metadata) invalidated at ${stopwatch.elapsedMilliseconds}ms');
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      // Phase 3: secondary providers
      ref.invalidate(discoveredMilestonesProvider);
      ref.invalidate(phaseFileDatesProvider);
      ref.invalidate(contractMetadataProvider);
      ref.invalidate(feeWorksheetsProvider);
      ref.invalidate(infoFormsProvider);
      ref.invalidate(sheetValidationProvider);
      ref.invalidate(weatherProvider);
      debugPrint('[SWITCH] Phase 3 (secondary) invalidated at ${stopwatch.elapsedMilliseconds}ms');
    });

    // 8. Trigger background sync after UI is stable
    Future.delayed(const Duration(milliseconds: 800), () {
      final container = ProviderScope.containerOf(ref.context);
      BackgroundSyncService.sync(container);
      debugPrint('[SWITCH] Background sync started at ${stopwatch.elapsedMilliseconds}ms');
    });
  }
}
