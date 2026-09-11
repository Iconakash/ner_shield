import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/error_mapper.dart';
import 'auth_controller.dart';

/// Login screen — POST /api/v1/auth/login via AuthService. No role selection
/// (AX-5): role comes exclusively from the server profile.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _otp = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    FocusScope.of(context).unfocus();
    try {
      final authenticated =
          await ref.read(authControllerProvider.notifier).signIn(
                email: _email.text.trim(),
                password: _password.text,
              );
      // When MFA is required the controller moves to AuthState.mfa() and the
      // build method swaps the form for the TOTP step.
      if (authenticated && mounted) context.go('/shell');
    } on Object catch (e) {
      final app = ErrorMapper.from(e);
      setState(() {
        _errorMessage = app.message;
      });
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  /// Second-factor step: challenge → verify (both proxied by the backend).
  Future<void> _verifyMfa() async {
    final code = _otp.text.trim();
    if (code.length < 6) {
      setState(() => _errorMessage = 'Enter the 6-digit code from your app.');
      return;
    }
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    FocusScope.of(context).unfocus();
    try {
      await ref
          .read(authControllerProvider.notifier)
          .verifyMfa(code: code);
      if (mounted) context.go('/shell');
    } on Object catch (e) {
      final app = ErrorMapper.from(e);
      setState(() {
        _errorMessage = app.message;
      });
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  /// Abandon the pending MFA challenge and return to the credentials form.
  void _resetToSignIn() async {
    setState(() {
      _errorMessage = null;
      _otp.clear();
    });
    await ref.read(authControllerProvider.notifier).cancelMfa();
  }
@override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final mfaPending = ref
            .watch(authControllerProvider)
            .valueOrNull
            ?.mfaPending ??
        false;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: mfaPending
                  ? _buildMfaStep(theme, scheme)
                  : Form(
                      key: _formKey,
                      child: _buildCredentialsForm(theme, scheme),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.shield_outlined, size: 52, color: scheme.primary),
        const SizedBox(height: 12),
        Text(
          'NER-SHIELD',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1),
        ),
        const SizedBox(height: 4),
        Text(
          'Sign in to the operations platform',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _buildErrorBox(ThemeData theme, ColorScheme scheme) {
    final message = _errorMessage;
    if (message == null) return const SizedBox.shrink();
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.errorContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: scheme.error),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onErrorContainer),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCredentialsForm(ThemeData theme, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(theme, scheme),
        TextFormField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          autofillHints: const [AutofillHints.email],
          inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.mail_outline),
          ),
          validator: (v) =>
              (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _password,
          obscureText: _obscure,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          validator: (v) =>
              (v == null || v.length < 8) ? 'Password is too short' : null,
        ),
        const SizedBox(height: 16),
        _buildErrorBox(theme, scheme),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Sign in'),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => context.go('/'),
          child: const Text('Back'),
        ),
      ],
    );
  }

  Widget _buildMfaStep(ThemeData theme, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(theme, scheme),
        Icon(Icons.pin_outlined, size: 40, color: scheme.primary),
        const SizedBox(height: 8),
        Text(
          'Two-factor verification',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Enter the 6-digit code from your authenticator app to complete '
          'sign-in.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _otp,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          autofocus: true,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(8),
          ],
          onFieldSubmitted: (_) => _verifyMfa(),
          decoration: const InputDecoration(
            labelText: 'Verification code',
            prefixIcon: Icon(Icons.verified_user_outlined),
          ),
        ),
        const SizedBox(height: 16),
        _buildErrorBox(theme, scheme),
        FilledButton(
          onPressed: _submitting ? null : _verifyMfa,
          child: _submitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Verify'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _submitting ? null : _resetToSignIn,
          child: const Text('Use a different account'),
        ),
      ],
    );
  }
  }