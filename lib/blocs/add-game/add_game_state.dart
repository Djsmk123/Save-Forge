import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:saveforge/models/api/rawg_models.dart';

part 'add_game_state.freezed.dart';

@freezed
class AddGameState with _$AddGameState {
  const factory AddGameState({
    @Default('') String name,
    @Default('') String savePath,
    @Default('') String executablePath,
    @Default('assets/icons/default.png') String iconPath,
    @Default(false) bool isLoading,
    String? error,
    // Search related fields
    @Default('') String searchQuery,
    @Default([]) List<RawgGame> searchResults,
    @Default(false) bool isSearching,
    String? searchError,
    @Default(false) bool showSearchResults,
  }) = _AddGameState;
}
