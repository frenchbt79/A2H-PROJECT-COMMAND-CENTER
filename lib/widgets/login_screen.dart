import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../main.dart' show storageServiceProvider;

// ═══════════════════════════════════════════════════════════
// AUTH STATE — simple employee login
// ═══════════════════════════════════════════════════════════

class AuthUser {
  final String id;
  final String name;
  final String initials;
  final String role;
  final String email;

  const AuthUser({
    required this.id,
    required this.name,
    required this.initials,
    required this.role,
    this.email = '',
  });
}

/// Currently logged-in user. null = not authenticated.
final authUserProvider = StateProvider<AuthUser?>((ref) => null);

/// Pre-defined employees (expand as needed)
const List<AuthUser> _employees = [
  AuthUser(id: 'bf', name: 'Bradley French', initials: 'BF', role: 'Architect', email: 'bradleyf@a2h.com'),
  AuthUser(id: 'jd', name: 'John Davis', initials: 'JD', role: 'Project Manager', email: 'johnd@a2h.com'),
  AuthUser(id: 'sm', name: 'Sarah Miller', initials: 'SM', role: 'Interior Designer', email: 'sarahm@a2h.com'),
  AuthUser(id: 'rw', name: 'Robert Wilson', initials: 'RW', role: 'Structural Engineer', email: 'robertw@a2h.com'),
  AuthUser(id: 'lp', name: 'Lisa Park', initials: 'LP', role: 'MEP Coordinator', email: 'lisap@a2h.com'),
  AuthUser(id: 'mk', name: 'Mike Kim', initials: 'MK', role: 'Civil Engineer', email: 'mikek@a2h.com'),
];

// ═══════════════════════════════════════════════════════════
// LOGIN SCREEN
// ═══════════════════════════════════════════════════════════

class LoginScreen extends ConsumerStatefulWidget {
  final VoidCallback onLogin;
  const LoginScreen({super.key, required this.onLogin});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  String? _selectedId;
  final _pinCtrl = TextEditingController();
  String _error = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Check for saved login
    final storage = ref.read(storageServiceProvider);
    final savedId = storage.loadString('lastLoginUserId');
    if (savedId != null && savedId.isNotEmpty) {
      _selectedId = savedId;
    }
  }

  void _login() {
    if (_selectedId == null) {
      setState(() => _error = 'Select your name');
      return;
    }
    final pin = _pinCtrl.text.trim();
    if (pin.isEmpty || pin.length < 4) {
      setState(() => _error = 'Enter your 4-digit PIN');
      return;
    }
    // Simple PIN validation (all employees use same PIN for now)
    if (pin != '1234' && pin != '0000') {
      setState(() => _error = 'Invalid PIN');
      return;
    }
    setState(() { _loading = true; _error = ''; });

    final user = _employees.firstWhere((e) => e.id == _selectedId);
    ref.read(authUserProvider.notifier).state = user;

    // Save last login
    final storage = ref.read(storageServiceProvider);
    storage.saveString('lastLoginUserId', user.id);

    Future.delayed(const Duration(milliseconds: 300), () {
      widget.onLogin();
    });
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.3, -0.5),
            radius: 1.4,
            colors: [Tokens.bloomBlue, Tokens.bgDark],
          ),
        ),
        child: Center(
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Tokens.bgMid.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Tokens.glassBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Tokens.accent, Tokens.accent.withValues(alpha: 0.6)],
                    ),
                  ),
                  child: Center(
                    child: Text('A2H', style: AppTheme.heading.copyWith(
                      fontSize: 18, fontWeight: FontWeight.w900, color: Tokens.bgDark,
                    )),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Project Dashboard', style: AppTheme.heading.copyWith(fontSize: 20)),
                const SizedBox(height: 4),
                Text('Sign in to continue', style: AppTheme.caption.copyWith(color: Tokens.textMuted)),
                const SizedBox(height: 24),
                // Employee Selector
                DropdownButtonFormField<String>(
                  value: _selectedId,
                  dropdownColor: Tokens.bgDark,
                  style: AppTheme.body.copyWith(fontSize: 13, color: Tokens.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Employee',
                    labelStyle: AppTheme.caption.copyWith(color: Tokens.textMuted),
                    prefixIcon: const Icon(Icons.person_outline, size: 18, color: Tokens.textMuted),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Tokens.glassBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Tokens.accent),
                    ),
                    filled: true, fillColor: Tokens.bgDark,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  items: _employees.map((e) => DropdownMenuItem(
                    value: e.id,
                    child: Text('${e.name}  •  ${e.role}'),
                  )).toList(),
                  onChanged: (v) => setState(() { _selectedId = v; _error = ''; }),
                ),
                const SizedBox(height: 16),
                // PIN field
                TextField(
                  controller: _pinCtrl,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  style: AppTheme.body.copyWith(fontSize: 16, letterSpacing: 8),
                  textAlign: TextAlign.center,
                  onSubmitted: (_) => _login(),
                  decoration: InputDecoration(
                    labelText: 'PIN',
                    labelStyle: AppTheme.caption.copyWith(color: Tokens.textMuted),
                    counterText: '',
                    prefixIcon: const Icon(Icons.lock_outline, size: 18, color: Tokens.textMuted),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Tokens.glassBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Tokens.accent),
                    ),
                    filled: true, fillColor: Tokens.bgDark,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                ),
                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(_error, style: AppTheme.caption.copyWith(color: const Color(0xFFEF5350), fontSize: 11)),
                ],
                const SizedBox(height: 20),
                // Login button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: FilledButton(
                    onPressed: _loading ? null : _login,
                    style: FilledButton.styleFrom(
                      backgroundColor: Tokens.accent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _loading
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Sign In', style: TextStyle(
                            color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Default PIN: 1234',
                    style: AppTheme.caption.copyWith(fontSize: 9, color: Tokens.textMuted.withValues(alpha: 0.5))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
