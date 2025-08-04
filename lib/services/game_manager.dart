import 'package:saveforge/models/game.dart';
import 'package:saveforge/models/profile.dart';
import 'package:saveforge/services/data_service.dart';
import 'package:saveforge/services/save_manager.dart';
import 'package:saveforge/core/logging/app_logger.dart';
import 'package:hive/hive.dart';

class GameManager {
  final DataService _dataService;
  final SaveManager _saveManager;
  final gameLogger = CategoryLogger(LoggerCategory.game);

  GameManager({
    required DataService dataService,
    required SaveManager saveManager,
  }) : _dataService = dataService, _saveManager = saveManager;

  /// Initialize both services
  Future<void> initialize() async {
    try {
      gameLogger.info('Initializing GameManager');
      await _dataService.initialize();
      await _saveManager.initialize();
      gameLogger.info('GameManager initialized successfully');
    } catch (e) {
      gameLogger.error('Failed to initialize GameManager', e);
      rethrow;
    }
  }

  // Game Management
  /// Add a new game with default profile
  Future<Game> addGame({
    required String name,
    required String iconPath,
    required String savePath,
    String? executablePath,
  }) async {
    try {
      gameLogger.info('Adding game: $name');
      
      // Create game in DataService
      var game = await _dataService.addGame(
        name: name,
        iconPath: iconPath,
        savePath: savePath,
        executablePath: executablePath,
      );

      // Create default profile
     final defaultProfile = await _saveManager.createProfile(game, 'Default', isDefault: true);
     game = game.copyWith(activeProfileId: defaultProfile.id);
     await _dataService.updateGame(game);
      
      gameLogger.info('Game added successfully: $name with default profile');
      return game;
    } catch (e) {
      gameLogger.error('Failed to add game: $name', e);
      rethrow;
    }
  }

  /// Update game information
  Future<void> updateGame(Game game) async {
    try {
      await _dataService.updateGame(game);
      gameLogger.info('Game updated successfully: ${game.name}');
    } catch (e) {
      gameLogger.error('Failed to update game: ${game.name}', e);
      rethrow;
    }
  }

  /// Delete game and all its profiles
  Future<void> deleteGame(String gameId) async {
    try {
      final game = _dataService.getGame(gameId);
      if (game == null) {
        throw Exception('Game not found: $gameId');
      }

      // Delete all profiles first
      await _saveManager.deleteAllProfiles(gameId);
      
      // Delete game
      await _dataService.deleteGame(gameId);
      
      gameLogger.info('Game deleted successfully: ${game.name}');
    } catch (e) {
      gameLogger.error('Failed to delete game: $gameId', e);
      rethrow;
    }
  }
  //delete all data
  Future<void> deleteAllData() async {
    try {
   
      //delete profile
      final games = _dataService.games;
      for (var game in games) {
        await _saveManager.deleteAllProfiles(game.id);
      }
         await Hive.deleteFromDisk();

      gameLogger.info('All data deleted successfully');
    } catch (e) {
      gameLogger.error('Failed to delete all data', e);
      rethrow;
    }
  }

  /// Get all games
  List<Game> getAllGames() {
    return _dataService.games;
  }

  /// Get a specific game
  Game? getGame(String gameId) {
    return _dataService.getGame(gameId);
  }

  // Profile Management
  /// Create a new profile for a game
  Future<Profile> createProfile(String gameId, String name, {bool isDefault = false}) async {
    try {
      final game = _dataService.getGame(gameId);
      if (game == null) {
        throw Exception('Game not found: $gameId');
      }

      final profile = await _saveManager.createProfile(game, name, isDefault: isDefault);
      gameLogger.info('Profile created successfully: $name for game: ${game.name}');
      return profile;
    } catch (e) {
      gameLogger.error('Failed to create profile: $name', e);
      rethrow;
    }
  }

  /// Update profile information
  Future<void> updateProfile(Profile profile) async {
    try {
      await _dataService.updateProfile(profile);
      gameLogger.info('Profile updated successfully: ${profile.name}');
    } catch (e) {
      gameLogger.error('Failed to update profile: ${profile.name}', e);
      rethrow;
    }
  }

  /// Delete a profile
  Future<void> deleteProfile(String gameId, String profileId) async {
    try {
      final game = _dataService.getGame(gameId);
      final profile = _dataService.getProfile(profileId);
      
      if (game == null) {
        throw Exception('Game not found: $gameId');
      }
      if (profile == null) {
        throw Exception('Profile not found: $profileId');
      }

      await _saveManager.deleteProfile(game, profile);
      gameLogger.info('Profile deleted successfully: ${profile.name}');
    } catch (e) {
      gameLogger.error('Failed to delete profile: $profileId', e);
      rethrow;
    }
  }

  /// Get all profiles for a game
  List<Profile> getProfilesForGame(String gameId) {
    return _dataService.getProfilesForGame(gameId);
  }

  /// Get default profile for a game
  Profile? getDefaultProfile(String gameId) {
    return _dataService.getDefaultProfile(gameId);
  }

  // Save Management
  /// Switch to a specific profile
  Future<void> switchToProfile(String gameId, String profileId) async {
    try {
      final game = _dataService.getGame(gameId);
      final profile = _dataService.getProfile(profileId);
      
      if (game == null) {
        throw Exception('Game not found: $gameId');
      }
      if (profile == null) {
        throw Exception('Profile not found: $profileId');
      }

      await _saveManager.switchToProfile(game, profile);
      gameLogger.info('Switched to profile: ${profile.name} for game: ${game.name}');
    } catch (e) {
      gameLogger.error('Failed to switch to profile: $profileId', e);
      rethrow;
    }
  }

  /// Sync active saves to profile
  Future<void> syncActiveToProfile(String gameId, String profileId) async {
    try {
      final game = _dataService.getGame(gameId);
      final profile = _dataService.getProfile(profileId);
      
      if (game == null) {
        throw Exception('Game not found: $gameId');
      }
      if (profile == null) {
        throw Exception('Profile not found: $profileId');
      }

      await _saveManager.syncActiveToProfile(game, profile);
      gameLogger.info('Synced active saves to profile: ${profile.name}');
    } catch (e) {
      gameLogger.error('Failed to sync active saves to profile: $profileId', e);
      rethrow;
    }
  }

  /// Launch a game
  Future<void> launchGame(String gameId) async {
    try {
      final game = _dataService.getGame(gameId);
      if (game == null) {
        throw Exception('Game not found: $gameId');
      }

      await _saveManager.launchGame(game);
      gameLogger.info('Launched game: ${game.name}');
    } catch (e) {
      gameLogger.error('Failed to launch game: $gameId', e);
      rethrow;
    }
  }

  /// Check if game has active saves
  Future<bool> hasActiveSaves(String gameId) async {
    try {
      final game = _dataService.getGame(gameId);
      if (game == null) {
        return false;
      }

      return await _saveManager.hasActiveSaves(game);
    } catch (e) {
      gameLogger.error('Failed to check active saves for game: $gameId', e);
      return false;
    }
  }

  /// Get active saves size
  Future<int> getActiveSavesSize(String gameId) async {
    try {
      final game = _dataService.getGame(gameId);
      if (game == null) {
        return 0;
      }

      return await _saveManager.getActiveSavesSize(game);
    } catch (e) {
      gameLogger.error('Failed to get active saves size for game: $gameId', e);
      return 0;
    }
  }

  /// Get all backups for a game
  Future<List<String>> getBackups(String gameId) async {
    try {
      final game = _dataService.getGame(gameId);
      if (game == null) {
        return [];
      }

      return await _saveManager.getBackups(game);
    } catch (e) {
      gameLogger.error('Failed to get backups for game: $gameId', e);
      return [];
    }
  }

  /// Restore backup
  Future<void> restoreBackup(String gameId, String backupPath) async {
    try {
      final game = _dataService.getGame(gameId);
      if (game == null) {
        throw Exception('Game not found: $gameId');
      }

      await _saveManager.restoreBackup(game, backupPath);
      gameLogger.info('Restored backup for game: ${game.name}');
    } catch (e) {
      gameLogger.error('Failed to restore backup for game: $gameId', e);
      rethrow;
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    try {
      await _dataService.dispose();
      gameLogger.info('GameManager disposed');
    } catch (e) {
      gameLogger.error('Error disposing GameManager', e);
    }
  }
}