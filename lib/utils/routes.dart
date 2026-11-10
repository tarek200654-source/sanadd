import 'package:flutter/material.dart';

import '../domain/models/app_user.dart';
import '../domain/models/user_role.dart';
import '../presentation/auth/auth_route_arguments.dart';
import '../presentation/screens/splash_screen/splash_screen.dart';
import '../presentation/screens/home_screen/home_screen.dart';
import '../presentation/screens/caregiver_links_screen/caregiver_links_screen.dart';
import '../presentation/screens/language_screen/language_screen.dart';
import '../presentation/screens/onboarding/onboarding_screen.dart';
import '../presentation/screens/role_selection/role_selection_screen.dart';
import '../presentation/screens/login_screen/login_screen.dart';
import '../presentation/screens/signup_screen/signup_screen.dart';
import '../presentation/screens/otp_verification_screen/otp_verification_screen.dart';

abstract final class AppRoutes {
  static const String splash = SplashScreen.routeName;
  static const String language = LanguageScreen.routeName;
  static const String home = '/home';
  static const String caregiverLinks = '/caregiver-links';
  static const String onboarding = OnboardingScreen.routeName;
  static const String roleSelection = RoleSelectionScreen.routeName;
  static const String login = LoginScreen.routeName;
  static const String signup = SignUpScreen.routeName;
  static const String otpVerification = OtpVerificationScreen.routeName;

  static Route<T> transition<T>({
    required RouteSettings settings,
    required WidgetBuilder builder,
  }) => _animatedPage<T>(settings, builder);

  static Route<T> _animatedPage<T>(
    RouteSettings settings,
    WidgetBuilder builder,
  ) => PageRouteBuilder<T>(
    settings: settings,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        child,
  );

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
      case null:
        return _animatedPage(settings, (_) => const SplashScreen());
      case language:
        return _animatedPage(settings, (_) => const LanguageScreen());
      case home:
        return _animatedPage(
          settings,
          (_) => HomeScreen(
            initialUser: settings.arguments is AppUser
                ? settings.arguments! as AppUser
                : null,
          ),
        );
      case caregiverLinks:
        return _animatedPage(settings, (_) => const CaregiverLinksScreen());
      case onboarding:
        return _animatedPage(settings, (_) => const OnboardingScreen());
      case roleSelection:
        return _animatedPage(settings, (_) => const RoleSelectionScreen());
      case login:
        return _animatedPage(
          settings,
          (_) => LoginScreen(arguments: _authArguments(settings)),
        );
      case signup:
        return _animatedPage(
          settings,
          (_) => SignUpScreen(arguments: _authArguments(settings)),
        );
      case otpVerification:
        return _animatedPage(
          settings,
          (_) => OtpVerificationScreen(arguments: _authArguments(settings)),
        );
      default:
        return _animatedPage(settings, (_) => const _UnknownRouteScreen());
    }
  }

  static AuthRouteArguments _authArguments(RouteSettings settings) {
    return settings.arguments is AuthRouteArguments
        ? settings.arguments! as AuthRouteArguments
        : const AuthRouteArguments(role: UserRole.patient);
  }
}

class _UnknownRouteScreen extends StatelessWidget {
  const _UnknownRouteScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Page not found')));
  }
}
