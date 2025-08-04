import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saveforge/core/logging/app_logger.dart';
import 'package:saveforge/models/game.dart';
import 'package:saveforge/models/profile.dart';

class LocalStorage {
  final storageLogger = CategoryLogger(LoggerCategory.storage);
  
  // Hive box names
  static const String gamesBoxName = 'games';
  static const String profilesBoxName = 'profiles';
  static const String settingsBoxName = 'settings';
  
  // SharedPreferences keys
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';
  
  late Box<Game> _gamesBox;
  late Box<Profile> _profilesBox;
  late Box<String> _settingsBox;
  late SharedPreferences _prefs;
  
  bool get isInitialized => _gamesBox.isOpen && _profilesBox.isOpen && _settingsBox.isOpen;

  Future<void> initialize() async {
    try {
      storageLogger.info('Initializing LocalStorage');
      
      // Initialize SharedPreferences
      _prefs = await SharedPreferences.getInstance();
      
      // Initialize Hive boxes
      if (!Hive.isBoxOpen(gamesBoxName)) {
        _gamesBox = await Hive.openBox<Game>(gamesBoxName);
      } else {
        _gamesBox = Hive.box<Game>(gamesBoxName);
      }
      
      if (!Hive.isBoxOpen(profilesBoxName)) {
        _profilesBox = await Hive.openBox<Profile>(profilesBoxName);
      } else {
        _profilesBox = Hive.box<Profile>(profilesBoxName);
      }
      
      if (!Hive.isBoxOpen(settingsBoxName)) {
        _settingsBox = await Hive.openBox<String>(settingsBoxName);
      } else {
        _settingsBox = Hive.box<String>(settingsBoxName);
      }
      
      storageLogger.info('LocalStorage initialized successfully');
      storageLogger.info('Games box: ${_gamesBox.length} items');
      storageLogger.info('Profiles box: ${_profilesBox.length} items');
    } catch (e) {
      storageLogger.error('Failed to initialize LocalStorage', e);
      rethrow;
    }
  }

  // Game operations
  List<Game> getGames() => _gamesBox.values.toList();
  
  Future<void> saveGame(Game game) async {
    try {
      await _gamesBox.put(game.id, game);
      storageLogger.debug('Game saved: ${game.name}');
    } catch (e) {
      storageLogger.error('Failed to save game', e);
      rethrow;
    }
  }
  
  Future<void> deleteGame(String gameId) async {
    try {
      await _gamesBox.delete(gameId);
      storageLogger.debug('Game deleted: $gameId');
    } catch (e) {
      storageLogger.error('Failed to delete game', e);
      rethrow;
    }
  }

  // Profile operations
  List<Profile> getProfiles() => _profilesBox.values.toList();
  
  List<Profile> getProfilesForGame(String gameId) {
    return _profilesBox.values.where((profile) => profile.gameId == gameId).toList();
  }
  
  Future<void> saveProfile(Profile profile) async {
    try {
      await _profilesBox.put(profile.id, profile);
      storageLogger.debug('Profile saved: ${profile.name}');
    } catch (e) {
      storageLogger.error('Failed to save profile', e);
      rethrow;
    }
  }
  
  Future<void> deleteProfile(String profileId) async {
    try {
      await _profilesBox.delete(profileId);
      storageLogger.debug('Profile deleted: $profileId');
    } catch (e) {
      storageLogger.error('Failed to delete profile', e);
      rethrow;
    }
  }

  // Settings operations
  String? getSetting(String key) => _settingsBox.get(key);
  
  Future<void> saveSetting(String key, String value) async {
    try {
      await _settingsBox.put(key, value);
      storageLogger.debug('Setting saved: $key = $value');
    } catch (e) {
      storageLogger.error('Failed to save setting', e);
      rethrow;
    }
  }

  // SharedPreferences operations
  String? getString(String key) => _prefs.getString(key);
  
  Future<void> saveString(String key, String value) async {
    try {
      await _prefs.setString(key, value);
      storageLogger.debug('String saved: $key');
    } catch (e) {
      storageLogger.error('Failed to save string', e);
      rethrow;
    }
  }

  // Export/Import operations
  Future<String> getDesktopPath() async {
    final desktop = await getApplicationSupportDirectory();
    final desktopPath = '${desktop.path}/Desktop';
    
    // Create Desktop directory if it doesn't exist
    final desktopDir = Directory(desktopPath);
    if (!await desktopDir.exists()) {
      await desktopDir.create(recursive: true);
    }
    
    return desktopPath;
  }

  Future<void> exportToJson() async {
    try {
      final desktopPath = await getDesktopPath();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // Export games
      final games = _gamesBox.values.toList();
      final gamesJson = games.map((game) => game.toJson()).toList();
      final gamesFile = File('$desktopPath/game_save_manager_games_$timestamp.json');
      await gamesFile.writeAsString(jsonEncode(gamesJson));
      
      // Export profiles
      final profiles = _profilesBox.values.toList();
      final profilesJson = profiles.map((profile) => profile.toJson()).toList();
      final profilesFile = File('$desktopPath/game_save_manager_profiles_$timestamp.json');
      await profilesFile.writeAsString(jsonEncode(profilesJson));
      
      // Export combined data
      final combinedData = {
        'exportedAt': DateTime.now().toIso8601String(),
        'version': '1.0.0',
        'games': gamesJson,
        'profiles': profilesJson,
      };
      final combinedFile = File('$desktopPath/game_save_manager_export_$timestamp.json');
      await combinedFile.writeAsString(jsonEncode(combinedData));
      
      storageLogger.info('Data exported to desktop: $desktopPath');
      storageLogger.info('Games exported: ${games.length}');
      storageLogger.info('Profiles exported: ${profiles.length}');
    } catch (e) {
      storageLogger.error('Failed to export data', e);
      rethrow;
    }
  }

  Future<void> importFromJson(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found: $filePath');
      }
      
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Clear existing data
      await _gamesBox.clear();
      await _profilesBox.clear();
      
      // Import games
      if (data.containsKey('games')) {
        final gamesList = data['games'] as List;
        for (final gameJson in gamesList) {
          final game = Game.fromJson(gameJson as Map<String, dynamic>);
          await _gamesBox.put(game.id, game);
        }
        storageLogger.info('Imported ${gamesList.length} games');
      }
      
      // Import profiles
      if (data.containsKey('profiles')) {
        final profilesList = data['profiles'] as List;
        for (final profileJson in profilesList) {
          final profile = Profile.fromJson(profileJson as Map<String, dynamic>);
          await _profilesBox.put(profile.id, profile);
        }
        storageLogger.info('Imported ${profilesList.length} profiles');
      }
      
      storageLogger.info('Data imported successfully from: $filePath');
    } catch (e) {
      storageLogger.error('Failed to import data', e);
      rethrow;
    }
  }

  // Export specific game with profiles
  Future<void> exportGameWithProfiles(String gameId) async {
    try {
      final game = _gamesBox.get(gameId);
      if (game == null) {
        throw Exception('Game not found: $gameId');
      }
      
      final profiles = getProfilesForGame(gameId);
      final desktopPath = await getDesktopPath();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      final exportData = {
        'exportedAt': DateTime.now().toIso8601String(),
        'game': game.toJson(),
        'profiles': profiles.map((profile) => profile.toJson()).toList(),
        'totalProfiles': profiles.length,
      };
      
      final fileName = '${game.name.replaceAll(RegExp(r'[^\w\s-]'), '_')}_export_$timestamp.json';
      final exportFile = File('$desktopPath/$fileName');
      await exportFile.writeAsString(jsonEncode(exportData));
      
      storageLogger.info('Game exported: ${game.name} with ${profiles.length} profiles');
      storageLogger.info('Export file: $fileName');
    } catch (e) {
      storageLogger.error('Failed to export game with profiles', e);
      rethrow;
    }
  }

  // Cache management
  Future<void> clearCache() async {
    try {
      await _settingsBox.clear();
      storageLogger.info('Cache cleared');
    } catch (e) {
      storageLogger.error('Failed to clear cache', e);
      rethrow;
    }
  }

  Future<void> dispose() async {
    try {
      if (_gamesBox.isOpen) await _gamesBox.close();
      if (_profilesBox.isOpen) await _profilesBox.close();
      if (_settingsBox.isOpen) await _settingsBox.close();
      storageLogger.info('LocalStorage disposed');
    } catch (e) {
      storageLogger.error('Error disposing LocalStorage', e);
    }
  }
} 