import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_export.dart';
import 'core/env_config.dart';
import 'services/challenge_completion_notifier.dart';

// Global navigator key for showing dialogs from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize environment configuration
  await EnvConfig.instance.initialize();

  // Initialize Supabase
  await Supabase.initialize(
    url: EnvConfig.instance.get('SUPABASE_URL'),
    anonKey: EnvConfig.instance.get('SUPABASE_ANON_KEY'),
  );

  // Initialize challenge completion notifier
  await ChallengeCompletionNotifier.instance.initialize();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _setupChallengeCompletionListener();
  }

  void _setupChallengeCompletionListener() {
    ChallengeCompletionNotifier.instance.completionStream.listen(
      (completions) {
        final context = navigatorKey.currentContext;
        if (context != null && completions.isNotEmpty) {
          ChallengeCompletionNotifier.showCompletionDialog(
            context,
            completions,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'ColdPlunge Pro',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          initialRoute: AppRoutes.splashScreen,
          routes: AppRoutes.routes,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(1.0)),
              child: child!,
            );
          },
        );
      },
    );
  }
}
