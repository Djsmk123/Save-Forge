import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:saveforge/blocs/add-game/add_game_state.dart';
import 'package:saveforge/core/logging/app_logger.dart';
import 'package:saveforge/core/di/injection.dart';
import 'package:saveforge/models/api/rawg_models.dart';
import 'dart:async';

class AddGameCubit extends Cubit<AddGameState> {
  final uiLogger = CategoryLogger(LoggerCategory.ui);
  Timer? _searchDebounceTimer;

  AddGameCubit() : super(const AddGameState());

  void updateName(String name) => emit(state.copyWith(name: name));

  void updateSavePath(String savePath) => emit(state.copyWith(savePath: savePath));

  void updateExecutablePath(String executablePath) => emit(state.copyWith(executablePath: executablePath));

  void updateIconPath(String iconPath) => emit(state.copyWith(iconPath: iconPath));

  void setLoading(bool isLoading) => emit(state.copyWith(isLoading: isLoading));

  void clearError() => emit(state.copyWith(error: null));

  // Search functionality
  void updateSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
    
    // Cancel previous timer
    _searchDebounceTimer?.cancel();
    
    if (query.trim().isEmpty) {
      emit(state.copyWith(
        searchResults: [],
        showSearchResults: false,
        searchError: null,
      ));
      return;
    }
    
    // Debounce search
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;
    
    emit(state.copyWith(isSearching: true, searchError: null));
    
    try {
      final results = await searchGames(search: query);
      emit(state.copyWith(
        searchResults: results,
        isSearching: false,
        showSearchResults: results.isNotEmpty,
      ));
      uiLogger.info('Found ${results.length} games for query: $query');
    } catch (e) {
      uiLogger.error('Search failed for query: $query', e);
      emit(state.copyWith(
        searchError: 'Search failed: $e',
        isSearching: false,
        showSearchResults: false,
      ));
    }
  }

  void selectGameFromSearch(RawgGame game) {
    emit(state.copyWith(
      name: game.name ?? '',
      iconPath: game.backgroundImage ?? state.iconPath,
      searchQuery: '',
      searchResults: [],
      showSearchResults: false,
      searchError: null,
    ));
    
    uiLogger.info('Selected game from search: ${game.name}');
  }

  void clearSearch() {
    emit(state.copyWith(
      searchQuery: '',
      searchResults: [],
      showSearchResults: false,
      searchError: null,
    ));
  }

  void toggleSearchResults() {
    emit(state.copyWith(showSearchResults: !state.showSearchResults));
  }
  
  Future<List<RawgGame>> searchGames({required String search,int pageSize=40,int page=1}) async {
    try{
      final result = await getIt.rawgApiService.searchGames(RawgSearchParams(search: search,pageSize: pageSize,page: page,mock: false ));
      return result.results;
    }catch(e){
      uiLogger.error('Failed to search games', e);
      return [];
    } 
  }

  Future<void> pickSavePath() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Save Directory',
      );
      
      if (result != null) {
        emit(state.copyWith(savePath: result));
        uiLogger.info('Save path selected: $result');
      }
    } catch (e) {
      uiLogger.error('Failed to pick save path', e);
      emit(state.copyWith(error: 'Failed to pick save directory: $e'));
    }
  }

  Future<void> pickExecutablePath() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select Game Executable',
        type: FileType.custom,
        allowedExtensions: ['exe', 'bat', 'cmd','lnk'],
      );
      
      if (result != null && result.files.isNotEmpty) {
        emit(state.copyWith(executablePath: result.files.first.path!));
        uiLogger.info('Executable path selected: ${result.files.first.path}');
      }
    } catch (e) {
      uiLogger.error('Failed to pick executable path', e);
      emit(state.copyWith(error: 'Failed to pick executable: $e'));
    }
  }

  Future<void> pickIconPath() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select Game Icon',
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg','ico','webp','svg'],
      );
      
      if (result != null && result.files.isNotEmpty) {
        emit(state.copyWith(iconPath: result.files.first.path!));
        uiLogger.info('Icon path selected: ${result.files.first.path}');
      }
    } catch (e) {
      uiLogger.error('Failed to pick icon path', e);
      emit(state.copyWith(error: 'Failed to pick icon: $e'));
    }
  }

  bool get isValid {
    return state.name.trim().isNotEmpty && state.savePath.trim().isNotEmpty;
  }

  void reset() {
    _searchDebounceTimer?.cancel();
    emit(const AddGameState());
  }

  @override
  Future<void> close() {
    _searchDebounceTimer?.cancel();
    return super.close();
  }
}
