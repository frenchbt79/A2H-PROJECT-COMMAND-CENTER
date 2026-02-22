import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai_service.dart';
import '../main.dart' show storageServiceProvider;

/// ═══════════════════════════════════════════════════════════
/// AI PROVIDERS — Riverpod wiring for AI features
/// ═══════════════════════════════════════════════════════════
///
/// HOW PROVIDERS WORK WITH AI:
///
/// In Riverpod, a Provider is a global "container" for a value. Other
/// widgets/providers can "watch" it to get the current value and rebuild
/// when it changes.
///
/// For AI, we need:
///   1. aiServiceProvider — the singleton AiService instance
///   2. aiEnabledProvider — reactive bool for UI toggle
///   3. aiModelProvider   — reactive string for model selection
///   4. Feature-specific providers (title block, QA, etc.)

// ── Singleton AiService ─────────────────────────────────────

/// The core AI service instance. Initialized once at app startup.
/// All AI features go through this single service.
final aiServiceProvider = Provider<AiService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final ai = AiService();
  ai.initWith(storage.prefs);
  return ai;
});

/// Whether AI features are enabled (user toggle in settings).
final aiEnabledProvider = StateProvider<bool>((ref) {
  return ref.watch(aiServiceProvider).isEnabled;
});

/// Currently selected model.
final aiModelProvider = StateProvider<String>((ref) {
  return ref.watch(aiServiceProvider).model;
});

/// Whether an API key is configured.
final aiHasKeyProvider = Provider<bool>((ref) {
  return ref.watch(aiServiceProvider).hasApiKey;
});
