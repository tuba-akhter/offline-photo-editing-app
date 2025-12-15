import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offline_ai_enhancer/core/theme/app_theme.dart';
import 'package:offline_ai_enhancer/presentation/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // TODO: Initialize Model or Services here if needed
  
  runApp(const ProviderScope(child: OfflineAiApp()));
}

class OfflineAiApp extends ConsumerWidget {
  const OfflineAiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'AI Enhancer',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Default to dark for premium feel
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
