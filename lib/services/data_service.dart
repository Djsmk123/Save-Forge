import 'package:uuid/uuid.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:game_save_manager/models/game.dart';
import 'package:game_save_manager/models/profile.dart';
import 'package:game_save_manager/core/logging/app_logger.dart';

class DataService {
  final dataLogger = CategoryLogger(LoggerCategory.data);
  
  late Box<Game> _gamesBox;
  late Box<Profile> _profilesBox;
  
  final Uuid _uuid = Uuid();
  
  List<Game> get games => _gamesBox.values.toList();
  List<Profile> get profiles => _profilesBox.values.toList();
  
  bool get isInitialized => _gamesBox.isOpen && _profilesBox.isOpen;
  
  Future<void> initialize() async {
    try {
      dataLogger.info('Initializing DataService');
      
      // Initialize Hive boxes - check if already open
      if (!Hive.isBoxOpen('games')) {
        _gamesBox = await Hive.openBox<Game>('games');
      } else {
        _gamesBox = Hive.box<Game>('games');
      }
      
      if (!Hive.isBoxOpen('profiles')) {
        _profilesBox = await Hive.openBox<Profile>('profiles');
      } else {
        _profilesBox = Hive.box<Profile>('profiles');
      }
      
      dataLogger.info('DataService initialized successfully');
      dataLogger.info('Loaded ${_gamesBox.length} games from Hive');
      dataLogger.info('Loaded ${_profilesBox.length} profiles from Hive');
    } catch (e) {
      dataLogger.error('Failed to initialize DataService', e);
      rethrow;
    }
  }
  
  // Game CRUD Operations
  Future<Game> addGame({
    required String name,
    required String iconPath,
    required String savePath,
    String? executablePath,
  }) async {
    final now = DateTime.now();
    final game = Game(
      id: _uuid.v4(),
      name: name,
      iconPath: iconPath,
      savePath: savePath,
      executablePath: executablePath,
      createdAt: now,
      updatedAt: now,
    );
    
    await _gamesBox.put(game.id, game);
    dataLogger.info('Game added successfully: ${game.name}');
    return game;
  }
  
  Future<void> updateGame(Game game) async {
    final updatedGame = game.copyWith(updatedAt: DateTime.now());
    await _gamesBox.put(game.id, updatedGame);
    dataLogger.info('Game updated successfully: ${game.name}');
  }
  
  Future<void> deleteGame(String gameId) async {
    await _gamesBox.delete(gameId);
    dataLogger.info('Game deleted successfully: $gameId');
  }
  
  Game? getGame(String gameId) {
    return _gamesBox.get(gameId);
  }
  
  // Profile CRUD Operations
  Future<Profile> addProfile({
    required String gameId,
    required String name,
    required String folderPath,
    bool isDefault = false,
  }) async {
    final now = DateTime.now();
    final profile = Profile(
      id: _uuid.v4(),
      gameId: gameId,
      name: name,
      folderPath: folderPath,
      isDefault: isDefault,
      createdAt: now,
      updatedAt: now,
    );
    
    await _profilesBox.put(profile.id, profile);
    dataLogger.info('Profile added successfully: ${profile.name}');
    return profile;
  }
  
  Future<void> updateProfile(Profile profile) async {
    final updatedProfile = profile.copyWith(updatedAt: DateTime.now());
    await _profilesBox.put(profile.id, updatedProfile);
    dataLogger.info('Profile updated successfully: ${profile.name}');
  }
  
  Future<void> deleteProfile(String profileId) async {
    await _profilesBox.delete(profileId);
    dataLogger.info('Profile deleted successfully: $profileId');
  }
  
  Profile? getProfile(String profileId) {
    return _profilesBox.get(profileId);
  }
  
  List<Profile> getProfilesForGame(String gameId) {
    return _profilesBox.values.where((profile) => profile.gameId == gameId).toList();
  }
  
  Profile? getDefaultProfile(String gameId) {
    final profiles = getProfilesForGame(gameId);
    if (profiles.isEmpty) return null;
    
    return profiles.firstWhere(
      (profile) => profile.isDefault,
      orElse: () => profiles.first,
    );
  }
  
  Future<void> dispose() async {
    try {
      if (_gamesBox.isOpen) {
        await _gamesBox.close();
      }
      if (_profilesBox.isOpen) {
        await _profilesBox.close();
      }
      dataLogger.info('DataService disposed');
    } catch (e) {
      dataLogger.error('Error disposing DataService', e);
    }
  }
} 