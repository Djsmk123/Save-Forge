# Profile Switching Algorithm

## 🎯 **Correct Algorithm Overview**

The profile switching system follows this directory structure:
```
AppData/GameSaveManager/saves/
├── GameName-UUID/
│   ├── saves/
│   │   ├── default/          # Default profile saves
│   │   ├── profile1/         # Profile 1 saves
│   │   ├── profile2/         # Profile 2 saves
│   │   └── profile3/         # Profile 3 saves
│   └── backups/              # Backup directory
```

## 📋 **Pseudo Algorithm**

### **1. First Game Addition**
```pseudo
FUNCTION addGame(game):
    // Create game directory structure
    gameDir = "/AppData/GameSaveManager/saves/GameName-UUID/"
    savesDir = gameDir + "saves/"
    defaultProfileDir = savesDir + "default/"
    
    // Create directories
    CREATE_DIRECTORY(gameDir)
    CREATE_DIRECTORY(savesDir)
    CREATE_DIRECTORY(defaultProfileDir)
    
    // Copy game.savePath → default profile
    IF EXISTS(game.savePath):
        COPY_DIRECTORY(game.savePath, defaultProfileDir)
        LOG("Copied game saves to default profile")
    
    // Create default profile in database
    profile = CREATE_PROFILE(game.id, "default", isDefault=true)
    SAVE_PROFILE(profile)
    
    RETURN game
```

### **2. New Profile Creation**
```pseudo
FUNCTION createProfile(game, profileName):
    // Create profile directory
    profileDir = "/AppData/GameSaveManager/saves/GameName-UUID/saves/" + profileName
    CREATE_DIRECTORY(profileDir)
    
    // Copy current game.savePath → new profile
    IF EXISTS(game.savePath):
        COPY_DIRECTORY(game.savePath, profileDir)
        LOG("Copied current saves to new profile: " + profileName)
    
    // Save profile to database
    profile = CREATE_PROFILE(game.id, profileName, isDefault=false)
    SAVE_PROFILE(profile)
    
    RETURN profile
```

### **3. Profile Switching**
```pseudo
FUNCTION switchToProfile(game, targetProfile):
    currentProfile = GET_CURRENT_ACTIVE_PROFILE(game)
    
    // If switching to same profile, do nothing
    IF currentProfile.id == targetProfile.id:
        LOG("Already on target profile")
        RETURN
    
    // Step 1: Backup current game.savePath to current profile
    IF currentProfile != null:
        currentProfileDir = "/AppData/GameSaveManager/saves/GameName-UUID/saves/" + currentProfile.name
        CREATE_DIRECTORY(currentProfileDir)
        
        IF EXISTS(game.savePath):
            COPY_DIRECTORY(game.savePath, currentProfileDir, overwrite=true)
            LOG("Backed up current saves to profile: " + currentProfile.name)
    
    // Step 2: Copy target profile to game.savePath
    targetProfileDir = "/AppData/GameSaveManager/saves/GameName-UUID/saves/" + targetProfile.name
    
    IF EXISTS(targetProfileDir):
        // Clear game.savePath
        IF EXISTS(game.savePath):
            DELETE_DIRECTORY(game.savePath)
        CREATE_DIRECTORY(game.savePath)
        
        // Copy target profile to game.savePath
        COPY_DIRECTORY(targetProfileDir, game.savePath, overwrite=true)
        LOG("Switched to profile: " + targetProfile.name)
    ELSE:
        // Create empty profile if it doesn't exist
        CREATE_DIRECTORY(targetProfileDir)
        LOG("Created empty profile: " + targetProfile.name)
    
    // Update active profile
    SET_CURRENT_ACTIVE_PROFILE(game, targetProfile)
    LOG("Successfully switched to profile: " + targetProfile.name)
```

### **4. Sync Active Saves to Profile**
```pseudo
FUNCTION syncActiveToProfile(game, profile):
    profileDir = "/AppData/GameSaveManager/saves/GameName-UUID/saves/" + profile.name
    
    IF NOT EXISTS(game.savePath):
        LOG("No active saves to sync")
        RETURN
    
    // Clear and recreate profile directory
    IF EXISTS(profileDir):
        DELETE_DIRECTORY(profileDir)
    CREATE_DIRECTORY(profileDir)
    
    // Copy game.savePath → profile directory
    COPY_DIRECTORY(game.savePath, profileDir)
    LOG("Synced active saves to profile: " + profile.name)
```

## 🔄 **Key Changes Made**

### **Before (Incorrect):**
- Copied entire "saves" directory structure
- Created empty folders instead of actual save content
- Used complex nested directory paths

### **After (Correct):**
- Directly copies save files from `game.savePath`
- Creates proper profile directories under `/GameName-UUID/saves/`
- Handles file copying with overwrite options
- Proper backup and restore logic

## 📁 **Directory Structure Example**

For a game "Cyberpunk 2077":
```
AppData/GameSaveManager/saves/
├── Cyberpunk_2077-abc123/
│   ├── saves/
│   │   ├── default/          # Default profile
│   │   │   ├── save1.sav
│   │   │   └── settings.ini
│   │   ├── profile1/         # Player 1 saves
│   │   │   ├── save2.sav
│   │   │   └── settings.ini
│   │   └── profile2/         # Player 2 saves
│   │       ├── save3.sav
│   │       └── settings.ini
│   └── backups/
│       └── backup_1234567890/
```

## ✅ **Benefits of Correct Algorithm**

1. **Direct File Copying**: Copies actual save files, not empty directories
2. **Proper Backup**: Current saves are backed up before switching
3. **Clean Structure**: Organized profile directories
4. **Data Integrity**: No data loss during profile switching
5. **Consistent Logic**: Same algorithm for all operations 