import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/distraction/presentation/app_unlocked_screen.dart';
import '../features/membership/presentation/membership_screen.dart';
import '../features/pomodoro/presentation/pomodoro_screen.dart';
import '../features/auth/presentation/account_screen.dart';
import '../features/auth/application/auth_notifier.dart';
import '../features/statistics/presentation/statistic_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../shared/widgets/scaffold_with_nav.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/onboarding',
    redirect: (context, state) {
      final isAuth = authState is AuthAuthenticated;
      final path = state.uri.path;

      // Unauthenticated routes (freely accessible before login)
      final isUnauthRoute =
          path == '/onboarding' || path == '/login' || path == '/register';

      // If not logged in and trying to access a protected route → onboarding
      if (!isAuth && !isUnauthRoute) return '/onboarding';

      // If logged in and still on an unauth route → dashboard
      if (isAuth && isUnauthRoute) return '/dashboard';

      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return ScaffoldWithNav(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/apps',
            builder: (context, state) => const AppUnlockedScreen(),
          ),
          GoRoute(
            path: '/rewards',
            builder: (context, state) => const MembershipScreen(),
          ),
          GoRoute(
            path: '/pomodoro',
            builder: (context, state) => const PomodoroScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/account',
        builder: (context, state) => const AccountScreen(),
      ),
      GoRoute(
        path: '/stats',
        builder: (context, state) => const StatisticScreen(),
      ),
    ],
  );
});
