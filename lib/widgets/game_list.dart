import 'package:fluent_ui/fluent_ui.dart';
import 'package:saveforge/core/compontents/image_widget.dart';
import '../models/game.dart';

class GameList extends StatelessWidget {
  final List<Game> games;
  final Game? selectedGame;
  final Function(Game) onGameSelected;
  final VoidCallback onAddGame;
  final Function(Game) onDeleteGame;

  const GameList({
    super.key,
    required this.games,
    required this.selectedGame,
    required this.onGameSelected,
    required this.onAddGame,
    required this.onDeleteGame,
  });

  void _showDeleteDialog(BuildContext context, Game game) {
   onDeleteGame(game);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: FluentTheme.of(context).accentColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header with glass effect
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  FluentTheme.of(context).accentColor.withValues(alpha: 0.1),
                  FluentTheme.of(context).accentColor.withValues(alpha: 0.05),
                ],
              ),
                              border: Border(
                  bottom: BorderSide(
                    color: FluentTheme.of(context).accentColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
            ),
            child: Row(
              children: [
                Icon(
                  FluentIcons.list,
                  color: FluentTheme.of(context).accentColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Games',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: FluentTheme.of(context).accentColor,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    FluentIcons.add,
                    color: FluentTheme.of(context).accentColor,
                  ),
                  onPressed: onAddGame,
                ),
              ],
            ),
          ),
          
          // Game list
          Expanded(
            child: games.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          FluentIcons.game,
                          size: 64,
                          color: FluentTheme.of(context).accentColor.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No games added',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: FluentTheme.of(context).accentColor.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Click the + button to add your first game',
                          style: TextStyle(
                            color: FluentTheme.of(context).accentColor.withValues(alpha: 0.5),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: games.length,
                    itemBuilder: (context, index) {
                      final game = games[index];
                      final isSelected = selectedGame?.id == game.id;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Card(
                          backgroundColor: isSelected
                              ? FluentTheme.of(context).accentColor.withValues(alpha: 0.1)
                              : Colors.transparent,
                          child: Row(
                            children: [
                              Expanded(
                                child: ListTile(
                                  leading: CircleAvatarImage(path: game.iconPath, radius: 24, errorWidget: Icon(
                        FluentIcons.game,
                        color: Colors.white,
                        size: 20,
                      )),
                                  title: Text(
                                    game.name,
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                      color: isSelected
                                          ? FluentTheme.of(context).accentColor
                                          : null,
                                    ),
                                  ),
                                  subtitle: Text(
                                    game.savePath,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: FluentTheme.of(context).accentColor.withValues(alpha: 0.6),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onPressed: () => onGameSelected(game),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(FluentIcons.delete),
                                style: ButtonStyle(
                                  foregroundColor: WidgetStateProperty.all(Colors.red),
                                  padding: WidgetStateProperty.all(const EdgeInsets.all(8)),
                                ),
                                onPressed: () => _showDeleteDialog(context, game),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
} 


void onDeleteGame(BuildContext context, Game game, Function(Game) onDeleteGame) {
   showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Delete Game'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to delete this game?',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Text(
              'Game: ${game.name}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Save Path: ${game.savePath}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          Button(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          FilledButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.red),
              foregroundColor: WidgetStateProperty.all(Colors.white),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              onDeleteGame(game);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
}