import 'package:flutter/material.dart';

import '../domain/models/user_role.dart';
import '../presentation/auth/auth_route_arguments.dart';
import '../presentation/screens/splash_screen/splash_screen.dart';
import '../presentation/screens/home_screen/home_screen.dart';
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
  static const String onboarding = OnboardingScreen.routeName;
  static const String roleSelection = RoleSelectionScreen.routeName;
  static const String login = LoginScreen.routeName;
  static const String signup = SignUpScreen.routeName;
  static const String otpVerification = OtpVerificationScreen.routeName;

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
      case null:
        return MaterialPageRoute<void>(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
      case language:
        return MaterialPageRoute<void>(
          builder: (_) => const LanguageScreen(),
          settings: settings,
        );
      case home:
        return MaterialPageRoute<void>(
          builder: (_) => const HomeScreen(),
          settings: settings,
        );
      case onboarding:
        return MaterialPageRoute<void>(
          builder: (_) => const OnboardingScreen(),
          settings: settings,
        );
      case roleSelection:
        return MaterialPageRoute<void>(
          builder: (_) => const RoleSelectionScreen(),
          settings: settings,
        );
      case login:
        return MaterialPageRoute<void>(
          builder: (_) => LoginScreen(arguments: _authArguments(settings)),
          settings: settings,
        );
      case signup:
        return MaterialPageRoute<void>(
          builder: (_) => SignUpScreen(arguments: _authArguments(settings)),
          settings: settings,
        );
      case otpVerification:
        return MaterialPageRoute<void>(
          builder: (_) =>
              OtpVerificationScreen(arguments: _authArguments(settings)),
          settings: settings,
        );
      default:
        return MaterialPageRoute<void>(
          builder: (_) => const _UnknownRouteScreen(),
          settings: settings,
        );
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
