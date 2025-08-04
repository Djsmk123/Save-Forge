import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_save_manager/blocs/game/game_bloc.dart';
import 'package:game_save_manager/blocs/add-game/add_game_cubit.dart';
import 'package:game_save_manager/blocs/add-game/add_game_state.dart';
import 'package:game_save_manager/blocs/profile/profile_bloc.dart';
import 'package:game_save_manager/core/compontents/image_widget.dart';
import 'package:game_save_manager/core/logging/app_logger.dart';
import 'package:game_save_manager/core/compontents/info_bar.dart';
import 'package:game_save_manager/widgets/game_search_box.dart';

class AddGameDialog extends StatefulWidget {
  final GameBloc gameBloc;

  const AddGameDialog({super.key, required this.gameBloc});

  @override
  State<AddGameDialog> createState() => _AddGameDialogState();
}

class _AddGameDialogState extends State<AddGameDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _savePathController = TextEditingController();
  final _executablePathController = TextEditingController();

  final uiLogger = CategoryLogger(LoggerCategory.ui);
  late final AddGameCubit cubit;

  @override
  void initState() {
    cubit = AddGameCubit();
    super.initState();
    _nameController.text = cubit.state.name;
    _savePathController.text = cubit.state.savePath;
    _executablePathController.text = cubit.state.executablePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _savePathController.dispose();
    _executablePathController.dispose();
    cubit.close();
    super.dispose();
  }

  void _onNameChanged(String value) => cubit.updateName(value);
  void _onSavePathChanged(String value) => cubit.updateSavePath(value);
  void _onExecutablePathChanged(String value) =>
      cubit.updateExecutablePath(value);

  Future<void> _addGame() async {
    final profileBloc = context.read<ProfileBloc>();
    if (!_formKey.currentState!.validate()) return;
    if (!cubit.isValid) {
      showInfoBar(
        'Validation Error',
        'Please fill in all required fields',
        InfoBarSeverity.error,
      );
      return;
    }
    cubit.setLoading(true);
    try {
      widget.gameBloc.add(
        GameAdded(
          name: cubit.state.name.trim(),
          iconPath: cubit.state.iconPath,
          savePath: cubit.state.savePath.trim(),
          executablePath: cubit.state.executablePath.trim().isEmpty
              ? null
              : cubit.state.executablePath.trim(),
          onGameAdded: (game) {
            profileBloc.add(LoadProfiles(game.id));
          },
        ),
      );
      uiLogger.info('Game added successfully: ${cubit.state.name}');
      cubit.reset();
      Navigator.of(context).pop();
    } catch (e) {
      uiLogger.error('Failed to add game', e);
      showInfoBar('Error', 'Failed to add game: $e', InfoBarSeverity.error);
    } finally {
      cubit.setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => cubit,
      child: BlocConsumer<AddGameCubit, AddGameState>(
        listener: (context, state) {
          if (state.error != null) {
            showInfoBar('Error', state.error!, InfoBarSeverity.error);
            cubit.clearError();
          }
          if (state.savePath.isNotEmpty) {
            _savePathController.text = state.savePath;
          }
          if (state.executablePath.isNotEmpty) {
            _executablePathController.text = state.executablePath;
          }
          //if (state.name.isNotEmpty) _nameController.text = state.name;
        },
        builder: (context, state) {
          return ContentDialog(
            title: Row(
              children: [
                Icon(
                  FluentIcons.add,
                  size: 20,
                  color: FluentTheme.of(context).accentColor,
                ),
                const SizedBox(width: 8),
                const Text('Add New Game'),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Game Search Box
                    Text(
                      'Game Name',
                      style: FluentTheme.of(context).typography.subtitle,
                    ),
                    const SizedBox(height: 8),
                    GameSearchBox(
                      controller: _nameController,
                      onChanged: _onNameChanged,
                      onGameSelected: (game) {
                        if (game.name != null) {
                          _nameController.text = game.name!;
                          _onNameChanged(game.name!);
                        }
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a game name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Save Path
                    Text(
                      'Save Directory',
                      style: FluentTheme.of(context).typography.subtitle,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormBox(
                            controller: _savePathController,
                            placeholder: 'Select save directory',
                            onChanged: _onSavePathChanged,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please select a save directory';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Button(
                          onPressed: state.isLoading
                              ? null
                              : () => cubit.pickSavePath(),
                          child: const Icon(FluentIcons.folder),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Executable Path (Optional)
                    Text(
                      'Game Executable (Optional)',
                      style: FluentTheme.of(context).typography.subtitle,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormBox(
                            controller: _executablePathController,
                            placeholder: 'Select game executable',
                            onChanged: _onExecutablePathChanged,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Button(
                          onPressed: state.isLoading
                              ? null
                              : () => cubit.pickExecutablePath(),
                          child: const Icon(FluentIcons.game),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Icon Preview
                    if (state.iconPath.isNotEmpty) ...[
                      Text(
                        'Game Icon',
                        style: FluentTheme.of(context).typography.subtitle,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          SizedBox(
                            width: 64,
                            height: 64,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: AppImageWidget(
                                path: state.iconPath,
                                fit: BoxFit.cover,
                                errorWidget: Container(
                                  color: FluentTheme.of(
                                    context,
                                  ).accentColor.withValues(alpha: 0.1),
                                  child: Icon(
                                    FluentIcons.game,
                                    color: FluentTheme.of(
                                      context,
                                    ).accentColor.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Button(
                            onPressed: state.isLoading
                                ? null
                                : () => cubit.pickIconPath(),
                            child: const Text('Change Icon'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              Button(
                onPressed: state.isLoading
                    ? null
                    : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              Button(
                onPressed: state.isLoading ? null : _addGame,
                child: state.isLoading
                    ? const ProgressRing(strokeWidth: 2)
                    : const Text('Add Game'),
              ),
            ],
          );
        },
      ),
    );
  }
}
