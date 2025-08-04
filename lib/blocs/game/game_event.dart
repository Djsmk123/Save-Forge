part of 'game_bloc.dart';
// Events
abstract class GameEvent extends Equatable {
  const GameEvent();

  @override
  List<Object?> get props => [];
}

class LoadGames extends GameEvent {}

class GameAdded extends GameEvent {
  final String name;
  final String iconPath;
  final String savePath;
  final String? executablePath;
  final Function(Game)? onGameAdded;

  const GameAdded({
    required this.name,
    required this.iconPath,
    required this.savePath,
    this.executablePath,
    this.onGameAdded,
  });

  @override
  List<Object?> get props => [name, iconPath, savePath, executablePath, onGameAdded];
}

class GameUpdated extends GameEvent {
  final Game game;

  const GameUpdated(this.game);

  @override
  List<Object?> get props => [game];
}

class GameDeleted extends GameEvent {
  final String gameId;

  const GameDeleted(this.gameId);

  @override
  List<Object?> get props => [gameId];
}

class GameSelected extends GameEvent {
  final Game game;

  const GameSelected(this.game);

  @override
  List<Object?> get props => [game];
}


//Switch to profile
class SwitchToProfile extends GameEvent {
  final Profile profile;

  const SwitchToProfile(this.profile);

  @override
  List<Object?> get props => [profile];
}

class DeleteAllData extends GameEvent {}