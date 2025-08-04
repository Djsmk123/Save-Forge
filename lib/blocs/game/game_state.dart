part of 'game_bloc.dart';

// States
abstract class GameState extends Equatable {
  const GameState();

  @override
  List<Object?> get props => [];
}

class GameInitial extends GameState {}

class GameLoading extends GameState {}

class GamesLoaded extends GameState {
  final List<Game> games;
  final Game? selectedGame;

  const GamesLoaded({
    required this.games,
    this.selectedGame,
  });

  @override
  List<Object?> get props => [games, selectedGame];

  GamesLoaded copyWith({
    List<Game>? games,
    Game? selectedGame,
  }) {
    return GamesLoaded(
      games: games ?? this.games,
      selectedGame: selectedGame ?? this.selectedGame,
    );
  }
}

class GameError extends GameState {
  final String message;

  const GameError(this.message);

  @override
  List<Object?> get props => [message];
}