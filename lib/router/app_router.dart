import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/home_map_screen.dart';
import '../screens/login_screen.dart';
import '../screens/payment_screen.dart';
import '../screens/ride_confirmation_screen.dart';
import '../screens/ride_details_screen.dart';
import '../state/auth_controller.dart';

GoRouter createAppRouter(AuthController auth) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: auth,
    redirect: (BuildContext context, GoRouterState state) {
      final loggingIn = state.matchedLocation == '/login';
      if (!auth.sessionActive && !loggingIn) {
        return '/login';
      }
      if (auth.sessionActive && loggingIn) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeMapScreen(),
      ),
      GoRoute(
        path: '/ride/details',
        builder: (context, state) => const RideDetailsScreen(),
      ),
      GoRoute(
        path: '/ride/confirm',
        builder: (context, state) => const RideConfirmationScreen(),
      ),
      GoRoute(
        path: '/payment',
        builder: (context, state) => const PaymentScreen(),
      ),
    ],
  );
}
