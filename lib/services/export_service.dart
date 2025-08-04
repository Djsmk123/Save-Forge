import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:saveforge/core/logging/app_logger.dart';
import 'package:saveforge/core/storage/local_storage.dart';
import 'package:saveforge/models/game.dart';

class ExportService {
  final LocalStorage _localStorage;
  final exportLogger = CategoryLogger(LoggerCategory.export);

  ExportService(this._localStorage);

  /// Export all games and profiles to JSON files on desktop
  Future<void> exportAllData() async {
    try {
      exportLogger.info('Starting export of all data');
      await _localStorage.exportToJson();
      exportLogger.info('Export completed successfully');
    } catch (e) {
      exportLogger.error('Failed to export all data', e);
      rethrow;
    }
  }

  /// Export a specific game with its profiles to JSON
  Future<void> exportGameWithProfiles(Game game) async {
    try {
      exportLogger.info('Starting export for game: ${game.name}');
      await _localStorage.exportGameWithProfiles(game.id);
      exportLogger.info('Game export completed: ${game.name}');
    } catch (e) {
      exportLogger.error('Failed to export game: ${game.name}', e);
      rethrow;
    }
  }

  /// Import data from a JSON file
  Future<void> importFromFile() async {
    try {
      exportLogger.info('Starting import from file');
      
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select JSON file to import',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.first.path!;
        await _localStorage.importFromJson(filePath);
        exportLogger.info('Import completed successfully from: $filePath');
      } else {
        exportLogger.info('No file selected for import');
      }
    } catch (e) {
      exportLogger.error('Failed to import from file', e);
      rethrow;
    }
  }

  /// Export games and profiles to a specific location
  Future<void> exportToLocation() async {
    try {
      exportLogger.info('Starting export to custom location');
      
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select export directory',
      );

      if (result != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final exportDir = Directory(result);
        
        // Export games
        final games = _localStorage.getGames();
        final gamesJson = games.map((game) => game.toJson()).toList();
        final gamesFile = File('${exportDir.path}/games_$timestamp.json');
        await gamesFile.writeAsString(jsonEncode(gamesJson));
        
        // Export profiles
        final profiles = _localStorage.getProfiles();
        final profilesJson = profiles.map((profile) => profile.toJson()).toList();
        final profilesFile = File('${exportDir.path}/profiles_$timestamp.json');
        await profilesFile.writeAsString(jsonEncode(profilesJson));
        
        // Export combined data
        final combinedData = {
          'exportedAt': DateTime.now().toIso8601String(),
          'version': '1.0.0',
          'games': gamesJson,
          'profiles': profilesJson,
          'totalGames': games.length,
          'totalProfiles': profiles.length,
        };
        final combinedFile = File('${exportDir.path}/game_save_manager_export_$timestamp.json');
        await combinedFile.writeAsString(jsonEncode(combinedData));
        
        exportLogger.info('Export completed to: $result');
        exportLogger.info('Games exported: ${games.length}');
        exportLogger.info('Profiles exported: ${profiles.length}');
      } else {
        exportLogger.info('No directory selected for export');
      }
    } catch (e) {
      exportLogger.error('Failed to export to location', e);
      rethrow;
    }
  }

  /// Export a specific game with profiles to a custom location
  Future<void> exportGameToLocation(Game game) async {
    try {
      exportLogger.info('Starting export for game: ${game.name}');
      
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select export directory for ${game.name}',
      );

      if (result != null) {
        final profiles = _localStorage.getProfilesForGame(game.id);
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final exportDir = Directory(result);
        
        final exportData = {
          'exportedAt': DateTime.now().toIso8601String(),
          'game': game.toJson(),
          'profiles': profiles.map((profile) => profile.toJson()).toList(),
          'totalProfiles': profiles.length,
        };
        
        final fileName = '${game.name.replaceAll(RegExp(r'[^\w\s-]'), '_')}_export_$timestamp.json';
        final exportFile = File('${exportDir.path}/$fileName');
        await exportFile.writeAsString(jsonEncode(exportData));
        
        exportLogger.info('Game export completed: ${game.name}');
        exportLogger.info('Export file: $fileName');
        exportLogger.info('Profiles exported: ${profiles.length}');
      } else {
        exportLogger.info('No directory selected for game export');
      }
    } catch (e) {
      exportLogger.error('Failed to export game to location', e);
      rethrow;
    }
  }

  /// Get export statistics
  Map<String, dynamic> getExportStats() {
    final games = _localStorage.getGames();
    final profiles = _localStorage.getProfiles();
    
    return {
      'totalGames': games.length,
      'totalProfiles': profiles.length,
      'gamesWithProfiles': games.where((game) => 
        _localStorage.getProfilesForGame(game.id).isNotEmpty
      ).length,
      'gamesWithoutProfiles': games.where((game) => 
        _localStorage.getProfilesForGame(game.id).isEmpty
      ).length,
    };
  }

  /// Validate JSON file before import
  Future<bool> validateImportFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return false;
      }
      
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Check if it's a valid export file
      return data.containsKey('games') || data.containsKey('profiles') || data.containsKey('game');
    } catch (e) {
      exportLogger.error('Failed to validate import file', e);
      return false;
    }
  }
} 