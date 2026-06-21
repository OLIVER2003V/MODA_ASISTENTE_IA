import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/home/presentation/pages/main_page.dart';
import '../../features/profile/presentation/pages/user_attributes_onboarding_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/admin/presentation/pages/admin_hairstyle_page.dart';
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: RoutePath.splash,
    routes: <RouteBase>[
      GoRoute(
        path: RoutePath.splash,
        name: AppRoute.splash.name,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: RoutePath.login,
        name: AppRoute.login.name,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RoutePath.register,
        name: AppRoute.register.name,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: RoutePath.main,
        name: AppRoute.main.name,
        builder: (context, state) => const MainPage(),
      ),
      GoRoute(
        path: RoutePath.onboarding,
        name: AppRoute.onboarding.name,
        builder: (context, state) {
          final userId = state.uri.queryParameters['userId'] ?? '';
          return UserAttributesOnboardingPage(userId: userId);
        },
      ),
      GoRoute(
        path: RoutePath.settings,
        name: AppRoute.settings.name,
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: RoutePath.adminHairstyles,
        name: AppRoute.adminHairstyles.name,
        builder: (context, state) => const AdminHairstylePage(),
      ),
      GoRoute(
        path: RoutePath.adminDashboard,
        name: AppRoute.adminDashboard.name,
        builder: (context, state) => const AdminDashboardPage(),
      ),
    ],
  );
}

class RoutePath {
  RoutePath._();

  static const String splash          = '/';
  static const String login           = '/login';
  static const String register        = '/register';
  static const String main            = '/main';
  static const String onboarding      = '/onboarding';
  static const String settings        = '/settings';
  static const String adminHairstyles = '/admin/hairstyles';
  static const String adminDashboard  = '/admin';
}

enum AppRoute { splash, login, register, main, onboarding, settings, adminHairstyles, adminDashboard }
