# Game Save Manager

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

```
AppData/GameSaveManager/
├── games_config.json     # Game metadata
├── profiles.json         # Profile data
└── saves/
    └── [Game ID]/
        ├── active/       # Current active save folder
        ├── Default/      # Default profile saves
        ├── [Profile 1]/  # Custom profile saves
        └── [Profile 2]/  # Custom profile saves
```

## Getting Started

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Windows, macOS, or Linux for desktop support

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd game_save_manager
```

2. Install dependencies:
```bash
flutter pub get
```

3. Generate JSON serialization code:
```bash
flutter packages pub run build_runner build
```

4. Run the application:
```bash
flutter run -d windows  # For Windows
flutter run -d macos    # For macOS
flutter run -d linux    # For Linux
```

## Usage

### Adding a Game
1. Click the "+" button in the game list
2. Enter the game name
3. Select a save game directory (where the game stores its save files)
4. Optionally select a game executable for direct launching
5. Choose a custom icon or use the default

### Managing Profiles
1. Select a game from the list
2. Click "Add Profile" to create a new save profile
3. Use the profile buttons to:
   - **Use Profile**: Switch to this profile's saves
   - **Rename**: Change the profile name
   - **Delete**: Remove the profile (not available for default)

### Switching Profiles
1. Select the desired profile
2. Click the play button (▶️) to switch to that profile
3. The app will copy the profile's save files to the active folder
4. Launch the game to use the switched saves

### Syncing Saves
- Click "Sync Save Now" to copy current active saves back to the selected profile
- Useful after playing to save progress to a specific profile

## Technical Details

### Dependencies
- `file_picker`: For selecting files and directories
- `path_provider`: For accessing app data directories
- `json_annotation`: For JSON serialization
- `uuid`: For generating unique IDs
- `process_run`: For launching external processes

### Architecture
- **Models**: Game and Profile data classes with JSON serialization
- **Services**: DataService for persistence, SaveManager for file operations
- **Widgets**: Modular UI components for different app sections
- **Screens**: Main application screen with sidebar layout

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and ensure code quality
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and feature requests, please create an issue in the repository.
