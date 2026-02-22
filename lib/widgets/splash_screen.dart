import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/tokens.dart';
import '../state/folder_scan_providers.dart';
import '../state/ca_scan_providers.dart';
import '../services/background_sync_service.dart';
import '../main.dart' show scanCacheServiceProvider;

/// Animated splash screen with CACHE-FIRST strategy.
///
/// - WARM START (cache exists): Show splash ~600ms, then app. Background sync after.
/// - COLD START (first run): Show progress bar while scanning, transition at 60%.
class SplashScreen extends ConsumerStatefulWidget {
  final VoidCallback onReady;
  const SplashScreen({super.key, required this.onReady});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeIn;
  late final Animation<double> _titleSlide;

  String _statusText = 'Loading...';
  bool _readyFired = false;
  bool _isColdStart = false;

  /// Labeled scan steps — used ONLY during cold start (no cache).
  static final _warmupSteps = <({String label, FutureProvider provider})>[
    (label: 'Scanning project files…', provider: allProjectFilesProvider),
    (label: 'Loading Contracts…', provider: scannedContractsProvider),
    (label: 'Reading contract metadata…', provider: contractMetadataProvider),
    (label: 'Loading Fee Worksheets…', provider: scannedFeeWorksheetsProvider),
    (label: 'Extracting fee data…', provider: feeWorksheetsProvider),
    (label: 'Loading Contacts…', provider: scannedContactsProvider),
    (label: 'Scanning project info forms…', provider: infoFormsProvider),
    (label: 'Populating project info…', provider: autoPopulateProjectInfoProvider),
    (label: 'Loading drawings — General…', provider: scannedGeneralProvider),
    (label: 'Loading drawings — Structural…', provider: scannedStructuralProvider),
    (label: 'Loading drawings — Architectural…', provider: scannedArchitecturalProvider),
    (label: 'Loading drawings — Civil…', provider: scannedCivilProvider),
    (label: 'Loading drawings — Landscape…', provider: scannedLandscapeProvider),
    (label: 'Loading drawings — Mechanical…', provider: scannedMechanicalProvider),
    (label: 'Loading drawings — Electrical…', provider: scannedElectricalProvider),
    (label: 'Loading drawings — Plumbing…', provider: scannedPlumbingProvider),
    (label: 'Loading drawings — Fire Protection…', provider: scannedFireProtectionProvider),
    (label: 'Reading sheet index…', provider: latestSheetIndexPdfProvider),
    (label: 'Loading RFI documents…', provider: scannedRfiPdfsProvider),
    (label: 'Loading ASI documents…', provider: scannedAsiPdfsProvider),
    (label: 'Loading Addendum documents…', provider: scannedAddendumPdfsProvider),
    (label: 'Scanning CA — RFIs…', provider: scannedCaRfisProvider),
    (label: 'Scanning CA — ASIs…', provider: scannedCaAsisProvider),
    (label: 'Scanning CA — Change Orders…', provider: scannedCaChangeOrdersProvider),
    (label: 'Scanning CA — Submittals…', provider: scannedCaSubmittalsProvider),
    (label: 'Scanning CA — Punchlists…', provider: scannedCaPunchlistsProvider),
    (label: 'Loading client-provided docs…', provider: scannedClientProvidedProvider),
    (label: 'Loading project photos…', provider: scannedPhotosProvider),
    (label: 'Loading specifications…', provider: scannedSpecsProvider),
    (label: 'Loading progress prints…', provider: scannedProgressPrintsProvider),
    (label: 'Loading signed prints…', provider: scannedSignedPrintsProvider),
    (label: 'Loading renderings…', provider: scannedRenderingsProvider),
    (label: 'Discovering milestones…', provider: discoveredMilestonesProvider),
    (label: 'Analyzing phase dates…', provider: phaseFileDatesProvider),
    (label: 'Extracting codes & standards…', provider: gSeriesCodesProvider),
    (label: 'Enriching drawing metadata…', provider: drawingMetadataProvider),
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _titleSlide = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut),
    );
    _fadeCtrl.forward();

    // Check cache after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkCacheState());
  }

  void _checkCacheState() {
    final cache = ref.read(scanCacheServiceProvider);
    final hasCache = cache.loadFiles('allProjectFiles') != null;

    if (hasCache) {
      // ── WARM START: cache exists → show app fast ──
      debugPrint('[SPLASH] Warm start — cache found, fast transition');
      setState(() => _statusText = 'Loading from cache...');
      Future.delayed(const Duration(milliseconds: 600), () {
        _fireReady();
        // Start background sync AFTER app is visible
        Future.delayed(const Duration(milliseconds: 500), () {
          _startBackgroundSync();
        });
      });
    } else {
      // ── COLD START: no cache → show progress, wait for scan ──
      debugPrint('[SPLASH] Cold start — no cache, scanning...');
      setState(() {
        _isColdStart = true;
        _statusText = 'First launch — scanning project files...';
      });
      // Don't block forever
      Future.delayed(const Duration(seconds: 15), () => _fireReady());
    }
  }

  void _startBackgroundSync() {
    final container = ProviderScope.containerOf(context);
    BackgroundSyncService.sync(container);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _fireReady() {
    if (!_readyFired && mounted) {
      _readyFired = true;
      widget.onReady();
    }
  }

  @override
  Widget build(BuildContext context) {
    double progress = 0;
    String? currentStepLabel;

    if (_isColdStart) {
      // Cold start: track provider progress
      int loadedCount = 0;
      for (final step in _warmupSteps) {
        final state = ref.watch(step.provider);
        if (state is AsyncData || state is AsyncError) {
          loadedCount++;
        } else if (currentStepLabel == null) {
          currentStepLabel = step.label;
        }
      }
      progress = loadedCount / _warmupSteps.length;

      String newStatus;
      if (loadedCount == 0) {
        newStatus = currentStepLabel ?? 'Scanning project folders…';
      } else if (progress >= 1.0) {
        newStatus = 'Ready';
      } else {
        newStatus = currentStepLabel ?? 'Scanning project files…';
      }

      if (newStatus != _statusText) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _statusText = newStatus);
        });
      }

      // Transition at 60%
      if (progress >= 0.6 && !_readyFired) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _fireReady();
          Future.delayed(const Duration(milliseconds: 500), () {
            _startBackgroundSync();
          });
        });
      }
    } else {
      // Warm start: smooth progress fill
      final cacheReady = ref.watch(cacheReadyProvider);
      if (cacheReady) progress = 1.0;
    }

    return Material(
      child: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.3),
            radius: 1.2,
            colors: [
              Color(0xFF3A2A18),
              Color(0xFF141210),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -80,
              bottom: -80,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF2E2018).withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: AnimatedBuilder(
                animation: _fadeCtrl,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeIn.value,
                    child: Transform.translate(
                      offset: Offset(0, _titleSlide.value),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // App icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Tokens.accent.withValues(alpha: 0.3),
                            blurRadius: 40,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          'assets/icon_512.png',
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'A2H PROJECT',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Tokens.accent,
                        letterSpacing: 6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'DASHBOARD',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Tokens.textPrimary,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Progress bar
                    SizedBox(
                      width: 200,
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: _isColdStart ? progress : 1.0),
                              duration: Duration(milliseconds: _isColdStart ? 400 : 500),
                              curve: Curves.easeOut,
                              builder: (context, value, _) {
                                return LinearProgressIndicator(
                                  value: value,
                                  backgroundColor:
                                      Tokens.glassBorder.withValues(alpha: 0.2),
                                  valueColor: const AlwaysStoppedAnimation(
                                      Tokens.accent),
                                  minHeight: 3,
                                );
                              },
                            ),
                          ),
                          if (_isColdStart) ...[
                            const SizedBox(height: 8),
                            Text(
                              '${(progress * _warmupSteps.length).round()} / ${_warmupSteps.length}',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: Tokens.textMuted.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _statusText,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Tokens.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 60),
                    Text(
                      'v1.1.0',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Tokens.textMuted.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
