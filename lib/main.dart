// Main entry point for SeebadScheduler

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'utils/theme.dart';
import 'utils/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize German locale for DateFormat
  await initializeDateFormatting('de', null);
  
  runApp(const ProviderScope(child: SeebadSchedulerApp()));
}

/// Main app widget
class SeebadSchedulerApp extends ConsumerWidget {
  const SeebadSchedulerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'SeebadScheduler',
      debugShowCheckedModeBanner: false,
      theme: SeebadTheme.lightTheme,
      routerConfig: router,
    );
  }
}
