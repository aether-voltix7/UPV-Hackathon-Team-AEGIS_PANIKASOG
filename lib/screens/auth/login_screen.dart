import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/auth_shared_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await context.read<AuthProvider>().loginWithEmail(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
    if (!mounted) return;
    if (success) {
      final email = _emailCtrl.text.trim();
      final route = email == 'moderator@email.com' ? '/moderator' : '/home';
      Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
    }
  }

  Future<void> _googleLogin() async {
    final success = await context.read<AuthProvider>().signInWithGoogle();
    if (!mounted) return;
    if (success) {
      final email = context.read<AuthProvider>().user?.email;
      final route = email == 'moderator@email.com' ? '/moderator' : '/home';
      Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
    }
  }

  void _forgotPassword() async {
    if (_emailCtrl.text.trim().isEmpty) {
      _showForgotPasswordDialog();
      return;
    }
    final success = await context
        .read<AuthProvider>()
        .sendPasswordReset(_emailCtrl.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Reset link sent to ${_emailCtrl.text.trim()}'
              : context.read<AuthProvider>().errorMessage ??
                  'Error sending reset link',
        ),
        backgroundColor:
            success ? AppColors.success : AppColors.error,
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Password', style: AppTextStyles.h2),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your email address to receive a password reset link.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Email',
              hint: 'your@email.com',
              controller: ctrl,
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: AppTextStyles.labelMedium),
          ),
          ElevatedButton(
            onPressed: () async {
              if (AuthService.isValidEmail(ctrl.text.trim())) {
                Navigator.pop(dialogCtx);
                await context
                    .read<AuthProvider>()
                    .sendPasswordReset(ctrl.text.trim());
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reset link sent! Check your inbox.'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Send Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const PanikasogAppBar(showBack: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppColors.chipBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                          size: 16, color: AppColors.primary),
                    ),
                    const SizedBox(width: 10),
                    const Text('Login', style: AppTextStyles.h1),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Email ────────────────────────────────────────────────────
                AppTextField(
                  label: 'Email',
                  hint: 'e.g. juandelacruz@email.com',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email is required';
                    if (!AuthService.isValidEmail(v)) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Password ─────────────────────────────────────────────────
                AppTextField(
                  label: 'Password',
                  hint: '••••••••',
                  controller: _passwordCtrl,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _login(),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Password is required';
                    }
                    return null;
                  },
                ),

                // ── Forgot password ───────────────────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _forgotPassword,
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: Text(
                      'Forgot password?',
                      style: AppTextStyles.link.copyWith(fontSize: 12),
                    ),
                  ),
                ),

                // ── Error banner ──────────────────────────────────────────────
                if (authProvider.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            authProvider.errorMessage!,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 8),

                // ── Log in button ─────────────────────────────────────────────
                AppButton(
                  label: 'Log in',
                  onPressed: _login,
                  isLoading: authProvider.isLoading,
                ),
                const SizedBox(height: 20),

                // ── Divider ───────────────────────────────────────────────────
                const AuthOrDivider(),
                const SizedBox(height: 16),

                // ── Google ────────────────────────────────────────────────────
                AppButton(
                  label: 'Log in with Google',
                  variant: ButtonVariant.social,
                  prefixIcon: const GoogleSignInIcon(),
                  onPressed: _googleLogin,
                ),
                const SizedBox(height: 12),

                // ── Facebook ──────────────────────────────────────────────────
                AppButton(
                  label: 'Log in with Facebook',
                  variant: ButtonVariant.social,
                  prefixIcon: const FacebookSignInIcon(),
                  onPressed: () {},
                ),
                const SizedBox(height: 28),

                // ── Sign up link ──────────────────────────────────────────────
                Center(
                  child: Text.rich(
                    TextSpan(
                      text: "Don't have an account yet? ",
                      style: AppTextStyles.bodySmall,
                      children: [
                        WidgetSpan(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Text(
                              'Sign up',
                              style: AppTextStyles.link
                                  .copyWith(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}