import 'package:logger/logger.dart';

class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  late final Logger _logger;

  void initialize() {
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
      level: Level.debug,
    );
  }

  void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  void verbose(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.t(message, error: error, stackTrace: stackTrace);
  }

  void wtf(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }
}

class LoggerCategory {
  static const String app = 'APP';
  static const String data = 'DATA';
  static const String ui = 'UI';
  static const String network = 'NETWORK';
  static const String storage = 'STORAGE';
  static const String game = 'GAME';
  static const String profile = 'PROFILE';
  static const String save = 'SAVE';
  static const String export = 'EXPORT';
  static const String gameManager = 'GAME_MANAGER';
}

class CategoryLogger {
  final String category;
  final AppLogger _logger = AppLogger();

  CategoryLogger(this.category);

  void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.debug('[$category] $message', error, stackTrace);
  }

  void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.info('[$category] $message', error, stackTrace);
  }

  void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.warning('[$category] $message', error, stackTrace);
  }

  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.error('[$category] $message', error, stackTrace);
  }

  void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.fatal('[$category] $message', error, stackTrace);
  }
}

// Global logger instances - these will be initialized when first accessed
AppLogger get appLogger => AppLogger();
CategoryLogger get dataLogger => CategoryLogger(LoggerCategory.data);
CategoryLogger get uiLogger => CategoryLogger(LoggerCategory.ui);
CategoryLogger get networkLogger => CategoryLogger(LoggerCategory.network);
CategoryLogger get storageLogger => CategoryLogger(LoggerCategory.storage);
CategoryLogger get gameLogger => CategoryLogger(LoggerCategory.game);
CategoryLogger get profileLogger => CategoryLogger(LoggerCategory.profile);
CategoryLogger get saveLogger => CategoryLogger(LoggerCategory.save);
CategoryLogger get exportLogger => CategoryLogger(LoggerCategory.export); 
CategoryLogger get gameManagerLogger => CategoryLogger(LoggerCategory.gameManager);