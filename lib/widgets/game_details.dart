import 'dart:io';

import 'package:game_save_manager/core/compontents/info_bar.dart';
import 'package:open_file/open_file.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_save_manager/blocs/profile/profile_bloc.dart';
import 'package:game_save_manager/core/compontents/image_widget.dart';
import 'package:game_save_manager/models/game.dart';
import 'package:game_save_manager/models/profile.dart';
import 'package:collection/collection.dart';

class GameDetails extends StatelessWidget {
  final Game game;
  final Profile? selectedProfile;
  final List<Profile> profiles;
  final Function(Profile) onProfileSelected;
  final Function(Profile) onSwitchToProfile;
  final VoidCallback onSyncSave;
  final VoidCallback onLaunchGame;
  final VoidCallback onDeleteGame;

  const GameDetails({
    super.key,
    required this.game,
    required this.selectedProfile,
    required this.profiles,
    required this.onProfileSelected,
    required this.onSwitchToProfile,
    required this.onSyncSave,
    required this.onLaunchGame,
    required this.onDeleteGame,
  });

  Future<void> _addProfile(BuildContext context) async {
    final nameController = TextEditingController();
    final profileBloc = context.read<ProfileBloc>();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Add Profile'),
        content: SizedBox(
          width: 300,
          height: 40,
          child: TextFormBox(
            controller: nameController,
            placeholder: 'Enter profile name',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a profile name';
              }
              return null;
            },
          ),
        ),
        actions: [
          Button(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.of(context).pop(nameController.text.trim());
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null) {
      profileBloc.add(ProfileAdded(game: game, name: result));
    }
  }

  Future<void> _renameProfile(BuildContext context, Profile profile) async {
    final nameController = TextEditingController(text: profile.name);
    final profileBloc = context.read<ProfileBloc>();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Rename Profile'),
        content: SizedBox(
          width: 300,
             height: 40,
          child: TextFormBox(
            controller: nameController,
            placeholder: 'Enter new profile name',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a profile name';
              }
              return null;
            },
          ),
        ),
        actions: [
          Button(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.of(context).pop(nameController.text.trim());
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (result != null && result != profile.name) {
      profileBloc.add(ProfileUpdated(profile.copyWith(name: result)));
    }
  }

  Future<void> _deleteProfile(BuildContext context, Profile profile) async {
    final profileBloc = context.read<ProfileBloc>();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Delete Profile'),
        content: Text(
          'Are you sure you want to delete the profile "${profile.name}"? This action cannot be undone.',
        ),
        actions: [
          Button(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.red),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      profileBloc.add(ProfileDeleted(game: game, profile: profile));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.scrollable(
      header: _buildHeader(context),
      children: [
        _buildGameInfoCard(context),
        const SizedBox(height: 20),
        _buildProfilesSection(context),
        const SizedBox(height: 20),
        _buildActionButtons(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return PageHeader(
      title: Text(
        game.name,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: FluentTheme.of(context).accentColor,
        ),
      ),
     
    );
  }
  String getActiveProfileName() {
    final activeProfile = profiles.firstWhereOrNull((profile) => profile.id == game.activeProfileId);
    return activeProfile?.name ?? 'Default';
  }

  Widget _buildGameInfoCard(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Card(
      backgroundColor: theme.resources.cardBackgroundFillColorDefault,
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatarImage(
            path: game.iconPath,
            radius: 40,
            errorWidget: Icon(
              FluentIcons.game,
              color: theme.accentColor,
              size: 36,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game.name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: theme.accentColor,
                  ),
                ),
                const SizedBox(height: 8),
                InfoLabel(
                  label: 'Save Path',
                  child: Row(
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                       
                        child: Text(
                          game.savePath,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.accentColor.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(FluentIcons.open_file),
                        onPressed: () => openFolder(game.savePath),
                      ),
                    ],
                  ),
                  
                ),
                if (game.executablePath != null) ...[
                  const SizedBox(height: 4),
                  InfoLabel(
                    label: 'Game Path',
                    child: Row(
                      children: [
                        Tooltip(
                          message: 'Open Folder', 
                          triggerMode: TooltipTriggerMode.longPress,
                          child: Text(
                            game.executablePath!,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.accentColor.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                       
                       
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // const SizedBox(width: 16),
          // FilledButton(
          //   onPressed: selectedProfile == null ? null : onSyncSave,
          //   child: Row(
          //     children: [z
          //       const Icon(FluentIcons.sync),
          //       const SizedBox(width: 8),
          //       const Text('Sync Save'),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }
  void openFolder(String path) async {
    try {
      final directory = Directory(path);
      if (directory.existsSync()) {
        OpenFile.open(directory.path);
      }
    } catch (e) {
      showInfoBar('Error', 'Failed to open save path: $e', InfoBarSeverity.error);
    }
  }

  Widget _buildProfilesSection(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Card(
      backgroundColor: theme.resources.cardBackgroundFillColorSecondary,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(FluentIcons.contact, size: 20),
              const SizedBox(width: 8),
              Text(
                'Profiles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.accentColor,
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => _addProfile(context),
                child: Row(
                  children: [
                    const Icon(FluentIcons.add),
                    const SizedBox(width: 8),
                    const Text('Add Profile'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (selectedProfile != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InfoBar(
                title: Row(
                  children: [
                    const Icon(FluentIcons.check_mark),
                    const SizedBox(width: 8),
                    Text('Active Profile: ${getActiveProfileName()}'),
                  ],
                ),
                severity: InfoBarSeverity.success,
              ),
            ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: profiles.length,
                separatorBuilder: (_, __) => const Divider(size: 1, style: DividerThemeData(horizontalMargin: EdgeInsets.zero)),
                itemBuilder: (context, index) {
                  final profile = profiles[index];
                  final isSelected = selectedProfile?.id == profile.id;
                  return ListTile.selectable(
                    selected: isSelected,
                    leading: Icon(
                      FluentIcons.contact,
                      color: isSelected ? theme.accentColor : null,
                    ),
                    title: Text(profile.name),
                    subtitle: Text('ID: ${profile.id}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(FluentIcons.edit),
                          onPressed: () => _renameProfile(context, profile),
                          style: ButtonStyle(
                            padding: WidgetStateProperty.all(const EdgeInsets.all(4)),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(FluentIcons.delete),
                          onPressed: () => _deleteProfile(context, profile),
                          style: ButtonStyle(
                            padding: WidgetStateProperty.all(const EdgeInsets.all(4)),
                          ),
                        ),
                        if (profile.id != game.activeProfileId )
                          IconButton(
                            icon:  Icon(FluentIcons.switch_user),
                            onPressed: () => onSwitchToProfile(profile),
                            style: ButtonStyle(
                              padding: WidgetStateProperty.all(const EdgeInsets.all(4)),
                            ),
                          ),
                      ],
                    ),
                    onPressed: isSelected
                        ? null
                        : () => onProfileSelected(profile),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // FilledButton(
        //   onPressed: selectedProfile == null ? null : onSyncSave,
        //   child: Row(
        //     children: [
        //       const Icon(FluentIcons.sync),
        //       const SizedBox(width: 8),
        //       const Text('Sync Save'),
        //     ],
        //   ),
        // ),
        if(game.executablePath != null)
        ...[
          FilledButton(
          onPressed: selectedProfile == null ? null : onLaunchGame,
          child: Row(
            children: [
              const Icon(FluentIcons.play, size: 16,color: Colors.white,),
              const SizedBox(width: 8),
              const Text('Launch Game', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ],
        FilledButton(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(Colors.red),
          ),
          onPressed: selectedProfile == null ? null : onDeleteGame,
          child: Row(
            children: [
              Icon(FluentIcons.delete, size: 16,color: Colors.white,),
              const SizedBox(width: 8),
              const Text('Delete Game', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }
}
