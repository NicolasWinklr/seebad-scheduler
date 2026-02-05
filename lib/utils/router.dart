// App routing with go_router

import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../screens/login_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/dienstplan_screen.dart';
import '../screens/mitarbeiter_screen.dart';
import '../screens/schicht_einstellungen_screen.dart';
import '../screens/regeln_screen.dart';
import '../screens/konflikte_screen.dart';
import '../widgets/app_shell.dart';

/// App router provider
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = ref.read(isAuthenticatedProvider);
      final isLoginPage = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginPage) {
        return '/login';
      }
      if (isLoggedIn && isLoginPage) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/dienstplan',
            builder: (context, state) => const DienstplanScreen(),
          ),
          GoRoute(
            path: '/mitarbeiter',
            builder: (context, state) => const MitarbeiterScreen(),
          ),
          GoRoute(
            path: '/schicht-einstellungen',
            builder: (context, state) => const SchichtEinstellungenScreen(),
          ),
          GoRoute(
            path: '/regeln',
            builder: (context, state) => const RegelnScreen(),
          ),
          GoRoute(
            path: '/konflikte',
            builder: (context, state) => const KonflikteScreen(),
          ),
        ],
      ),
    ],
  );
});
