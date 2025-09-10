import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../logic/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.isSignup = false});
  final bool isSignup;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  String _email = '';
  String _password = '';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginControllerProvider);
    final ctrl = ref.read(loginControllerProvider.notifier);

    Future<void> onSubmit() async {
      if (!(_formKey.currentState?.validate() ?? false)) return;
      _formKey.currentState!.save();
      if (widget.isSignup) {
        final ok = await ctrl.signup();
                if (ok && mounted) {
                  if (!context.mounted) return;
                  // After signup, redirect to awaiting screen.
                  context.go('/awaiting');
                }
      } else {
        final ok = await ctrl.login();
        if (ok && mounted) {
          // Routing guard elsewhere will send to awaiting/home.
          context.go('/gate');
        }
      }
    }

    Future<void> onForgot() async {
      final err = await ctrl.forgot(_email);
      if (!mounted) return;
      final snack = SnackBar(content: Text(err ?? 'Reset email sent'));
      ScaffoldMessenger.of(context).showSnackBar(snack);
    }

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(16),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      widget.isSignup ? 'Create account' : 'Sign in',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    if (state.error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          state.error!,
                          style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      enabled: !state.loading,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'name@example.com',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Email is required';
                        if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
                        return null;
                      },
                      onSaved: (v) {
                        _email = v?.trim() ?? '';
                        ref.read(loginControllerProvider.notifier).setEmail(_email);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      enabled: !state.loading,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                        ),
                      ),
                      obscureText: _obscure,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password is required';
                        if (v.length < 6) return 'At least 6 characters';
                        return null;
                      },
                      onSaved: (v) {
                        _password = v ?? '';
                        ref.read(loginControllerProvider.notifier).setPassword(_password);
                      },
                      onFieldSubmitted: (_) => onSubmit(),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: state.loading ? null : onForgot,
                        child: const Text('Forgot password?'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: state.loading ? null : onSubmit,
                      child: state.loading
                          ? const Padding(
                              padding: EdgeInsets.all(6),
                              child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                          : Text(widget.isSignup ? 'Create account' : 'Sign in'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                              onPressed: state.loading
                                  ? null
                                  : () {
                                      if (widget.isSignup) {
                                        context.go('/login');
                                      } else {
                                        context.go('/signup');
                                      }
                                    },
                      child: Text(widget.isSignup ? 'Have an account? Sign in' : 'Create a new account'),
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'By continuing, you agree to our Terms and Privacy Policy.',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
