import 'package:flutter/material.dart' hide Colors;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_save_manager/core/router/router.dart';
import 'package:game_save_manager/core/utils.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:game_save_manager/core/di/injection.dart';
import 'package:game_save_manager/core/theme/app_theme.dart';
import 'package:game_save_manager/blocs/theme/theme_bloc.dart';
import 'package:game_save_manager/blocs/game/game_bloc.dart';
import 'package:game_save_manager/blocs/profile/profile_bloc.dart';
import 'package:game_save_manager/models/game.dart';
import 'package:game_save_manager/models/profile.dart';
import 'package:game_save_manager/screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(GameAdapter());
  Hive.registerAdapter(ProfileAdapter());
  
  // Initialize dependency injection
  await Injection.initialize();
  
  final List<Future> futures = [
    Utils.fetchAppVersion(),
    getIt.gameManager.initialize(),
  ];
  await Future.wait(futures);
  
  runApp(const GameSaveManagerApp());
}

class GameSaveManagerApp extends StatelessWidget {
  const GameSaveManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ThemeBloc()..add(ThemeInitialized()),
        ),
        BlocProvider(
          create: (_) => GameBloc(getIt.gameManager),
        ),
        BlocProvider(
          create: (_) => ProfileBloc(getIt.dataService, getIt.saveManager),
        ),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, state) {
          FluentThemeData theme;
          
          if (state is ThemeLoaded) {
            theme = state.appTheme.lightTheme;
          } else {
            theme = AppTheme.defaultTheme().lightTheme;
          }
          
          return FluentApp(
            title: 'Save Forge',
            theme: theme,
            navigatorKey: AppRouter.navigatorKey,
            home: const SplashScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final logger = getIt.appLogger;
      logger.info('Application initialized successfully');
      
      // Add a small delay to show splash screen
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } catch (e) {
      final logger = getIt.appLogger;
      logger.error('Failed to initialize application', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FluentIcons.game,
              size: 64,
              color: const Color(0xFF0078D4),
            ),
            const SizedBox(height: 16),
            const Text(
              'Save Forge',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            const ProgressRing(),
            const SizedBox(height: 16),
            const Text('Initializing...'),
          ],
        ),
      ),
    );
  }
}
