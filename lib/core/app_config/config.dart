class AppConfig {
  // API Configuration
  static const String rawgApiBaseUrl = 'https://api.rawg.io/api';
  static const String rawgApiKey = String.fromEnvironment('RAWG_API_KEY', defaultValue: '54f7cb2a58a84ed79ca354bf8f018702');
  
  // API Endpoints
  static const String gamesEndpoint = '/games';
  static const String gameDetailsEndpoint = '/games/{id}';
  static const String gameScreenshotsEndpoint = '/games/{id}/screenshots';
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 40;
  
  // Cache Configuration
  static const Duration cacheExpiration = Duration(hours: 24);
  static const int maxCacheSize = 100;
  
  // Search Configuration
  static const int minSearchLength = 2;
  static const Duration searchDebounce = Duration(milliseconds: 500);
  
  // Image Configuration
  static const String defaultGameImage = 'assets/icons/default.png';
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png', 'webp'];
  
  // Platform Configuration
  static const List<String> supportedPlatforms = [
    'PC',
    'PlayStation 5',
    'PlayStation 4',
    'Xbox One',
    'Xbox Series S/X',
    'Nintendo Switch',
    'Android',
    'iOS',
  ];
  
  // Store Configuration
  static const List<String> supportedStores = [
    'Steam',
    'PlayStation Store',
    'Xbox Store',
    'Epic Games',
    'GOG',
    'itch.io',
    'App Store',
    'Google Play',
  ];
}