import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../services/analytics_service.dart';
import '../../utils/error_handler.dart';
import '../../widgets/common/auth_error_banner.dart';

String _friendlyAuthError(dynamic e) {
  if (e is AuthException) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid credentials')) {
      return 'auth_error_invalid_credentials'.tr();
    }
    if (msg.contains('email not confirmed')) {
      return 'auth_error_email_not_confirmed'.tr();
    }
    if (msg.contains('too many requests') || msg.contains('rate limit')) {
      return 'auth_error_too_many_requests'.tr();
    }
  }
  return 'error_generic'.tr();
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('Login');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) Navigator.pushReplacementNamed(context, '/main');
    } catch (e) {
      if (mounted) {
        setState(() => _error = _friendlyAuthError(e));
        if (e is! AuthException) {
          ErrorHandler.handle(e, context: context, developerMessage: 'Login Action');
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColors.backgroundDark : AppColors.background;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    context.read<AppState>().isDarkMode(context)
                        ? 'assets/images/app_icon.png'
                        : 'assets/images/app_icon_light.jpg',
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    cacheWidth: 144,
                    cacheHeight: 144,
                    semanticLabel: 'app_logo_label'.tr(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'auth_login_welcome'.tr(),
                style: AppTypography.displaySmall.copyWith(color: textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'auth_login_subtitle'.tr(),
                style: AppTypography.bodyMd.copyWith(color: textSecondary),
              ),
              const SizedBox(height: 40),
              if (_error != null) ...[
                AuthErrorBanner(message: _error!),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: AppTypography.bodyMd.copyWith(color: textPrimary),
                decoration: InputDecoration(
                  labelText: 'auth_email'.tr(),
                  prefixIcon: Icon(Icons.email_outlined, color: textSecondary),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscure,
                style: AppTypography.bodyMd.copyWith(color: textPrimary),
                decoration: InputDecoration(
                  labelText: 'auth_password'.tr(),
                  prefixIcon: Icon(Icons.lock_outlined, color: textSecondary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: textSecondary,
                    ),
                    tooltip: _obscure
                        ? 'tooltip_show_password'.tr()
                        : 'tooltip_hide_password'.tr(),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/forgot-password'),
                  child: Text(
                    'auth_forgot_password'.tr(),
                    style: AppTypography.labelMd.copyWith(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _login,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textInverse,
                        ),
                      )
                    : Text('auth_login_button'.tr()),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'auth_no_account'.tr(),
                    style: AppTypography.bodyMd.copyWith(color: textSecondary),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/register'),
                    child: Text(
                      'auth_register_now'.tr(),
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
