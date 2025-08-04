import 'package:get_it/get_it.dart';
import 'package:saveforge/core/logging/app_logger.dart';
import 'package:saveforge/core/theme/app_theme.dart';
import 'package:saveforge/core/api/api_client.dart';
import 'package:saveforge/core/storage/local_storage.dart';
import 'package:saveforge/services/data_service.dart';
import 'package:saveforge/services/save_manager.dart';
import 'package:saveforge/services/game_manager.dart';
import 'package:saveforge/services/export_service.dart';
import 'package:saveforge/services/rawg_api_service.dart';
import 'package:saveforge/blocs/profile/profile_bloc.dart';

final getIt = GetIt.instance;

class Injection {
  static Future<void> initialize() async {
    // Create and initialize logger first
    final logger = AppLogger();
    logger.initialize();
    
    // Register logger
    getIt.registerSingleton<AppLogger>(logger);
    
    logger.info('Initializing dependency injection');
    
    await _registerCoreServices();
    await _registerBusinessServices();
    
    logger.info('Dependency injection initialized successfully');
  }

  static Future<void> _registerCoreServices() async {
    // App Theme
    if (!getIt.isRegistered<AppTheme>()) {
      getIt.registerSingleton<AppTheme>(AppTheme.defaultTheme());
    }

    // API Client
    if (!getIt.isRegistered<ApiClient>()) {
      getIt.registerSingleton<ApiClient>(ApiClient());
    }

    // Local Storage
    if (!getIt.isRegistered<LocalStorage>()) {
      final localStorage = LocalStorage();
      await localStorage.initialize();
      getIt.registerSingleton<LocalStorage>(localStorage);
    }
  }

  static Future<void> _registerBusinessServices() async {
    // Data Service
    if (!getIt.isRegistered<DataService>()) {
      getIt.registerSingleton<DataService>(DataService());
    }

    // Save Manager
    if (!getIt.isRegistered<SaveManager>()) {
      getIt.registerSingleton<SaveManager>(SaveManager(getIt.dataService));
    }

    // Game Manager - Main service that combines DataService and SaveManager
    if (!getIt.isRegistered<GameManager>()) {
      getIt.registerSingleton<GameManager>(GameManager(
        dataService: getIt.dataService,
        saveManager: getIt.saveManager,
      ));
    }

    // Export Service
    if (!getIt.isRegistered<ExportService>()) {
      getIt.registerLazySingleton<ExportService>(() => ExportService(getIt.localStorage));
    }

    // RAWG API Service
    if (!getIt.isRegistered<RawgApiService>()) {
      getIt.registerLazySingleton<RawgApiService>(() => RawgApiService());
    }

    // BLoCs
    if (!getIt.isRegistered<ProfileBloc>()) {
      getIt.registerLazySingleton<ProfileBloc>(() => ProfileBloc(getIt.dataService, getIt.saveManager));
    }
  }

  static Future<void> dispose() async {
    final logger = getIt<AppLogger>();
    logger.info('Disposing dependency injection');
    
    if (getIt.isRegistered<GameManager>()) {
      await getIt<GameManager>().dispose();
    }
    if (getIt.isRegistered<DataService>()) {
      await getIt<DataService>().dispose();
    }
    if (getIt.isRegistered<LocalStorage>()) {
      await getIt<LocalStorage>().dispose();
    }
    getIt.reset();
  }
}

// Extension methods for easy access
extension GetItExtension on GetIt {
  AppLogger get appLogger => get<AppLogger>();
  AppTheme get appTheme => get<AppTheme>();
  ApiClient get apiClient => get<ApiClient>();
  LocalStorage get localStorage => get<LocalStorage>();
  DataService get dataService => get<DataService>();
  SaveManager get saveManager => get<SaveManager>();
  GameManager get gameManager => get<GameManager>();
  ExportService get exportService => get<ExportService>();
  RawgApiService get rawgApiService => get<RawgApiService>();
} 