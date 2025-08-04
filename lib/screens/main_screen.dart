import 'package:fluent_ui/fluent_ui.dart';
import 'package:game_save_manager/core/utils.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_save_manager/core/logging/app_logger.dart';
import 'package:game_save_manager/core/di/injection.dart';
import 'package:game_save_manager/blocs/game/game_bloc.dart';
import 'package:game_save_manager/blocs/profile/profile_bloc.dart';
import 'package:game_save_manager/models/game.dart';
import 'package:game_save_manager/models/profile.dart';
import 'package:game_save_manager/services/save_manager.dart';
import 'package:game_save_manager/widgets/game_list.dart';
import 'package:game_save_manager/widgets/game_details.dart';
import 'package:game_save_manager/widgets/add_game_dialog.dart';
import 'package:game_save_manager/widgets/export_dialog.dart';
import 'package:game_save_manager/core/compontents/info_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final SaveManager _saveManager;
  final uiLogger = CategoryLogger(LoggerCategory.ui);
  bool isFirstTime = true;

  @override
  void initState() {
    super.initState();
    _saveManager = getIt.saveManager;
    uiLogger.info('MainScreen initialized');
    context.read<GameBloc>().add(LoadGames());
  }

  void _onGameSelected(Game game) {
    context.read<GameBloc>().add(GameSelected(game));
    context.read<ProfileBloc>().add(LoadProfiles(game.id));
  }

  void _deleteGame(Game game) {
    context.read<GameBloc>().add(GameDeleted(game.id));
    context.read<ProfileBloc>().add(UnselectProfile());

    if (!mounted) return;

    showInfoBar(
      'Game Deleted',
      'Game deleted successfully: ${game.name}',
      InfoBarSeverity.success,
    );
  }

  void _onProfileSelected(Profile profile) {
    context.read<ProfileBloc>().add(ProfileSelected(profile));
  }

  void _deleteGameDialog(Game game) {
    onDeleteGame(context, game, _deleteGame);
  }

  Future<void> _addGame() async {
    final gameBloc = context.read<GameBloc>();
    final profileBloc = context.read<ProfileBloc>();
    final result = await showDialog<Game>(
      context: context,
      builder: (context) => AddGameDialog(gameBloc: gameBloc),
    );

    if (result != null) {
      gameBloc.add(GameSelected(result));
      profileBloc.add(LoadProfiles(result.id));
    }
  }

  Future<void> _switchToProfile(Profile profile) async {
    final gameBloc = context.read<GameBloc>();
    final gameState = gameBloc.state;
    if (gameState is! GamesLoaded || gameState.selectedGame == null) return;

    final profileBloc = context.read<ProfileBloc>();

    if (profileBloc.state is ProfilesLoaded &&
        (profileBloc.state as ProfilesLoaded).profiles.length == 1) {
      showInfoBar(
        'Single Profile',
        'You have only one profile for this game.',
        InfoBarSeverity.success,
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Switch Profile'),
        content: Text(
          'Switch to profile: ${profile.name}?\nThis will make it the active one.',
        ),
        actions: [
          Button(child: const Text('Cancel'), onPressed: () => Navigator.pop(context, false)),
          FilledButton(child: const Text('Switch'), onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      gameBloc.add(SwitchToProfile(profile));
      showInfoBar('Profile Switched', 'Switched to: ${profile.name}', InfoBarSeverity.success);
    } catch (e) {
      showInfoBar('Error', 'Failed to switch: $e', InfoBarSeverity.error);
    }
  }

  Future<void> _syncSaveNow() async {
    final gameState = context.read<GameBloc>().state;
    final profileState = context.read<ProfileBloc>().state;

    if (gameState is! GamesLoaded || gameState.selectedGame == null) return;
    if (profileState is! ProfilesLoaded || profileState.selectedProfile == null) return;

    try {
      await _saveManager.syncActiveToProfile(gameState.selectedGame!, profileState.selectedProfile!);
      if (!mounted) return;
      showInfoBar('Save Synced', 'Successfully synced', InfoBarSeverity.success);
    } catch (e) {
      showInfoBar('Error', 'Sync failed: $e', InfoBarSeverity.error);
    }
  }

  Future<void> _launchGame() async {
    final gameState = context.read<GameBloc>().state;
    if (gameState is! GamesLoaded || gameState.selectedGame == null) return;

    try {
      await _saveManager.launchGame(gameState.selectedGame!);
    } catch (e) {
      if (!mounted) return;
      showInfoBar('Error', 'Launch failed: $e', InfoBarSeverity.error);
    }
  }

  Future<void> _showExportDialog() async {
    final gameState = context.read<GameBloc>().state;
    Game? selectedGame = (gameState is GamesLoaded) ? gameState.selectedGame : null;

    await showDialog(
      context: context,
      builder: (context) => ExportDialog(selectedGame: selectedGame),
    );
  }

  Future<void> _showDeleteAllDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Delete All Data?'),
        content: const Text('This action cannot be undone. Proceed?'),
        actions: [
          Button(child: const Text('Cancel'), onPressed: () => Navigator.pop(context, false)),
          FilledButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.red),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!context.mounted) return; 

    if (result == true) {
      try {
       context.read<GameBloc>().add(DeleteAllData());
      } catch (e) {
        showInfoBar('Error', 'Failed: $e', InfoBarSeverity.error);
      }
    }
  }

  Widget _buildMainContent() {
    bool isDark = FluentTheme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark ? Colors.grey.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.05),
            isDark ? Colors.grey.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Row(
        children: [
          // Sidebar
          SizedBox(
            width: 320,
            child: GlassmorphicContainer(
              width: 320,
              height: double.infinity,
              borderRadius: 0,
              blur: 20,
              alignment: Alignment.center,
              border: 0,
              
              linearGradient: LinearGradient(
                colors: [
                  isDark ? Colors.black.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.05),
                  isDark ? Colors.black.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.1),
                ],
              ),
              
              borderGradient: isDark?
              LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.2),
                  Colors.white.withValues(alpha: 0.05),
                ],
              ):LinearGradient(
                colors: [
                 Colors.white,
                 Colors.white 
                ],
              ) ,
              child: BlocConsumer<GameBloc, GameState>(
                listener: (context, gameState) {
                  if (gameState is GamesLoaded &&
                      gameState.selectedGame != null &&
                      isFirstTime) {
                    isFirstTime = false;
                    final activeProfileId =
                        gameState.games.firstOrNull?.activeProfileId;
                    if (activeProfileId != null) {
                      context.read<ProfileBloc>().add(LoadProfiles(gameState.selectedGame!.id));
                    }
                  }
                },
                builder: (context, gameState) {
                  if (gameState is GameLoading) {
                    return const Center(child: ProgressRing());
                  } else if (gameState is GamesLoaded) {
                    return GameList(
                      games: gameState.games,
                      selectedGame: gameState.selectedGame,
                      onGameSelected: _onGameSelected,
                      onAddGame: _addGame,
                      onDeleteGame: _deleteGame,
                    );
                  } else if (gameState is GameError) {
                    return Center(child: Text('Error: ${gameState.message}'));
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),

          // Details Panel
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GlassmorphicContainer(
                borderRadius: 16,
                blur: 20,
                width: double.infinity,
                height: double.infinity,
                border: 1,
                alignment: Alignment.center,
                linearGradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.05),
                  ],
                ),
                borderGradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.3),
                    Colors.white.withValues(alpha: 0.1),
                  ],
                ),
                child: BlocBuilder<GameBloc, GameState>(
                  builder: (context, gameState) {
                    if (gameState is GamesLoaded &&
                        gameState.selectedGame != null) {
                      final selectedGame = gameState.selectedGame!;
                      return BlocBuilder<ProfileBloc, ProfileState>(
                        builder: (context, profileState) {
                          List<Profile> profiles = (profileState is ProfilesLoaded &&
                                  profileState.gameId == selectedGame.id)
                              ? profileState.profiles
                              : [];
                          final selectedProfile = (profileState is ProfilesLoaded)
                              ? profileState.selectedProfile
                              : null;

                          return GameDetails(
                            game: selectedGame,
                            profiles: profiles,
                            selectedProfile: selectedProfile,
                            onProfileSelected: _onProfileSelected,
                            onSwitchToProfile: _switchToProfile,
                            onSyncSave: _syncSaveNow,
                            onLaunchGame: _launchGame,
                            onDeleteGame: () => _deleteGameDialog(selectedGame),
                          );
                        },
                      );
                    }

                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            FluentIcons.game,
                            size: 80,
                            color: FluentTheme.of(context).accentColor.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No game selected',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: FluentTheme.of(context).accentColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Select a game from the list or add one.',
                            style: TextStyle(
                              fontSize: 16,
                              color: FluentTheme.of(context).accentColor.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    bool isDark = theme.brightness == Brightness.dark;
    return ScaffoldPage.withPadding(
      padding: EdgeInsets.zero,
      header: Container(
        decoration: BoxDecoration(
        color: !isDark ? Colors.white.withValues(alpha: 0.05) : Colors.transparent
          ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
           
            MenuBar(
              items: [
                MenuBarItem(
                  title: 'File',
                  items: [
                    MenuFlyoutItem(text: const Text('Add Game'), onPressed: _addGame),
                    MenuFlyoutItem(text: const Text('Export'), onPressed: _showExportDialog),
                    //import
                    MenuFlyoutItem(text: const Text('Import'), onPressed: () {}),
                    MenuFlyoutItem(text: const Text('Delete All Data'), onPressed: () => _showDeleteAllDialog(context)),
                    const MenuFlyoutSeparator(),
                    MenuFlyoutItem(text: const Text('Exit'), onPressed: () => Navigator.pop(context)),
                  ]
                
                ),
               
                MenuBarItem(
                  title: 'Help',
                  items: [
                    MenuFlyoutItem(
                      text: Text('Version ${Utils.currentVersion.version}'),
                      onPressed: () => showInfoBar(
                        'About',
                        'Game Save Manager v1.0.0\nBuilt with Flutter & Fluent UI',
                        InfoBarSeverity.info,
                      ),
                    ),
                    //contact
                    MenuFlyoutItem(
                      text: const Text('Contact'),
                      onPressed: () => showInfoBar(
                        'Contact',
                        'Contact us at support@gamesavemanager.com',
                        InfoBarSeverity.info,
                      ),
                    ),
                    //github
                    MenuFlyoutItem(
                      text: const Text('GitHub'),
                      onPressed: (){
        
                      }
                    ),
                  ],
                  
                ),
              ],
            ),
            const Divider(size: 1),
          ],
        ),
      ),
      content: _buildMainContent(),
  
    );
  }
}
