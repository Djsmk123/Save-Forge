import 'package:fluent_ui/fluent_ui.dart';
import 'package:game_save_manager/core/di/injection.dart';
import 'package:game_save_manager/core/logging/app_logger.dart';
import 'package:game_save_manager/core/compontents/info_bar.dart';
import 'package:game_save_manager/models/game.dart';

class ExportDialog extends StatefulWidget {
  final Game? selectedGame;
  
  const ExportDialog({
    super.key,
    this.selectedGame,
  });

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  bool _isExporting = false;
  final exportLogger = CategoryLogger(LoggerCategory.export);

  Future<void> _exportAllData() async {
    setState(() => _isExporting = true);
    
    try {
      await getIt.exportService.exportAllData();
      if (!mounted) return;
      
      showInfoBar(
        'Export Successful',
        'All games and profiles have been exported to the desktop',
        InfoBarSeverity.success,
      );
      
      Navigator.of(context).pop();
    } catch (e) {
      exportLogger.error('Failed to export all data', e);
      if (!mounted) return;
      
      showInfoBar(
        'Export Failed',
        'Failed to export data: $e',
        InfoBarSeverity.error,
      );
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportSelectedGame() async {
    if (widget.selectedGame == null) return;
    
    setState(() => _isExporting = true);
    
    try {
      await getIt.exportService.exportGameWithProfiles(widget.selectedGame!);
      if (!mounted) return;
      
      showInfoBar(
        'Export Successful',
        '${widget.selectedGame!.name} and its profiles have been exported to the desktop',
        InfoBarSeverity.success,
      );
      
      Navigator.of(context).pop();
    } catch (e) {
      exportLogger.error('Failed to export game', e);
      if (!mounted) return;
      
      showInfoBar(
        'Export Failed',
        'Failed to export game: $e',
        InfoBarSeverity.error,
      );
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportToLocation() async {
    setState(() => _isExporting = true);
    
    try {
      await getIt.exportService.exportToLocation();
      if (!mounted) return;
      
      showInfoBar(
        'Export Successful',
        'Data has been exported to the selected location',
        InfoBarSeverity.success,
      );
      
      Navigator.of(context).pop();
    } catch (e) {
      exportLogger.error('Failed to export to location', e);
      if (!mounted) return;
      
      showInfoBar(
        'Export Failed',
        'Failed to export data: $e',
        InfoBarSeverity.error,
      );
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportGameToLocation() async {
    if (widget.selectedGame == null) return;
    
    setState(() => _isExporting = true);
    
    try {
      await getIt.exportService.exportGameToLocation(widget.selectedGame!);
      if (!mounted) return;
      
      showInfoBar(
        'Export Successful',
        '${widget.selectedGame!.name} has been exported to the selected location',
        InfoBarSeverity.success,
      );
      
      Navigator.of(context).pop();
    } catch (e) {
      exportLogger.error('Failed to export game to location', e);
      if (!mounted) return;
      
      showInfoBar(
        'Export Failed',
        'Failed to export game: $e',
        InfoBarSeverity.error,
      );
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _importFromFile() async {
    try {
      await getIt.exportService.importFromFile();
      if (!mounted) return;
      
      showInfoBar(
        'Import Successful',
        'Data has been imported successfully',
        InfoBarSeverity.success,
      );
      
      Navigator.of(context).pop();
    } catch (e) {
      exportLogger.error('Failed to import from file', e);
      if (!mounted) return;
      
      showInfoBar(
        'Import Failed',
        'Failed to import data: $e',
        InfoBarSeverity.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = getIt.exportService.getExportStats();
    
    return ContentDialog(
      title: Row(
        children: [
          Icon(
            FluentIcons.export,
            size: 20,
            color: FluentTheme.of(context).accentColor,
          ),
          const SizedBox(width: 8),
          const Text('Export/Import Data'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistics
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Data',
                      style: FluentTheme.of(context).typography.title,
                    ),
                    const SizedBox(height: 8),
                    Text('Total Games: ${stats['totalGames']}'),
                    Text('Total Profiles: ${stats['totalProfiles']}'),
                    Text('Games with Profiles: ${stats['gamesWithProfiles']}'),
                    Text('Games without Profiles: ${stats['gamesWithoutProfiles']}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Export Options
            Text(
              'Export Options',
              style: FluentTheme.of(context).typography.subtitle,
            ),
            const SizedBox(height: 8),
            
            // Export All Data
            Button(
              onPressed: _isExporting ? null : _exportAllData,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(FluentIcons.export),
                  const SizedBox(width: 8),
                  const Text('Export All Data to Desktop'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            
            // Export Selected Game
            if (widget.selectedGame != null) ...[
              Button(
                onPressed: _isExporting ? null : _exportSelectedGame,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FluentIcons.game),
                    const SizedBox(width: 8),
                    Text('Export "${widget.selectedGame!.name}" to Desktop'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            
            // Export to Custom Location
            Button(
              onPressed: _isExporting ? null : _exportToLocation,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(FluentIcons.folder),
                  const SizedBox(width: 8),
                  const Text('Export All Data to Custom Location'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            
            // Export Game to Custom Location
            if (widget.selectedGame != null)
              Button(
                onPressed: _isExporting ? null : _exportGameToLocation,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FluentIcons.game),
                    const SizedBox(width: 8),
                    Text('Export "${widget.selectedGame!.name}" to Custom Location'),
                  ],
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Import Options
            Text(
              'Import Options',
              style: FluentTheme.of(context).typography.subtitle,
            ),
            const SizedBox(height: 8),
            
            Button(
              onPressed: _isExporting ? null : _importFromFile,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(FluentIcons.import),
                  const SizedBox(width: 8),
                  const Text('Import from JSON File'),
                ],
              ),
            ),
            
            if (_isExporting) ...[
              const SizedBox(height: 16),
              const Center(child: ProgressRing()),
            ],
          ],
        ),
      ),
      actions: [
        Button(
          onPressed: _isExporting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
} 