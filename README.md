# Save Forge

A desktop Flutter application for managing multiple save profiles for games. Perfect for households with multiple players who want to easily switch between different save states.

## Features

### 🎮 Game Management
- Add games with custom names and icons
- Configure save game directories
- Set optional game executable paths for direct launching
- Support for both predefined and custom game icons

### 👥 Profile Management
- Create multiple save profiles per game
- Automatic default profile creation for each game
- Rename and delete profiles (except default)
- Visual distinction between default and custom profiles

### 🔄 Profile Switching
- Switch between save profiles with one click
- Automatic backup of current saves before switching
- Sync current save data back to selected profile
- Status indicators for active profiles

### 🚀 Game Launching
- Launch games directly from the app (if executable path is set)
- Automatic profile switching before game launch
- Error handling for missing executables

## Building and Installation

### Prerequisites
- Flutter SDK (latest stable version)
- Windows 10/11
- Inno Setup 6 (for creating installers)

### Building the Application

#### Option 1: Manual Build
```bash
# Build the Windows application
flutter build windows

# The built application will be in: build\windows\x64\runner\Release\
```

#### Option 2: Automated Build with Installer Creation
```bash
# Run the automated build and installer creation script
make_installer.bat
```

This script will:
1. Extract the version from `pubspec.yaml`
2. Open a separate terminal for Flutter build
3. Create an installer using Inno Setup
4. Generate the installer in the `installer/` directory

### Creating an Installer

The project includes an automated installer creation system:

1. **Ensure Inno Setup 6 is installed** on your system
2. **Run the installer script**:
   ```bash
   make_installer.bat
   ```
3. **Follow the prompts**:
   - A new terminal window will open for the Flutter build
   - Complete the build in the new window
   - Press any key in the main window to continue
   - The installer will be created automatically

### Installer Features
- Automatic version detection from `pubspec.yaml`
- Desktop shortcut creation (optional)
- Start menu integration
- Uninstall support
- Proper file associations

### Output
- **Built Application**: `build\windows\x64\runner\Release\`
- **Installer**: `installer\SaveForgeInstaller_[version].exe`



