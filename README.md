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

## Directory Structure

The app manages save data in the following structure:
