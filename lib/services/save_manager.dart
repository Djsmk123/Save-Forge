import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:saveforge/models/game.dart';
import 'package:saveforge/models/profile.dart';
import 'package:saveforge/core/logging/app_logger.dart';
import 'package:saveforge/services/data_service.dart';

class SaveManager {
  final DataService _dataService;
  final saveLogger = CategoryLogger(LoggerCategory.save);
  final _uuid = Uuid();
  
  late Directory _appDataDir;

  SaveManager(this._dataService);

  Future<void> initialize() async {
    try {
      saveLogger.info('Initializing SaveManager');
      
      final appDir = await getApplicationSupportDirectory();
      _appDataDir = Directory('${appDir.path}/AppData/GameSaveManager');
      await _appDataDir.create(recursive: true);
      
      saveLogger.info('SaveManager initialized successfully');
    } catch (e) {
      saveLogger.error('Failed to initialize SaveManager', e);
      rethrow;
    }
  }

  /// Gets the base saves directory for the application
  String getSavesBasePath() {
    return path.join(_appDataDir.path, 'saves');
  }

  /// Gets the game-specific saves directory
  String getGameSavesPath(Game game) {
    final basePath = getSavesBasePath();
    return path.join(basePath, '${game.name.replaceAll(RegExp(r'[^\w\s-]'), '_')}-${game.id}');
  }

  /// Gets the profiles directory for a specific game
  String getGameProfilesPath(Game game) {
    final gamePath = getGameSavesPath(game);
    return path.join(gamePath, 'saves');
  }

  /// Gets the profile-specific saves directory
  String getProfileSavesPath(Game game, Profile profile) {
    final profilesPath = getGameProfilesPath(game);
    return path.join(profilesPath, profile.name);
  }

  /// Gets the backup directory for a game
  String getBackupPath(Game game) {
    final gamePath = getGameSavesPath(game);
    return path.join(gamePath, 'backups');
  }

  /// Creates a backup of the current active saves
  Future<String?> createActiveBackup(Game game) async {
    try {
      final gameSaveDir = Directory(game.savePath);
      
      if (!await gameSaveDir.exists()) {
        saveLogger.info('No active saves to backup for game: ${game.name}');
        return null;
      }

      final files = await gameSaveDir.list().toList();
      if (files.isEmpty) {
        saveLogger.info('Game save directory is empty, no backup needed for game: ${game.name}');
        return null;
      }

      final backupPath = getBackupPath(game);
      final backupDir = Directory(backupPath);
      await backupDir.create(recursive: true);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupName = 'backup_$timestamp';
      final backupLocation = path.join(backupPath, backupName);

      await _copyDirectory(gameSaveDir, Directory(backupLocation));
      saveLogger.info('Created backup: $backupLocation for game: ${game.name}');

   
      
      return backupLocation;
    } catch (e) {
      saveLogger.error('Failed to create backup for game: ${game.name}', e);
      rethrow;
    }
  }

  /// Switches to a specific profile for a game
  Future<void> switchToProfile(Game game, Profile targetProfile) async {
    try {
      saveLogger.info('Switching to profile: ${targetProfile.name} for game: ${game.name}');

      // Get current active profile
      final currentProfile = await _getCurrentActiveProfile(game);

      // If switching to the same profile, no action needed
      if (currentProfile?.id == targetProfile.id) {
        saveLogger.info('Already on profile: ${targetProfile.name}, no switch needed');
        return;
      }

      final gameSaveDir = Directory(game.savePath);
      final targetProfileDir = Directory(getProfileSavesPath(game, targetProfile));

      // Step 1: If there's a current profile, backup current savePath to current profile
      if (currentProfile != null) {
        final currentProfileDir = Directory(getProfileSavesPath(game, currentProfile));
        
        // Ensure current profile directory exists
        await currentProfileDir.create(recursive: true);

        // Copy contents of game.savePath to current profile directory
        if (await gameSaveDir.exists()) {
          await _copyDirectory(gameSaveDir, currentProfileDir, overwrite: true);
          saveLogger.info('Backed up current saves to profile: ${currentProfile.name}');
        }
      }

      // Step 2: Copy target profile to game.savePath
      if (await targetProfileDir.exists()) {
        // Clear game.savePath before copying
        if (await gameSaveDir.exists()) {
          await gameSaveDir.delete(recursive: true);
        }
        await gameSaveDir.create(recursive: true);

        // Copy contents of target profile to game.savePath
        await _copyDirectory(targetProfileDir, gameSaveDir, overwrite: true);
        saveLogger.info('Switched to profile: ${targetProfile.name}');
      } else {
        // If target profile doesn't exist, create empty profile
        await targetProfileDir.create(recursive: true);
        saveLogger.warning('Target profile directory does not exist, created empty profile: ${targetProfile.name}');
      }

      // Set current profile
      await _setCurrentActiveProfile(game, targetProfile);

      saveLogger.info('Successfully switched to profile: ${targetProfile.name} for game: ${game.name}');
    } catch (e) {
      saveLogger.error('Failed to switch to profile: ${targetProfile.name}', e);
      rethrow;
    }
  }

  /// Syncs the active save folder back to the specified profile
  Future<void> syncActiveToProfile(Game game, Profile profile) async {
    try {
      saveLogger.info('Syncing active saves to profile: ${profile.name} for game: ${game.name}');
      
      final gameSaveDir = Directory(game.savePath);
      final profileDir = Directory(getProfileSavesPath(game, profile));

      if (!await gameSaveDir.exists()) {
        saveLogger.warning('Game save directory does not exist: ${game.savePath}');
        return;
      }

      // Create profile directory if it doesn't exist
      await profileDir.create(recursive: true);

      // Clear profile directory and copy active saves
      if (await profileDir.exists()) {
        await profileDir.delete(recursive: true);
      }
      await profileDir.create(recursive: true);

      await _copyDirectory(gameSaveDir, profileDir);
      saveLogger.info('Successfully synced active saves to profile: ${profile.name}');
    } catch (e) {
      saveLogger.error('Failed to sync active saves to profile: ${profile.name}', e);
      rethrow;
    }
  }

  /// Creates a new profile for a game
  Future<Profile> createProfile(Game game, String name, {bool isDefault = false}) async {
    try {
      saveLogger.info('Creating profile: $name for game: ${game.name}');
      
      final profileId = _uuid.v4();
      final profilePath = getProfileSavesPath(game, Profile(
        id: profileId,
        gameId: game.id,
        name: name,
        folderPath: '', // Will be set below
        isDefault: isDefault,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final profile = Profile(
        id: profileId,
        gameId: game.id,
        name: name,
        folderPath: profilePath,
        isDefault: isDefault,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Create profile directory
      final profileDir = Directory(profilePath);
      await profileDir.create(recursive: true);

      // Copy from game.savePath to the new profile directory
      final gameSaveDir = Directory(game.savePath);

      if (await gameSaveDir.exists()) {
        final gameSaveDirContents = await gameSaveDir.list(followLinks: false).toList();
        if (gameSaveDirContents.isNotEmpty) {
          await _copyDirectory(gameSaveDir, profileDir);
          saveLogger.info('Copied game.savePath (${game.savePath}) to new profile: $name');
        } else {
          saveLogger.info('Game savePath directory is empty, nothing to copy for new profile: $name');
        }
      } else {
        saveLogger.warning('Game savePath does not exist: ${game.savePath}');
      }

      // Save profile to DataService
      await _dataService.addProfile(
        gameId: game.id,
        name: name,
        folderPath: profilePath,
        isDefault: isDefault,
      );
      
      saveLogger.info('Successfully created profile: $name for game: ${game.name}');
      return profile;
    } catch (e) {
      saveLogger.error('Failed to create profile: $name', e);
      rethrow;
    }
  }

  /// Deletes a profile and its saves
  Future<void> deleteProfile(Game game, Profile profile) async {
    try {
      saveLogger.info('Deleting profile: ${profile.name} for game: ${game.name}');
      
      // Check if this is the current active profile
      final currentActiveProfile = await _getCurrentActiveProfile(game);
      if (currentActiveProfile?.id == profile.id) {
        throw Exception('Cannot delete currently active profile: ${profile.name}');
      }

      // Delete profile directory
      final profilePath = getProfileSavesPath(game, profile);
      final profileDir = Directory(profilePath);
      if (await profileDir.exists()) {
        await profileDir.delete(recursive: true);
        saveLogger.info('Deleted profile directory: $profilePath');
      }

      // Remove from DataService
      await _dataService.deleteProfile(profile.id);
      
      saveLogger.info('Successfully deleted profile: ${profile.name}');
    } catch (e) {
      saveLogger.error('Failed to delete profile: ${profile.name}', e);
      rethrow;
    }
  }

  /// Deletes all profiles for a game
  Future<void> deleteAllProfiles(String gameId) async {
    try {
      final profiles = _dataService.getProfilesForGame(gameId);
      for (var profile in profiles) {
        await _dataService.deleteProfile(profile.id);
      }
      saveLogger.info('Deleted all profiles for game: $gameId');
    } catch (e) {
      saveLogger.error('Failed to delete all profiles for game: $gameId', e);
      rethrow;
    }
  }

  /// Gets the current active profile for a game
  Future<Profile?> _getCurrentActiveProfile(Game game) async {
    try {
      // For now, return the default profile
      // In the future, this could be stored in a separate settings service
      return _dataService.getDefaultProfile(game.id);
    } catch (e) {
      saveLogger.error('Failed to get current active profile for game: ${game.name}', e);
      return null;
    }
  }

  /// Sets the current active profile for a game
  Future<void> _setCurrentActiveProfile(Game game, Profile profile) async {
    try {
      await _dataService.updateGame(game.copyWith(activeProfileId: profile.id));
      saveLogger.info('Successfully switched to profile: ${profile.name} for game: ${game.name}');
    } catch (e) {
      saveLogger.error('Failed to set active profile for game: ${game.name}', e);
      rethrow;
    }
  }

  /// Launches the game executable
  Future<void> launchGame(Game game) async {
    try {
      saveLogger.info('Launching game: ${game.name}');
      
      if (game.executablePath == null || game.executablePath!.isEmpty) {
        throw Exception('No executable path specified for game: ${game.name}');
      }
      
      final executable = File(game.executablePath!);
      if (!await executable.exists()) {
        throw Exception('Game executable not found: ${game.executablePath}');
      }
      
      await Process.run('start', ['', game.executablePath!], runInShell: true);
      saveLogger.info('Launched game: ${game.name}');
    } catch (e) {
      saveLogger.error('Failed to launch game: ${game.name}', e);
      rethrow;
    }
  }

  /// Checks if there are active saves for a game
  Future<bool> hasActiveSaves(Game game) async {
    try {
      final gameSaveDir = Directory(game.savePath);
      
      if (await gameSaveDir.exists()) {
        final files = await gameSaveDir.list().toList();
        return files.isNotEmpty;
      }
      return false;
    } catch (e) {
      saveLogger.error('Failed to check active saves for game: ${game.name}', e);
      return false;
    }
  }

  /// Gets the size of active saves for a game
  Future<int> getActiveSavesSize(Game game) async {
    try {
      final gameSaveDir = Directory(game.savePath);
      
      if (!await gameSaveDir.exists()) return 0;
      
      int totalSize = 0;
      await for (final entity in gameSaveDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      
      return totalSize;
    } catch (e) {
      saveLogger.error('Failed to get active saves size for game: ${game.name}', e);
      return 0;
    }
  }

  /// Copies a directory and its contents, with optional overwrite
  Future<void> _copyDirectory(Directory source, Directory destination, {bool overwrite = false}) async {
    try {
      if (!await destination.exists()) {
        await destination.create(recursive: true);
      }

      await for (final entity in source.list(recursive: true)) {
        final relativePath = entity.path.substring(source.path.length + 1);
        final targetPath = path.join(destination.path, relativePath);

        if (entity is File) {
          final targetFile = File(targetPath);
          await targetFile.parent.create(recursive: true);
          if (await targetFile.exists()) {
            if (overwrite) {
              await targetFile.delete();
              await entity.copy(targetFile.path);
            }
            // else: do not overwrite, skip copying
          } else {
            await entity.copy(targetFile.path);
          }
        } else if (entity is Directory) {
          await Directory(targetPath).create(recursive: true);
        }
      }

      saveLogger.debug('Copied directory: ${source.path} to ${destination.path} (overwrite: $overwrite)');
    } catch (e) {
      saveLogger.error('Failed to copy directory: ${source.path}', e);
      rethrow;
    }
  }

  /// Gets all backup files for a game
  Future<List<String>> getBackups(Game game) async {
    try {
      final backupPath = getBackupPath(game);
      final backupDir = Directory(backupPath);
      
      if (!await backupDir.exists()) return [];
      
      final backups = <String>[];
      await for (final entity in backupDir.list()) {
        if (entity is Directory) {
          backups.add(entity.path);
        }
      }
      
      return backups;
    } catch (e) {
      saveLogger.error('Failed to get backups for game: ${game.name}', e);
      return [];
    }
  }

  /// Restores a backup to active saves
  Future<void> restoreBackup(Game game, String backupPath) async {
    try {
      saveLogger.info('Restoring backup: $backupPath for game: ${game.name}');
      
      final gameSaveDir = Directory(game.savePath);
      final backupDir = Directory(backupPath);
      
      if (!await backupDir.exists()) {
        throw Exception('Backup directory does not exist: $backupPath');
      }
      
      // Clear game save directory
      if (await gameSaveDir.exists()) {
        await gameSaveDir.delete(recursive: true);
      }
      await gameSaveDir.create(recursive: true);
      
      // Copy backup to game save directory
      await _copyDirectory(backupDir, gameSaveDir);
      
      saveLogger.info('Successfully restored backup for game: ${game.name}');
    } catch (e) {
      saveLogger.error('Failed to restore backup for game: ${game.name}', e);
      rethrow;
    }
  }
} 