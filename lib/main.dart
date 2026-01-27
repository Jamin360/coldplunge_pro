import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_export.dart';
import 'core/env_config.dart';
import 'services/challenge_service.dart';

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
    print('🔧 DEBUG: Setting up challenge completion stream listener');
    ChallengeService.instance.completionStream.listen(
      (completions) {
        print(
            '📡 DEBUG: completionStream received event with ${completions.length} completion(s)');
        print(
            '📡 DEBUG: Completion IDs: ${completions.map((c) => c.challengeId).join(", ")}');
        final context = navigatorKey.currentContext;
        if (context != null && completions.isNotEmpty) {
          print('✅ DEBUG: Context available, showing dialog...');
          _showChallengeCompletionDialog(context, completions);
        } else if (context == null) {
          print('❌ DEBUG: No context available from navigatorKey');
        } else {
          print('❌ DEBUG: Completions list is empty');
        }
      },
    );
    print('🔧 DEBUG: Stream listener setup complete');
  }

  void _showChallengeCompletionDialog(
    BuildContext context,
    List<ChallengeCompletion> completions,
  ) {
    print('🎭 DEBUG: _showChallengeCompletionDialog called');
    print(
        '🎭 DEBUG: Showing modal for: ${completions.map((c) => c.name).join(", ")}');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      useRootNavigator: true,
      builder: (context) {
        print('🎭 DEBUG: Building _CompletionBottomSheet widget');
        return _CompletionBottomSheet(completions: completions);
      },
    );
    print('🎭 DEBUG: showModalBottomSheet called successfully');
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

/// Bottom sheet widget for challenge completion
class _CompletionBottomSheet extends StatelessWidget {
  final List<ChallengeCompletion> completions;

  const _CompletionBottomSheet({required this.completions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.only(
        top: 3.h,
        left: 5.w,
        right: 5.w,
        bottom: MediaQuery.of(context).padding.bottom + 3.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Success icon
          Container(
            padding: EdgeInsets.all(2.h),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.emoji_events,
              size: 48,
              color: const Color(0xFF10B981),
            ),
          ),
          SizedBox(height: 2.h),

          // Title
          Text(
            'Challenge Complete!',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 1.h),

          // Challenge names
          if (completions.length == 1)
            Column(
              children: [
                Text(
                  completions.first.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (completions.first.difficulty != null) ...[
                  SizedBox(height: 0.5.h),
                  Text(
                    completions.first.difficulty!.toUpperCase(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            )
          else
            Column(
              children: [
                Text(
                  completions.first.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (completions.length > 1)
                  Text(
                    '+${completions.length - 1} more',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          SizedBox(height: 1.5.h),

          // Reward text
          Text(
            'Nice work — keep the streak going!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 3.h),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Nice!',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigate to challenges tab
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.homeDashboard,
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'View Challenges',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
