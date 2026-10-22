import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../shared_widgets/auth_screen_styles.dart';
import 'login_screen_action_button.dart';
import '../shared_widgets/auth_form_input.dart';

class LoginForm extends StatelessWidget {
  final bool isArabic, loading, obscure;
  final TextEditingController username, password;
  final bool usernameError, passwordError;
  final int usernameShake, passwordShake;
  final VoidCallback onToggle, onForgot, onSubmit, onToggleObscure;
  const LoginForm({
    required this.isArabic,
    required this.loading,
    required this.username,
    required this.password,
    required this.onToggle,
    required this.onForgot,
    required this.onSubmit,
    required this.obscure,
    required this.onToggleObscure,
    this.usernameError = false,
    this.passwordError = false,
    this.usernameShake = 0,
    this.passwordShake = 0,
  });
  @override
  Widget build(BuildContext context) {
    final t = isArabic ? GoogleFonts.tajawal : GoogleFonts.plusJakartaSans;
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        key: const ValueKey('login'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isKeyboardVisible ? 0.3 : 1.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'تسجيل الدخول' : 'Log in to your account',
                  style: t(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: context.sanadText,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isArabic
                      ? 'أهلاً بك مجدداً! من فضلك أدخل بياناتك.'
                      : 'Welcome back! Please enter your details.',
                  style: t(fontSize: 16, color: context.sanadDim, height: 1.5),
                ),
              ],
            ),
          ),
          SizedBox(height: isKeyboardVisible ? 20 : 40),
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  AuthFormInput(
                    label: isArabic ? 'البريد الإلكتروني' : 'Email',
                    controller: username,
                    isArabic: isArabic,
                    icon: Icons.alternate_email_rounded,
                    inputKey: const ValueKey('auth-email-field'),
                    error: usernameError,
                    keyboardType: TextInputType.emailAddress,
                    hint: isArabic ? 'أدخل بريدك الإلكتروني' : 'you@email.com',
                  ),
                  const SizedBox(height: 24),
                  AuthFormInput(
                    label: isArabic ? 'كلمة المرور' : 'Password',
                    controller: password,
                    obscure: obscure,
                    isArabic: isArabic,
                    icon: Icons.password_rounded,
                    inputKey: const ValueKey('auth-password-field'),
                    suffix: IconButton(
                      icon: Icon(
                        obscure
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        size: 22,
                        color: context.sanadDim,
                      ),
                      onPressed: onToggleObscure,
                    ),
                    error: passwordError,
                    hint: '••••••••',
                  ),
                  Align(
                    alignment: isArabic
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: TextButton(
                      onPressed: onForgot,
                      child: Text(
                        isArabic ? 'نسيت كلمة المرور؟' : 'Forgot password?',
                        style: t(
                          color: context.sanadText,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  LoginScreenActionButton(
                    key: const ValueKey('login-submit'),
                    text: isArabic ? 'تسجيل الدخول' : 'Sign in',
                    loading: loading,
                    onTap: onSubmit,
                    isArabic: isArabic,
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          isArabic
                              ? 'ليس لديك حساب؟ '
                              : "Don't have an account? ",
                          style: t(fontSize: 14, color: context.sanadDim),
                        ),
                        TextButton(
                          onPressed: onToggle,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            isArabic ? 'أنشئ حساباً' : 'Sign up',
                            style: t(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: context.sanadText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
