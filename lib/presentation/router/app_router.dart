import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offline_ai_enhancer/presentation/screens/splash_screen.dart';
import 'package:offline_ai_enhancer/presentation/screens/home_screen.dart';
import 'package:offline_ai_enhancer/presentation/screens/enhancement_preview_screen.dart';
import 'package:offline_ai_enhancer/presentation/screens/result_screen.dart';
import 'package:offline_ai_enhancer/presentation/screens/paywall_screen.dart';
import 'package:offline_ai_enhancer/presentation/screens/settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/enhance',
        builder: (context, state) {
           final String imagePath = state.extra as String;
           return EnhancementPreviewScreen(imagePath: imagePath);
        },
      ),
      GoRoute(
        path: '/result',
        builder: (context, state) => const ResultScreen(),
      ),
      GoRoute(
        path: '/paywall',
        builder: (context, state) => const PaywallScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
