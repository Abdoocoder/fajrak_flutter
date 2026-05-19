import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../utils/error_handler.dart';
import '../../services/analytics_service.dart';
import '../../widgets/common/auth_error_banner.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const int _kMinLength = 8;

class _PasswordChecks {
  final bool upper;
  final bool lower;
  final bool number;
  final bool symbol;
  final int length;

  const _PasswordChecks({
    required this.upper,
    required this.lower,
    required this.number,
    required this.symbol,
    required this.length,
  });

  bool get allMet =>
      upper && lower && number && symbol && length >= _kMinLength;

  factory _PasswordChecks.of(String pw) => _PasswordChecks(
    upper: pw.contains(RegExp(r'[A-Z]')),
    lower: pw.contains(RegExp(r'[a-z]')),
    number: pw.contains(RegExp(r'[0-9]')),
    symbol: pw.contains(RegExp(r'[^A-Za-z0-9]')),
    length: pw.length,
  );
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;
  _PasswordChecks _checks = _PasswordChecks.of('');

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('Register');
    _passwordController.addListener(() {
      setState(() => _checks = _PasswordChecks.of(_passwordController.text));
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_loading) return;
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() => _error = 'auth_error_fill_fields'.tr());
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {'full_name': _nameController.text.trim()},
      );
      if (res.user != null && mounted) {
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.handle(
          e,
          context: context,
          developerMessage: 'Register Action',
        );
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
    final showChecklist = _passwordController.text.isNotEmpty;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text(
                    'ف',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textInverse,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'auth_register_title'.tr(),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'auth_register_subtitle'.tr(),
                style: TextStyle(fontSize: 14, color: textSecondary),
              ),
              const SizedBox(height: 32),
              if (_error != null) ...[
                AuthErrorBanner(message: _error!),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _nameController,
                autofocus: true,
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  labelText: 'auth_full_name'.tr(),
                  prefixIcon: Icon(Icons.person_outlined, color: textSecondary),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  labelText: 'auth_email'.tr(),
                  prefixIcon: Icon(Icons.email_outlined, color: textSecondary),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscure,
                style: TextStyle(color: textPrimary),
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
              if (showChecklist) ...[
                const SizedBox(height: 12),
                _PasswordChecklist(checks: _checks, isDark: isDark),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: (_loading || !_checks.allMet) ? null : _register,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textInverse,
                        ),
                      )
                    : Text('auth_register_button'.tr()),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'auth_have_account'.tr(),
                    style: TextStyle(color: textSecondary),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/login'),
                    child: Text(
                      'auth_login_now'.tr(),
                      style: const TextStyle(
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

class _PasswordChecklist extends StatelessWidget {
  final _PasswordChecks checks;
  final bool isDark;

  const _PasswordChecklist({required this.checks, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final surfaceVariant = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    const metColor = AppColors.income;
    final unmetColor = textSecondary.withValues(alpha: 0.5);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: surfaceVariant.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _Req(
                  met: checks.upper,
                  label: 'auth_pass_req_upper'.tr(),
                  metColor: metColor,
                  unmetColor: unmetColor,
                ),
              ),
              Expanded(
                child: _Req(
                  met: checks.lower,
                  label: 'auth_pass_req_lower'.tr(),
                  metColor: metColor,
                  unmetColor: unmetColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _Req(
                  met: checks.number,
                  label: 'auth_pass_req_number'.tr(),
                  metColor: metColor,
                  unmetColor: unmetColor,
                ),
              ),
              Expanded(
                child: _Req(
                  met: checks.symbol,
                  label: 'auth_pass_req_symbol'.tr(),
                  metColor: metColor,
                  unmetColor: unmetColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _Req(
            met: checks.length >= _kMinLength,
            label: '${'auth_pass_req_length'.tr()}: ${checks.length}/$_kMinLength',
            metColor: metColor,
            unmetColor: unmetColor,
          ),
        ],
      ),
    );
  }
}

class _Req extends StatelessWidget {
  final bool met;
  final String label;
  final Color metColor;
  final Color unmetColor;

  const _Req({
    required this.met,
    required this.label,
    required this.metColor,
    required this.unmetColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = met ? metColor : unmetColor;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            met ? Icons.check_circle_rounded : Icons.cancel_rounded,
            key: ValueKey(met),
            size: 14,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: TextStyle(fontSize: 11, color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
