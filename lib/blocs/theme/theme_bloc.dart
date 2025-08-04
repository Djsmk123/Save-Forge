import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:saveforge/core/theme/app_theme.dart';
import 'package:saveforge/core/logging/app_logger.dart';

// Events
abstract class ThemeEvent extends Equatable {
  const ThemeEvent();

  @override
  List<Object?> get props => [];
}

class ThemeChanged extends ThemeEvent {
  final ThemeMode themeMode;

  const ThemeChanged(this.themeMode);

  @override
  List<Object?> get props => [themeMode];
}

class ThemeInitialized extends ThemeEvent {}

// States
abstract class ThemeState extends Equatable {
  const ThemeState();

  @override
  List<Object?> get props => [];
}

class ThemeInitial extends ThemeState {}

class ThemeLoaded extends ThemeState {
  final AppTheme appTheme;

  const ThemeLoaded(this.appTheme);

  @override
  List<Object?> get props => [appTheme];
}

class ThemeError extends ThemeState {
  final String message;

  const ThemeError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final uiLogger = CategoryLogger(LoggerCategory.ui);

  ThemeBloc() : super(ThemeInitial()) {
    on<ThemeInitialized>(_onThemeInitialized);
    on<ThemeChanged>(_onThemeChanged);
  }

  Future<void> _onThemeInitialized(
    ThemeInitialized event,
    Emitter<ThemeState> emit,
  ) async {
    try {
      uiLogger.info('Initializing theme');
      
      // Load saved theme from storage or use default
      final appTheme = AppTheme.defaultTheme();
      
      uiLogger.info('Theme initialized successfully');
      emit(ThemeLoaded(appTheme));
    } catch (e) {
      uiLogger.error('Failed to initialize theme', e);
      emit(ThemeError('Failed to initialize theme: $e'));
    }
  }

  Future<void> _onThemeChanged(
    ThemeChanged event,
    Emitter<ThemeState> emit,
  ) async {
    try {
      uiLogger.info('Changing theme to: ${event.themeMode}');
      
      if (state is ThemeLoaded) {
        final currentTheme = (state as ThemeLoaded).appTheme;
        final newTheme = currentTheme.copyWith(themeMode: event.themeMode);
        
        // Save theme preference to storage
        // await _saveThemePreference(event.themeMode);
        
        uiLogger.info('Theme changed successfully');
        emit(ThemeLoaded(newTheme));
      }
    } catch (e) {
      uiLogger.error('Failed to change theme', e);
      emit(ThemeError('Failed to change theme: $e'));
    }
  }

  // Helper methods
  ThemeMode get currentThemeMode {
    if (state is ThemeLoaded) {
      return (state as ThemeLoaded).appTheme.themeMode;
    }
    return ThemeMode.system;
  }

  FluentThemeData get currentLightTheme {
    if (state is ThemeLoaded) {
      return (state as ThemeLoaded).appTheme.lightTheme;
    }
    return AppTheme.defaultTheme().lightTheme;
  }

  FluentThemeData get currentDarkTheme {
    if (state is ThemeLoaded) {
      return (state as ThemeLoaded).appTheme.darkTheme;
    }
    return AppTheme.defaultTheme().darkTheme;
  }
} 