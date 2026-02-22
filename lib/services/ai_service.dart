import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// ═══════════════════════════════════════════════════════════
/// AI SERVICE — connects your app to Claude's API
/// ═══════════════════════════════════════════════════════════
///
/// HOW THIS WORKS (the architecture):
///
/// 1. Your app stores an API key locally in SharedPreferences (encrypted-ish,
///    base64-encoded — not true encryption but keeps it out of plain text).
///
/// 2. When a feature needs AI (title block reading, QA reports, etc.),
///    it calls a method on this service with context (text, image bytes, etc.)
///
/// 3. This service builds the HTTP request to Anthropic's Messages API,
///    sends it, and returns structured results.
///
/// 4. The API call pattern is always:
///    - System prompt: tells Claude what role to play and output format
///    - User message: the actual content (text, images, PDFs)
///    - Response: structured JSON that your app can parse
///
/// KEY CONCEPTS:
/// - "Messages API" = Anthropic's chat completion endpoint
/// - "System prompt" = instructions that shape Claude's behavior
/// - "Vision" = sending images (base64) for Claude to analyze
/// - "Structured output" = asking Claude to respond in JSON format
/// - "Tokens" = billing unit (~4 chars = 1 token). Input + output tokens = cost.
///
/// COST REALITY (Sonnet 4, the sweet spot for this app):
///   Input:  $3 / million tokens  (~750,000 words for $3)
///   Output: $15 / million tokens (~250,000 words for $15)
///   A title block read = ~2K input + 200 output ≈ $0.009 (less than a penny)
///   A full sheet set QA (50 sheets) ≈ $0.50
///
class AiService {
  static const _keyApiKey = 'pcc_ai_api_key';
  static const _keyModel = 'pcc_ai_model';
  static const _keyEnabled = 'pcc_ai_enabled';

  /// Default model — Sonnet is the best price/performance for document tasks.
  /// Haiku is cheaper for simple extraction. Opus for complex reasoning.
  static const defaultModel = 'claude-sonnet-4-20250514';

  static const _baseUrl = 'https://api.anthropic.com/v1/messages';
  static const _apiVersion = '2023-06-01';

  late final SharedPreferences _prefs;

  /// Call after StorageService.init() — shares the same SharedPreferences.
  void initWith(SharedPreferences prefs) {
    _prefs = prefs;
  }

  // ── API Key Management ────────────────────────────────────

  /// Store the API key (base64 encoded to keep out of plain text).
  Future<void> setApiKey(String key) async {
    final encoded = base64Encode(utf8.encode(key));
    await _prefs.setString(_keyApiKey, encoded);
  }

  /// Retrieve the API key (decoded).
  String? getApiKey() {
    final encoded = _prefs.getString(_keyApiKey);
    if (encoded == null || encoded.isEmpty) return null;
    try {
      return utf8.decode(base64Decode(encoded));
    } catch (_) {
      return null;
    }
  }

  /// Check if API key is configured.
  bool get hasApiKey => getApiKey() != null;

  /// Remove the stored API key.
  Future<void> clearApiKey() async {
    await _prefs.remove(_keyApiKey);
  }

  /// Get/set the model to use.
  String get model => _prefs.getString(_keyModel) ?? defaultModel;
  Future<void> setModel(String m) => _prefs.setString(_keyModel, m);

  /// Get/set whether AI features are enabled.
  bool get isEnabled => _prefs.getBool(_keyEnabled) ?? true;
  Future<void> setEnabled(bool v) => _prefs.setBool(_keyEnabled, v);

  // ── Core API Call ─────────────────────────────────────────
  //
  // This is the foundation everything else builds on.
  // Every AI feature in the app ultimately calls this method.
  //
  // Parameters:
  //   systemPrompt — tells Claude how to behave and what format to use
  //   messages     — the conversation (usually just one user message)
  //   maxTokens    — cap on response length (saves money, prevents runaway)
  //   temperature  — 0.0 = deterministic, 1.0 = creative. For extraction use 0.

  /// Send a message to Claude and get a text response.
  /// Returns the assistant's text content, or throws on error.
  Future<String> complete({
    required String systemPrompt,
    required List<Map<String, dynamic>> messages,
    int maxTokens = 1024,
    double temperature = 0.0,
  }) async {
    final apiKey = getApiKey();
    if (apiKey == null) {
      throw AiServiceException('No API key configured. Go to Settings → AI.');
    }
    if (!isEnabled) {
      throw AiServiceException('AI features are disabled in Settings.');
    }

    // Build the request body — this is the Anthropic Messages API format.
    // Docs: https://docs.anthropic.com/en/api/messages
    final body = jsonEncode({
      'model': model,
      'max_tokens': maxTokens,
      'temperature': temperature,
      'system': systemPrompt,
      'messages': messages,
    });

    debugPrint('[AI] Sending request to $model (max_tokens=$maxTokens)');

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': _apiVersion,
      },
      body: body,
    );

    if (response.statusCode != 200) {
      final error = _parseError(response);
      debugPrint('[AI] Error ${response.statusCode}: $error');
      throw AiServiceException('API error ${response.statusCode}: $error');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content = data['content'] as List;

    // Extract text blocks from response
    final textBlocks = content
        .where((c) => c['type'] == 'text')
        .map((c) => c['text'] as String)
        .join('\n');

    // Log usage for cost tracking
    final usage = data['usage'] as Map<String, dynamic>?;
    if (usage != null) {
      debugPrint('[AI] Tokens — input: ${usage['input_tokens']}, '
          'output: ${usage['output_tokens']}');
    }

    return textBlocks;
  }

  // ── Convenience: Text-only message ────────────────────────

  /// Simple text prompt → text response.
  Future<String> ask(String systemPrompt, String userMessage, {
    int maxTokens = 1024,
  }) {
    return complete(
      systemPrompt: systemPrompt,
      messages: [
        {'role': 'user', 'content': userMessage},
      ],
      maxTokens: maxTokens,
    );
  }

  // ── Convenience: Image analysis (Vision) ──────────────────
  //
  // HOW VISION WORKS:
  // Claude can "see" images. You send a base64-encoded image as part of
  // the message. The model processes it like a human looking at a picture.
  // This is how we'll read title blocks, review drawings, etc.
  //
  // Supported formats: JPEG, PNG, GIF, WebP
  // Max size: 20MB per image, but smaller = faster + cheaper
  // Multiple images: yes, up to 20 per message

  /// Analyze an image with a text prompt.
  /// [imageBytes] = raw file bytes (PNG, JPEG, etc.)
  /// [mediaType] = "image/png", "image/jpeg", etc.
  Future<String> analyzeImage({
    required String systemPrompt,
    required String userPrompt,
    required List<int> imageBytes,
    String mediaType = 'image/png',
    int maxTokens = 1024,
  }) {
    final b64 = base64Encode(imageBytes);
    return complete(
      systemPrompt: systemPrompt,
      messages: [
        {
          'role': 'user',
          'content': [
            {
              'type': 'image',
              'source': {
                'type': 'base64',
                'media_type': mediaType,
                'data': b64,
              },
            },
            {
              'type': 'text',
              'text': userPrompt,
            },
          ],
        },
      ],
      maxTokens: maxTokens,
    );
  }

  /// Analyze a PDF document (sent as base64 document block).
  /// Claude can read PDFs natively — no text extraction needed.
  Future<String> analyzePdf({
    required String systemPrompt,
    required String userPrompt,
    required List<int> pdfBytes,
    int maxTokens = 2048,
  }) {
    final b64 = base64Encode(pdfBytes);
    return complete(
      systemPrompt: systemPrompt,
      messages: [
        {
          'role': 'user',
          'content': [
            {
              'type': 'document',
              'source': {
                'type': 'base64',
                'media_type': 'application/pdf',
                'data': b64,
              },
            },
            {
              'type': 'text',
              'text': userPrompt,
            },
          ],
        },
      ],
      maxTokens: maxTokens,
    );
  }

  // ── Convenience: Structured JSON response ─────────────────
  //
  // KEY PATTERN: When you want the AI to return data your app can parse,
  // you tell it in the system prompt to respond ONLY with JSON, then
  // parse the response. This is how every "smart" feature works.
  //
  // Example flow:
  //   System: "Extract title block info. Respond ONLY with JSON: {sheet_number, ...}"
  //   User: [image of drawing sheet]
  //   Response: {"sheet_number": "A1.01", "project_number": "24402", ...}
  //   App: jsonDecode(response) → use in UI

  /// Send a prompt expecting JSON back. Parses and returns the Map.
  Future<Map<String, dynamic>> askJson(
    String systemPrompt,
    String userMessage, {
    int maxTokens = 1024,
  }) async {
    final raw = await ask(systemPrompt, userMessage, maxTokens: maxTokens);
    return _parseJsonResponse(raw);
  }

  /// Analyze an image expecting JSON back.
  Future<Map<String, dynamic>> analyzeImageJson({
    required String systemPrompt,
    required String userPrompt,
    required List<int> imageBytes,
    String mediaType = 'image/png',
    int maxTokens = 1024,
  }) async {
    final raw = await analyzeImage(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      imageBytes: imageBytes,
      mediaType: mediaType,
      maxTokens: maxTokens,
    );
    return _parseJsonResponse(raw);
  }

  /// Analyze a PDF expecting JSON back.
  Future<Map<String, dynamic>> analyzePdfJson({
    required String systemPrompt,
    required String userPrompt,
    required List<int> pdfBytes,
    int maxTokens = 2048,
  }) async {
    final raw = await analyzePdf(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      pdfBytes: pdfBytes,
      maxTokens: maxTokens,
    );
    return _parseJsonResponse(raw);
  }

  // ── Validate API key with a lightweight test call ─────────

  /// Test the API key with a minimal request. Returns null on success,
  /// or an error message on failure.
  Future<String?> testApiKey() async {
    try {
      final result = await ask(
        'Respond with exactly: OK',
        'Test',
        maxTokens: 10,
      );
      return result.trim().toLowerCase().contains('ok') ? null : 'Unexpected response';
    } on AiServiceException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // ── Private helpers ───────────────────────────────────────

  /// Parse JSON from Claude's response, handling markdown code fences.
  Map<String, dynamic> _parseJsonResponse(String raw) {
    // Claude sometimes wraps JSON in ```json ... ``` — strip it
    var cleaned = raw.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceFirst(RegExp(r'^```\w*\n?'), '');
      cleaned = cleaned.replaceFirst(RegExp(r'\n?```$'), '');
      cleaned = cleaned.trim();
    }
    try {
      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      throw AiServiceException('Failed to parse JSON response: $e\nRaw: $raw');
    }
  }

  /// Extract error message from API error response.
  String _parseError(http.Response response) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final error = data['error'] as Map<String, dynamic>?;
      return error?['message'] as String? ?? response.body;
    } catch (_) {
      return response.body;
    }
  }
}

/// Custom exception for AI service errors.
class AiServiceException implements Exception {
  final String message;
  const AiServiceException(this.message);
  @override
  String toString() => 'AiServiceException: $message';
}
