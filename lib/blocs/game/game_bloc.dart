import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:saveforge/models/game.dart';
import 'package:saveforge/models/profile.dart';
import 'package:saveforge/services/game_manager.dart';
import 'package:saveforge/core/logging/app_logger.dart';


part 'game_event.dart';
part 'game_state.dart';

// BLoC
class GameBloc extends Bloc<GameEvent, GameState> {
  final GameManager _gameManager;
  final gameLogger = CategoryLogger(LoggerCategory.game);

  GameBloc(this._gameManager) : super(GameInitial()) {
    on<LoadGames>(_onLoadGames);
    on<GameAdded>(_onGameAdded);
    on<GameUpdated>(_onGameUpdated);
    on<GameDeleted>(_onGameDeleted);
    on<GameSelected>(_onGameSelected);
    on<SwitchToProfile>(_onSwitchToProfile);
    on<DeleteAllData>(_onDeleteAllData);
  }

  Future<void> _onLoadGames(
    LoadGames event,
    Emitter<GameState> emit,
  ) async {
    try {
      gameLogger.info('Loading games');
      emit(GameLoading());

      final games = _gameManager.getAllGames();
      Game? selectedGame;
      
      if (games.isNotEmpty) {
        selectedGame = games.first;
      }

      gameLogger.info('Games loaded successfully: ${games.length} games');
      emit(GamesLoaded(games: games, selectedGame: selectedGame));
    } catch (e) {
      gameLogger.error('Failed to load games', e);
      emit(GameError('Failed to load games: $e'));
    }
  }

  Future<void> _onGameAdded(
    GameAdded event,
    Emitter<GameState> emit,
  ) async {
    try {
      var previousState = state;
      gameLogger.info('Adding game: ${event.name}');
      emit(GameLoading());

      final game = await _gameManager.addGame(
        name: event.name,
        iconPath: event.iconPath,
        savePath: event.savePath,
        executablePath: event.executablePath,
      );

      final currentState = previousState;
      if (currentState is GamesLoaded) {
        final updatedGames = List<Game>.from(currentState.games)..add(game);
        
        gameLogger.info('Game added successfully: ${game.name}');
        emit(currentState.copyWith(
          games: updatedGames,
          selectedGame: game,
        ));
        event.onGameAdded?.call(game);
      }
    } catch (e) {
      gameLogger.error('Failed to add game: ${event.name}', e);
      emit(GameError('Failed to add game: $e'));
    }
  }

  Future<void> _onGameUpdated(
    GameUpdated event,
    Emitter<GameState> emit,
  ) async {
    try {
      var previousState = state;
      gameLogger.info('Updating game: ${event.game.name}');
      emit(GameLoading());

      await _gameManager.updateGame(event.game);

      final currentState = previousState;
      if (currentState is GamesLoaded) {
        final updatedGames = currentState.games.map((game) {
          return game.id == event.game.id ? event.game : game;
        }).toList();

        final updatedSelectedGame = currentState.selectedGame?.id == event.game.id
            ? event.game
            : currentState.selectedGame;

        gameLogger.info('Game updated successfully: ${event.game.name}');
        emit(currentState.copyWith(
          games: updatedGames,
          selectedGame: updatedSelectedGame,
        ));
      }
    } catch (e) {
      gameLogger.error('Failed to update game: ${event.game.name}', e);
      emit(GameError('Failed to update game: $e'));
    }
  }

  Future<void> _onGameDeleted(
    GameDeleted event,
    Emitter<GameState> emit,
  ) async {
    try {
      var previousState = state;
      gameLogger.info('Deleting game: $event.gameId');
      emit(GameLoading());

      await _gameManager.deleteGame(event.gameId);

      final currentState = previousState;
      if (currentState is GamesLoaded) {
        final updatedGames = currentState.games
            .where((game) => game.id != event.gameId)
            .toList();

        Game? updatedSelectedGame;
        if (currentState.selectedGame?.id == event.gameId) {
          updatedSelectedGame = updatedGames.isNotEmpty ? updatedGames.first : null;
        } else {
          updatedSelectedGame = currentState.selectedGame;
        }

        gameLogger.info('Game deleted successfully: $event.gameId');
        emit(currentState.copyWith(
          games: updatedGames,
          selectedGame: updatedSelectedGame,
        ));
      }
    } catch (e) {
      gameLogger.error('Failed to delete game: $event.gameId', e);
      emit(GameError('Failed to delete game: $e'));
    }
  }

  Future<void> _onGameSelected(
    GameSelected event,
    Emitter<GameState> emit,
  ) async {
    try {
      gameLogger.info('Selecting game: ${event.game.name}');
      
      final currentState = state;
      if (currentState is GamesLoaded) {
        gameLogger.info('Game selected successfully: ${event.game.name}');
        emit(currentState.copyWith(selectedGame: event.game));
      }
    } catch (e) {
      gameLogger.error('Failed to select game: ${event.game.name}', e);
      emit(GameError('Failed to select game: $e'));
    }
  }

  // Helper methods
  List<Game> get games {
    if (state is GamesLoaded) {
      return (state as GamesLoaded).games;
    }
    return [];
  }

  Game? get selectedGame {
    if (state is GamesLoaded) {
      return (state as GamesLoaded).selectedGame;
    }
    return null;
  }

  Future<void> _onSwitchToProfile(
    SwitchToProfile event,
    Emitter<GameState> emit,
  ) async {
    var state = this.state;
    if (state is! GamesLoaded) return;
    final game = state.selectedGame;
    if (game == null) return;

    await _gameManager.switchToProfile(game.id, event.profile.id);
    emit(state.copyWith(selectedGame: game.copyWith(
      activeProfileId: event.profile.id,
    )));
  
  }

  Future<void> _onDeleteAllData(
    DeleteAllData event,
    Emitter<GameState> emit,
  ) async {
    try {
      await _gameManager.deleteAllData();
      emit(GameInitial());
    } catch (e) {
      gameLogger.error('Failed to delete all data', e);
      emit(GameError('Failed to delete all data: $e'));
    }
  }

  bool get isLoading => state is GameLoading;
  bool get hasError => state is GameError;
  String? get errorMessage {
    if (state is GameError) {
      return (state as GameError).message;
    }
    return null;
  }
} 