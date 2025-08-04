import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_save_manager/blocs/add-game/add_game_cubit.dart';
import 'package:game_save_manager/blocs/add-game/add_game_state.dart';
import 'package:game_save_manager/models/api/rawg_models.dart';
import 'package:game_save_manager/core/compontents/image_widget.dart';

class GameSearchBox extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onChanged;
  final String? Function(String?)? validator;
  final Function(RawgGame)? onGameSelected;

  const GameSearchBox({
    super.key,
    required this.controller,
    required this.onChanged,
    this.validator,
    this.onGameSelected,
  });

  @override
  State<GameSearchBox> createState() => _GameSearchBoxState();
}

class _GameSearchBoxState extends State<GameSearchBox> {
  Timer? _searchDebounceTimer;

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    widget.onChanged(value);
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      context.read<AddGameCubit>().updateSearchQuery(value);
    });
  }
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddGameCubit, AddGameState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Input
            TextFormBox(
              controller: widget.controller,
              placeholder: 'Search for a game...',
              onChanged: _onSearchChanged,
              validator: widget.validator,
              suffix: state.isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: ProgressRing(strokeWidth:1.5 ),
                      ),
                    )
                  : state.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(FluentIcons.clear),
                          onPressed: () {
                            widget.controller.clear();
                            context.read<AddGameCubit>().clearSearch();
                          },
                        )
                      : null,
            ),
            
            // Search Results
            if (state.showSearchResults && state.searchResults.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: FluentTheme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: FluentTheme.of(context).accentColor.withValues(alpha: 0.2),
                  ),
                ),
                child: ListView.builder(          
                  cacheExtent: 50,        
                  addAutomaticKeepAlives: true,
                  addRepaintBoundaries: true,
                  itemCount: state.searchResults.length,
                  itemBuilder: (context, index) {
                    final game = state.searchResults[index];
                    return _GameSearchResultTile(
                      game: game,
                      onTap: (){
                        context.read<AddGameCubit>().selectGameFromSearch(game);
                        widget.onGameSelected?.call(game);
                      },
                    );
                  },
                ),
              ),
            ],
            
            // Search Error
            if (state.searchError != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(
                      FluentIcons.error,
                      color: Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.searchError!,
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _GameSearchResultTile extends StatelessWidget {
  final RawgGame game;
  final VoidCallback onTap;

  const _GameSearchResultTile({
    required this.game,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onPressed: onTap,
      leading: SizedBox(
        width: 48,
        height: 48,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: AppImageWidget(
            path: game.backgroundImage ?? 'assets/icons/default.png',
            fit: BoxFit.cover,
            errorWidget: Container(
              color: FluentTheme.of(context).accentColor.withValues(alpha: 0.1),
              child: Icon(
                FluentIcons.game,
                color: FluentTheme.of(context).accentColor.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ),
      title: Text(
        game.name??'',
        style: FluentTheme.of(context).typography.body,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (game.released != null)
            Text(
              'Released: ${game.released}',
              style: FluentTheme.of(context).typography.caption,
            ),
          if (game.rating != null)
            Text(
              'Rating: ${game.rating}/5',
              style: FluentTheme.of(context).typography.caption,
            ),
          if (game.parentPlatforms != null && game.parentPlatforms!.isNotEmpty)
            Text(
              'Platforms: ${game.parentPlatforms!.map((p) => p.platform?.name).join(', ')}',
              style: FluentTheme.of(context).typography.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      trailing: Icon(
        FluentIcons.chevron_right,
        size: 16,
        color: FluentTheme.of(context).accentColor.withValues(alpha: 0.5),
      ),
    );
  }
} 