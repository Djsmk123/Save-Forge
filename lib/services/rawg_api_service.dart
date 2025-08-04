import 'package:dio/dio.dart';
import 'package:game_save_manager/core/app_config/config.dart';
import 'package:game_save_manager/core/logging/app_logger.dart';
import 'package:game_save_manager/models/api/rawg_models.dart';
import 'package:game_save_manager/models/game.dart';

class RawgApiService {
  final Dio _dio;
  final apiLogger = CategoryLogger(LoggerCategory.network);

  RawgApiService() : _dio = Dio() {
    _dio.options.baseUrl = AppConfig.rawgApiBaseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    
    // Add API key to all requests
    _dio.options.queryParameters = {
      'key': AppConfig.rawgApiKey,
    };
    
    // Add interceptors for logging
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => apiLogger.debug(obj.toString()),
    ));
  }

  /// Search for games using RAWG API
  Future<RawgApiResponse<RawgGame>> searchGames(RawgSearchParams params) async {
    try {
      apiLogger.info('Searching games with params: ${params.toQueryParameters()}');
      if(params.mock){
        List<RawgGame> games = (mockJson()['results'] as List<dynamic>).map((game) => RawgGame.fromJson(game as Map<String, dynamic>)).toList();
        return RawgApiResponse<RawgGame>(
          count: mockJson()['count'] as int? ?? 0,
          next: mockJson()['next'] as String? ?? '',
          previous: mockJson()['previous'] as String? ?? '',
          results: games,
        );
      }
      
      final response = await _dio.get(
        AppConfig.gamesEndpoint,
        queryParameters: params.toQueryParameters(),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final games = (data['results'] as List<dynamic>)
            .map((game) => RawgGame.fromJson(game as Map<String, dynamic>))
            .toList();

        final result = RawgApiResponse<RawgGame>(
          count: data['count'] as int? ?? 0,
          next: data['next'] as String?,
          previous: data['previous'] as String?,
          results: games,
        );

        apiLogger.info('Found ${games.length} games out of ${result.count} total');
        return result;
      } else {
        throw Exception('Failed to search games: ${response.statusCode}');
      }
    } on DioException catch (e) {
      apiLogger.error('DioException while searching games', e);
      throw _handleDioError(e);
    } catch (e) {
      apiLogger.error('Unexpected error while searching games', e);
      rethrow;
    }
  }

  /// Get game details by ID
  Future<RawgGame> getGameDetails(int gameId) async {
    try {
      apiLogger.info('Fetching game details for ID: $gameId');
      
      final response = await _dio.get(
        AppConfig.gameDetailsEndpoint.replaceAll('{id}', gameId.toString()),
      );

      if (response.statusCode == 200) {
        final game = RawgGame.fromJson(response.data as Map<String, dynamic>);
        apiLogger.info('Successfully fetched game details: ${game.name}');
        return game;
      } else {
        throw Exception('Failed to get game details: ${response.statusCode}');
      }
    } on DioException catch (e) {
      apiLogger.error('DioException while getting game details', e);
      throw _handleDioError(e);
    } catch (e) {
      apiLogger.error('Unexpected error while getting game details', e);
      rethrow;
    }
  }

  /// Get game screenshots
  Future<List<RawgScreenshot>> getGameScreenshots(int gameId) async {
    try {
      apiLogger.info('Fetching screenshots for game ID: $gameId');
      
      final response = await _dio.get(
        AppConfig.gameScreenshotsEndpoint.replaceAll('{id}', gameId.toString()),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final screenshots = (data['results'] as List<dynamic>)
            .map((screenshot) => RawgScreenshot.fromJson(screenshot as Map<String, dynamic>))
            .toList();

        apiLogger.info('Successfully fetched ${screenshots.length} screenshots');
        return screenshots;
      } else {
        throw Exception('Failed to get game screenshots: ${response.statusCode}');
      }
    } on DioException catch (e) {
      apiLogger.error('DioException while getting game screenshots', e);
      throw _handleDioError(e);
    } catch (e) {
      apiLogger.error('Unexpected error while getting game screenshots', e);
      rethrow;
    }
  }

  /// Search games by name (simplified method)
  Future<List<RawgGame>> searchGamesByName(String query) async {
    try {
      final params = RawgSearchParams(
        search: query,
        pageSize: AppConfig.defaultPageSize,
      );
      
      final response = await searchGames(params);
      return response.results;
    } catch (e) {
      apiLogger.error('Error searching games by name: $query', e);
      rethrow;
    }
  }

  /// Get popular games
  Future<List<RawgGame>> getPopularGames({int pageSize = 20}) async {
    try {
      final params = RawgSearchParams(
        ordering: '-rating',
        pageSize: pageSize,
      );
      
      final response = await searchGames(params);
      return response.results;
    } catch (e) {
      apiLogger.error('Error getting popular games', e);
      rethrow;
    }
  }

  /// Get recent games
  Future<List<RawgGame>> getRecentGames({int pageSize = 20}) async {
    try {
      final params = RawgSearchParams(
        ordering: '-released',
        pageSize: pageSize,
      );
      
      final response = await searchGames(params);
      return response.results;
    } catch (e) {
      apiLogger.error('Error getting recent games', e);
      rethrow;
    }
  }

  /// Convert RAWG game to local Game model
  static Game convertToLocalGame(RawgGame rawgGame) {
    final now = DateTime.now();
    return Game(
      id: rawgGame.id.toString(),
      name: rawgGame.name??'',
      iconPath: rawgGame.backgroundImage ?? AppConfig.defaultGameImage,
      savePath: '', // User will need to set this
      executablePath: null, // User will need to set this
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Handle Dio errors
  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Connection timeout. Please check your internet connection.');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) {
          return Exception('API key is invalid or expired.');
        } else if (statusCode == 429) {
          return Exception('Rate limit exceeded. Please try again later.');
        } else if (statusCode == 404) {
          return Exception('Game not found.');
        } else {
          return Exception('Server error: $statusCode');
        }
      case DioExceptionType.cancel:
        return Exception('Request was cancelled.');
      case DioExceptionType.connectionError:
        return Exception('No internet connection.');
      default:
        return Exception('Network error: ${e.message}');
    }
  }

  /// Dispose resources
  void dispose() {
    _dio.close();
  }

  Map<String,dynamic> mockJson(){
    return {
  "count": 1084,
  "next": "https://api.rawg.io/api/games?key=54f7cb2a58a84ed79ca354bf8f018702&page=2&search=Assassin%27s+Creed",
  "previous": null,
  "results": [
    {
      "slug": "assassins-creed",
      "name": "Assassin's Creed",
      "playtime": 5,
      "platforms": [
        {
          "platform": {
            "id": 4,
            "name": "PC",
            "slug": "pc"
          }
        },
        {
          "platform": {
            "id": 1,
            "name": "Xbox One",
            "slug": "xbox-one"
          }
        },
        {
          "platform": {
            "id": 14,
            "name": "Xbox 360",
            "slug": "xbox360"
          }
        },
        {
          "platform": {
            "id": 16,
            "name": "PlayStation 3",
            "slug": "playstation3"
          }
        }
      ],
      "stores": [
        {
          "store": {
            "id": 3,
            "name": "PlayStation Store",
            "slug": "playstation-store"
          }
        },
        {
          "store": {
            "id": 2,
            "name": "Xbox Store",
            "slug": "xbox-store"
          }
        },
        {
          "store": {
            "id": 7,
            "name": "Xbox 360 Store",
            "slug": "xbox360"
          }
        }
      ],
      "released": "2007-11-13",
      "tba": false,
      "background_image": "https://media.rawg.io/media/games/0bc/0bcc108295a244b488d5c25f7d867220.jpg",
      "rating": 3.91,
      "rating_top": 4,
      "ratings": [
        {
          "id": 4,
          "title": "recommended",
          "count": 1166,
          "percent": 58.33
        },
        {
          "id": 5,
          "title": "exceptional",
          "count": 391,
          "percent": 19.56
        },
        {
          "id": 3,
          "title": "meh",
          "count": 380,
          "percent": 19.01
        },
        {
          "id": 1,
          "title": "skip",
          "count": 62,
          "percent": 3.1
        }
      ],
      "ratings_count": 1971,
      "reviews_text_count": 19,
      "added": 5424,
      "added_by_status": {
        "yet": 131,
        "owned": 2156,
        "beaten": 2527,
        "toplay": 138,
        "dropped": 430,
        "playing": 42
      },
      "metacritic": 80,
      "suggestions_count": 616,
      "updated": "2025-08-02T08:45:27",
      "id": 4729,
      "score": "91.73706",
      "clip": null,
      "tags": [
        {
          "id": 15,
          "name": "Stealth",
          "slug": "stealth",
          "language": "eng",
          "games_count": 6924,
          "image_background": "https://media.rawg.io/media/games/4fb/4fb548e4816c84d1d70f1a228fb167cc.jpg"
        },
        {
          "id": 25,
          "name": "Space",
          "slug": "space",
          "language": "eng",
          "games_count": 43900,
          "image_background": "https://media.rawg.io/media/games/5f4/5f4780690dbf04900cbac5f05b9305f3.jpg"
        },
        {
          "id": 278,
          "name": "Assassin",
          "slug": "assassin",
          "language": "eng",
          "games_count": 938,
          "image_background": "https://media.rawg.io/media/games/9c4/9c47f320eb73c9a02d462e12f6206b26.jpg"
        },
        {
          "id": 808,
          "name": "character",
          "slug": "character",
          "language": "eng",
          "games_count": 8876,
          "image_background": "https://media.rawg.io/media/games/cdd/cdd4b6cf03ac7ebf7460b0d82f9aaa09.jpg"
        },
        {
          "id": 2030,
          "name": "city",
          "slug": "city",
          "language": "eng",
          "games_count": 9276,
          "image_background": "https://media.rawg.io/media/games/257/257c497aa4060f4a697ccbf5e99ec230.jpg"
        },
        {
          "id": 326,
          "name": "Investigation",
          "slug": "investigation",
          "language": "eng",
          "games_count": 3156,
          "image_background": "https://media.rawg.io/media/games/f1d/f1d25c007b9b45c98b57ff9ebbca9692.jpg"
        },
        {
          "id": 3068,
          "name": "future",
          "slug": "future",
          "language": "eng",
          "games_count": 3140,
          "image_background": "https://media.rawg.io/media/games/5a9/5a9e785af72ae88026380f7987f23d90.jpg"
        },
        {
          "id": 425,
          "name": "Single player only",
          "slug": "single-player-only",
          "language": "eng",
          "games_count": 33,
          "image_background": "https://media.rawg.io/media/screenshots/1ac/1ac8e4433f332827a52aa43b3786d737.jpeg"
        },
        {
          "id": 1328,
          "name": "office",
          "slug": "office",
          "language": "eng",
          "games_count": 1073,
          "image_background": "https://media.rawg.io/media/screenshots/34a/34ab311451a42830da586fe02c37fb59.jpg"
        },
        {
          "id": 3626,
          "name": "treasure",
          "slug": "treasure",
          "language": "eng",
          "games_count": 1880,
          "image_background": "https://media.rawg.io/media/games/9d3/9d335d988b809912a3f7876523916578.jpg"
        }
      ],
      "esrb_rating": {
        "id": 4,
        "name": "Mature",
        "slug": "mature",
        "name_en": "Mature",
        "name_ru": "С 17 лет"
      },
      "user_game": null,
      "reviews_count": 1999,
      "saturated_color": "0f0f0f",
      "dominant_color": "0f0f0f",
      "short_screenshots": [
        {
          "id": -1,
          "image": "https://media.rawg.io/media/games/0bc/0bcc108295a244b488d5c25f7d867220.jpg"
        },
        {
          "id": 459661,
          "image": "https://media.rawg.io/media/screenshots/0dc/0dc9daa10241d1e05bf29d4c34bf87c3.jpg"
        },
        {
          "id": 459662,
          "image": "https://media.rawg.io/media/screenshots/35b/35bc2e90473975c2125a519e008dbe92.jpg"
        },
        {
          "id": 459663,
          "image": "https://media.rawg.io/media/screenshots/900/9000a97620418d8bfa17f839ff0e895b.jpg"
        },
        {
          "id": 459664,
          "image": "https://media.rawg.io/media/screenshots/543/543b1c938b04bc73b104ae6df7e5287e.jpg"
        },
        {
          "id": 459665,
          "image": "https://media.rawg.io/media/screenshots/b8e/b8e8da9d02a271776bef17a425552040.jpg"
        },
        {
          "id": 459666,
          "image": "https://media.rawg.io/media/screenshots/5a5/5a5520aee0b77d39a0b296c8db1f4b53.jpg"
        }
      ],
      "parent_platforms": [
        {
          "platform": {
            "id": 1,
            "name": "PC",
            "slug": "pc"
          }
        },
        {
          "platform": {
            "id": 2,
            "name": "PlayStation",
            "slug": "playstation"
          }
        },
        {
          "platform": {
            "id": 3,
            "name": "Xbox",
            "slug": "xbox"
          }
        }
      ],
      "genres": [
        {
          "id": 4,
          "name": "Action",
          "slug": "action"
        }
      ]
    },
    {
      "slug": "assassins-creed-valhalla",
      "name": "Assassin's Creed Valhalla",
      "playtime": 5,
      "platforms": [
        {
          "platform": {
            "id": 4,
            "name": "PC",
            "slug": "pc"
          }
        },
        {
          "platform": {
            "id": 187,
            "name": "PlayStation 5",
            "slug": "playstation5"
          }
        },
        {
          "platform": {
            "id": 1,
            "name": "Xbox One",
            "slug": "xbox-one"
          }
        },
        {
          "platform": {
            "id": 18,
            "name": "PlayStation 4",
            "slug": "playstation4"
          }
        },
        {
          "platform": {
            "id": 186,
            "name": "Xbox Series S/X",
            "slug": "xbox-series-x"
          }
        }
      ],
      "stores": [
        {
          "store": {
            "id": 1,
            "name": "Steam",
            "slug": "steam"
          }
        },
        {
          "store": {
            "id": 3,
            "name": "PlayStation Store",
            "slug": "playstation-store"
          }
        },
        {
          "store": {
            "id": 2,
            "name": "Xbox Store",
            "slug": "xbox-store"
          }
        },
        {
          "store": {
            "id": 11,
            "name": "Epic Games",
            "slug": "epic-games"
          }
        }
      ],
      "released": "2020-11-10",
      "tba": false,
      "background_image": "https://media.rawg.io/media/games/934/9346092ae11bf7582c883869468171cc.jpg",
      "rating": 3.69,
      "rating_top": 4,
      "ratings": [
        {
          "id": 4,
          "title": "recommended",
          "count": 349,
          "percent": 44.35
        },
        {
          "id": 3,
          "title": "meh",
          "count": 194,
          "percent": 24.65
        },
        {
          "id": 5,
          "title": "exceptional",
          "count": 171,
          "percent": 21.73
        },
        {
          "id": 1,
          "title": "skip",
          "count": 73,
          "percent": 9.28
        }
      ],
      "ratings_count": 763,
      "reviews_text_count": 16,
      "added": 4408,
      "added_by_status": {
        "yet": 384,
        "owned": 2264,
        "beaten": 534,
        "toplay": 679,
        "dropped": 348,
        "playing": 199
      },
      "metacritic": 82,
      "suggestions_count": 470,
      "updated": "2025-07-30T08:56:02",
      "id": 437059,
      "score": "59.745445",
      "clip": null,
      "tags": [
        {
          "id": 31,
          "name": "Singleplayer",
          "slug": "singleplayer",
          "language": "eng",
          "games_count": 243828,
          "image_background": "https://media.rawg.io/media/games/f46/f466571d536f2e3ea9e815ad17177501.jpg"
        },
        {
          "id": 42396,
          "name": "Для одного игрока",
          "slug": "dlia-odnogo-igroka",
          "language": "rus",
          "games_count": 65063,
          "image_background": "https://media.rawg.io/media/games/511/5118aff5091cb3efec399c808f8c598f.jpg"
        },
        {
          "id": 42417,
          "name": "Экшен",
          "slug": "ekshen",
          "language": "rus",
          "games_count": 47885,
          "image_background": "https://media.rawg.io/media/games/7fa/7fa0b586293c5861ee32490e953a4996.jpg"
        },
        {
          "id": 42392,
          "name": "Приключение",
          "slug": "prikliuchenie",
          "language": "rus",
          "games_count": 46267,
          "image_background": "https://media.rawg.io/media/games/26d/26d4437715bee60138dab4a7c8c59c92.jpg"
        },
        {
          "id": 7,
          "name": "Multiplayer",
          "slug": "multiplayer",
          "language": "eng",
          "games_count": 41388,
          "image_background": "https://media.rawg.io/media/games/34b/34b1f1850a1c06fd971bc6ab3ac0ce0e.jpg"
        },
        {
          "id": 13,
          "name": "Atmospheric",
          "slug": "atmospheric",
          "language": "eng",
          "games_count": 37992,
          "image_background": "https://media.rawg.io/media/games/737/737ea5662211d2e0bbd6f5989189e4f1.jpg"
        },
        {
          "id": 42425,
          "name": "Для нескольких игроков",
          "slug": "dlia-neskolkikh-igrokov",
          "language": "rus",
          "games_count": 12143,
          "image_background": "https://media.rawg.io/media/games/ec3/ec3a7db7b8ab5a71aad622fe7c62632f.jpg"
        },
        {
          "id": 42394,
          "name": "Глубокий сюжет",
          "slug": "glubokii-siuzhet",
          "language": "rus",
          "games_count": 16612,
          "image_background": "https://media.rawg.io/media/games/6c5/6c55e22185876626881b76c11922b073.jpg"
        },
        {
          "id": 24,
          "name": "RPG",
          "slug": "rpg",
          "language": "eng",
          "games_count": 25171,
          "image_background": "https://media.rawg.io/media/games/b45/b45575f34285f2c4479c9a5f719d972e.jpg"
        },
        {
          "id": 42412,
          "name": "Ролевая игра",
          "slug": "rolevaia-igra",
          "language": "rus",
          "games_count": 21574,
          "image_background": "https://media.rawg.io/media/games/26d/26d4437715bee60138dab4a7c8c59c92.jpg"
        },
        {
          "id": 118,
          "name": "Story Rich",
          "slug": "story-rich",
          "language": "eng",
          "games_count": 25746,
          "image_background": "https://media.rawg.io/media/games/26d/26d4437715bee60138dab4a7c8c59c92.jpg"
        },
        {
          "id": 42442,
          "name": "Открытый мир",
          "slug": "otkrytyi-mir",
          "language": "rus",
          "games_count": 7003,
          "image_background": "https://media.rawg.io/media/games/6cd/6cd653e0aaef5ff8bbd295bf4bcb12eb.jpg"
        },
        {
          "id": 36,
          "name": "Open World",
          "slug": "open-world",
          "language": "eng",
          "games_count": 8816,
          "image_background": "https://media.rawg.io/media/games/e6d/e6de699bd788497f4b52e2f41f9698f2.jpg"
        },
        {
          "id": 42441,
          "name": "От третьего лица",
          "slug": "ot-tretego-litsa",
          "language": "rus",
          "games_count": 9458,
          "image_background": "https://media.rawg.io/media/games/b49/b4912b5dbfc7ed8927b65f05b8507f6c.jpg"
        },
        {
          "id": 149,
          "name": "Third Person",
          "slug": "third-person",
          "language": "eng",
          "games_count": 13934,
          "image_background": "https://media.rawg.io/media/games/562/562553814dd54e001a541e4ee83a591c.jpg"
        },
        {
          "id": 40845,
          "name": "Partial Controller Support",
          "slug": "partial-controller-support",
          "language": "eng",
          "games_count": 13444,
          "image_background": "https://media.rawg.io/media/games/2ad/2ad87a4a69b1104f02435c14c5196095.jpg"
        },
        {
          "id": 64,
          "name": "Fantasy",
          "slug": "fantasy",
          "language": "eng",
          "games_count": 31629,
          "image_background": "https://media.rawg.io/media/games/af7/af7a831001c5c32c46e950cc883b8cb7.jpg"
        },
        {
          "id": 42491,
          "name": "Мясо",
          "slug": "miaso",
          "language": "rus",
          "games_count": 4962,
          "image_background": "https://media.rawg.io/media/games/c6b/c6bd26767c1053fef2b10bb852943559.jpg"
        },
        {
          "id": 26,
          "name": "Gore",
          "slug": "gore",
          "language": "eng",
          "games_count": 6372,
          "image_background": "https://media.rawg.io/media/games/858/858c016de0cf7bc21a57dcc698a04a0c.jpg"
        },
        {
          "id": 189,
          "name": "Female Protagonist",
          "slug": "female-protagonist",
          "language": "eng",
          "games_count": 14719,
          "image_background": "https://media.rawg.io/media/games/e3d/e3ddc524c6292a435d01d97cc5f42ea7.jpg"
        },
        {
          "id": 42402,
          "name": "Насилие",
          "slug": "nasilie",
          "language": "rus",
          "games_count": 6484,
          "image_background": "https://media.rawg.io/media/games/5bf/5bf88a28de96321c86561a65ee48e6c2.jpg"
        },
        {
          "id": 34,
          "name": "Violent",
          "slug": "violent",
          "language": "eng",
          "games_count": 7522,
          "image_background": "https://media.rawg.io/media/games/67f/67f62d1f062a6164f57575e0604ee9f6.jpg"
        },
        {
          "id": 15,
          "name": "Stealth",
          "slug": "stealth",
          "language": "eng",
          "games_count": 6913,
          "image_background": "https://media.rawg.io/media/games/7ac/7aca7ccf0e70cd0974cb899ab9e5158e.jpg"
        },
        {
          "id": 42439,
          "name": "Стелс",
          "slug": "stels",
          "language": "rus",
          "games_count": 2771,
          "image_background": "https://media.rawg.io/media/games/1bd/1bd2657b81eb0c99338120ad444b24ff.jpg"
        },
        {
          "id": 69,
          "name": "Action-Adventure",
          "slug": "action-adventure",
          "language": "eng",
          "games_count": 19877,
          "image_background": "https://media.rawg.io/media/games/fc3/fc30790a3b3c738d7a271b02c1e26dc2.jpg"
        },
        {
          "id": 97,
          "name": "Action RPG",
          "slug": "action-rpg",
          "language": "eng",
          "games_count": 8280,
          "image_background": "https://media.rawg.io/media/games/bc0/bc06a29ceac58652b684deefe7d56099.jpg"
        },
        {
          "id": 42489,
          "name": "Ролевой экшен",
          "slug": "rolevoi-ekshen",
          "language": "rus",
          "games_count": 5271,
          "image_background": "https://media.rawg.io/media/games/d1f/d1f872a48286b6b751670817d5c1e1be.jpg"
        },
        {
          "id": 42406,
          "name": "Нагота",
          "slug": "nagota",
          "language": "rus",
          "games_count": 7775,
          "image_background": "https://media.rawg.io/media/games/260/26023c855f1769a93411d6a7ea084632.jpeg"
        },
        {
          "id": 44,
          "name": "Nudity",
          "slug": "nudity",
          "language": "eng",
          "games_count": 8170,
          "image_background": "https://media.rawg.io/media/games/8ca/8ca40b562a755d6a0e30d48e6c74b178.jpg"
        },
        {
          "id": 42490,
          "name": "Приключенческий экшен",
          "slug": "prikliuchencheskii-ekshen",
          "language": "rus",
          "games_count": 12267,
          "image_background": "https://media.rawg.io/media/games/baf/baf9905270314e07e6850cffdb51df41.jpg"
        },
        {
          "id": 40837,
          "name": "In-App Purchases",
          "slug": "in-app-purchases",
          "language": "eng",
          "games_count": 3217,
          "image_background": "https://media.rawg.io/media/games/742/7424c1f7d0a8da9ae29cd866f985698b.jpg"
        },
        {
          "id": 40833,
          "name": "Captions available",
          "slug": "captions-available",
          "language": "eng",
          "games_count": 1458,
          "image_background": "https://media.rawg.io/media/games/b8c/b8c243eaa0fbac8115e0cdccac3f91dc.jpg"
        },
        {
          "id": 42405,
          "name": "Сексуальный контент",
          "slug": "seksualnyi-kontent",
          "language": "rus",
          "games_count": 8010,
          "image_background": "https://media.rawg.io/media/games/934/9346092ae11bf7582c883869468171cc.jpg"
        },
        {
          "id": 89,
          "name": "Historical",
          "slug": "historical",
          "language": "eng",
          "games_count": 3791,
          "image_background": "https://media.rawg.io/media/games/849/849414b978db37d4563ff9e4b0d3a787.jpg"
        },
        {
          "id": 50,
          "name": "Sexual Content",
          "slug": "sexual-content",
          "language": "eng",
          "games_count": 8048,
          "image_background": "https://media.rawg.io/media/games/a9c/a9c789951de65da545d51f664b4f2ce0.jpg"
        },
        {
          "id": 58132,
          "name": "Атмосферная",
          "slug": "atmosfernaia",
          "language": "rus",
          "games_count": 13696,
          "image_background": "https://media.rawg.io/media/games/e85/e851f527ab0658519436342ee73da191.jpg"
        },
        {
          "id": 278,
          "name": "Assassin",
          "slug": "assassin",
          "language": "eng",
          "games_count": 938,
          "image_background": "https://media.rawg.io/media/games/c35/c354856af9151dc63844be4f9843d2c2.jpg"
        },
        {
          "id": 42440,
          "name": "Ассассины",
          "slug": "assassiny",
          "language": "rus",
          "games_count": 456,
          "image_background": "https://media.rawg.io/media/games/4e6/4e6e8e7f50c237d76f38f3c885dae3d2.jpg"
        },
        {
          "id": 59643,
          "name": "Протагонистка",
          "slug": "protagonistka",
          "language": "eng",
          "games_count": 7198,
          "image_background": "https://media.rawg.io/media/games/d47/d479582ed0a46496ad34f65c7099d7e5.jpg"
        },
        {
          "id": 66539,
          "name": "Историческая",
          "slug": "istoricheskaia",
          "language": "rus",
          "games_count": 2052,
          "image_background": "https://media.rawg.io/media/games/32e/32ec3c0a53bf3ff458211ea45d8a3bdb.jpg"
        },
        {
          "id": 6046,
          "name": "vikings",
          "slug": "vikings",
          "language": "eng",
          "games_count": 184,
          "image_background": "https://media.rawg.io/media/screenshots/608/6081f6b90a549f6ca0996e279ae18dd3.jpg"
        },
        {
          "id": 69243,
          "name": "Викинги",
          "slug": "vikingi",
          "language": "rus",
          "games_count": 46,
          "image_background": "https://media.rawg.io/media/screenshots/608/6081f6b90a549f6ca0996e279ae18dd3.jpg"
        }
      ],
      "esrb_rating": null,
      "user_game": null,
      "reviews_count": 787,
      "saturated_color": "0f0f0f",
      "dominant_color": "0f0f0f",
      "short_screenshots": [
        {
          "id": -1,
          "image": "https://media.rawg.io/media/games/934/9346092ae11bf7582c883869468171cc.jpg"
        },
        {
          "id": 2366796,
          "image": "https://media.rawg.io/media/screenshots/40d/40d4c5e37758450905c985918ab6ea11.jpg"
        },
        {
          "id": 2366797,
          "image": "https://media.rawg.io/media/screenshots/c5b/c5b052449f59eb31a0dcf01967d0715b.jpg"
        },
        {
          "id": 2366798,
          "image": "https://media.rawg.io/media/screenshots/0fa/0fab0247d40f79a2f35fe8143dc438ec.jpg"
        },
        {
          "id": 2366799,
          "image": "https://media.rawg.io/media/screenshots/50e/50efcd7fdd2967ddd73c9911985339dc.jpg"
        },
        {
          "id": 2366800,
          "image": "https://media.rawg.io/media/screenshots/4c4/4c4e1c1079b11760d07847f83cc1a2a8.jpg"
        },
        {
          "id": 2366801,
          "image": "https://media.rawg.io/media/screenshots/a07/a07f4c2dab611d69357f20f32435b1a2.jpg"
        }
      ],
      "parent_platforms": [
        {
          "platform": {
            "id": 1,
            "name": "PC",
            "slug": "pc"
          }
        },
        {
          "platform": {
            "id": 2,
            "name": "PlayStation",
            "slug": "playstation"
          }
        },
        {
          "platform": {
            "id": 3,
            "name": "Xbox",
            "slug": "xbox"
          }
        }
      ],
      "genres": [
        {
          "id": 3,
          "name": "Adventure",
          "slug": "adventure"
        },
        {
          "id": 4,
          "name": "Action",
          "slug": "action"
        },
        {
          "id": 5,
          "name": "RPG",
          "slug": "role-playing-games-rpg"
        }
      ]
    },
    {
      "slug": "assassins-creed-origins",
      "name": "Assassin's Creed Origins",
      "playtime": 28,
      "platforms": [
        {
          "platform": {
            "id": 4,
            "name": "PC",
            "slug": "pc"
          }
        },
        {
          "platform": {
            "id": 1,
            "name": "Xbox One",
            "slug": "xbox-one"
          }
        },
        {
          "platform": {
            "id": 18,
            "name": "PlayStation 4",
            "slug": "playstation4"
          }
        }
      ],
      "stores": [
        {
          "store": {
            "id": 1,
            "name": "Steam",
            "slug": "steam"
          }
        },
        {
          "store": {
            "id": 3,
            "name": "PlayStation Store",
            "slug": "playstation-store"
          }
        },
        {
          "store": {
            "id": 2,
            "name": "Xbox Store",
            "slug": "xbox-store"
          }
        }
      ],
      "released": "2017-10-27",
      "tba": false,
      "background_image": "https://media.rawg.io/media/games/336/336c6bd63d83cf8e59937ab8895d1240.jpg",
      "rating": 3.96,
      "rating_top": 4,
      "ratings": [
        {
          "id": 4,
          "title": "recommended",
          "count": 1083,
          "percent": 51.6
        },
        {
          "id": 5,
          "title": "exceptional",
          "count": 556,
          "percent": 26.49
        },
        {
          "id": 3,
          "title": "meh",
          "count": 375,
          "percent": 17.87
        },
        {
          "id": 1,
          "title": "skip",
          "count": 85,
          "percent": 4.05
        }
      ],
      "ratings_count": 2068,
      "reviews_text_count": 23,
      "added": 7880,
      "added_by_status": {
        "yet": 452,
        "owned": 4321,
        "beaten": 1812,
        "toplay": 477,
        "dropped": 574,
        "playing": 244
      },
      "metacritic": 81,
      "suggestions_count": 331,
      "updated": "2025-07-31T19:19:26",
      "id": 28153,
      "score": "59.745445",
      "clip": null,
      "tags": [
        {
          "id": 42396,
          "name": "Для одного игрока",
          "slug": "dlia-odnogo-igroka",
          "language": "rus",
          "games_count": 65063,
          "image_background": "https://media.rawg.io/media/games/511/5118aff5091cb3efec399c808f8c598f.jpg"
        },
        {
          "id": 42417,
          "name": "Экшен",
          "slug": "ekshen",
          "language": "rus",
          "games_count": 47885,
          "image_background": "https://media.rawg.io/media/games/7fa/7fa0b586293c5861ee32490e953a4996.jpg"
        },
        {
          "id": 42392,
          "name": "Приключение",
          "slug": "prikliuchenie",
          "language": "rus",
          "games_count": 46267,
          "image_background": "https://media.rawg.io/media/games/26d/26d4437715bee60138dab4a7c8c59c92.jpg"
        },
        {
          "id": 42425,
          "name": "Для нескольких игроков",
          "slug": "dlia-neskolkikh-igrokov",
          "language": "rus",
          "games_count": 12143,
          "image_background": "https://media.rawg.io/media/games/ec3/ec3a7db7b8ab5a71aad622fe7c62632f.jpg"
        },
        {
          "id": 42400,
          "name": "Атмосфера",
          "slug": "atmosfera",
          "language": "rus",
          "games_count": 6083,
          "image_background": "https://media.rawg.io/media/games/737/737ea5662211d2e0bbd6f5989189e4f1.jpg"
        },
        {
          "id": 42401,
          "name": "Отличный саундтрек",
          "slug": "otlichnyi-saundtrek",
          "language": "rus",
          "games_count": 4658,
          "image_background": "https://media.rawg.io/media/games/20a/20aa03a10cda45239fe22d035c0ebe64.jpg"
        },
        {
          "id": 42394,
          "name": "Глубокий сюжет",
          "slug": "glubokii-siuzhet",
          "language": "rus",
          "games_count": 16612,
          "image_background": "https://media.rawg.io/media/games/6c5/6c55e22185876626881b76c11922b073.jpg"
        },
        {
          "id": 42412,
          "name": "Ролевая игра",
          "slug": "rolevaia-igra",
          "language": "rus",
          "games_count": 21574,
          "image_background": "https://media.rawg.io/media/games/26d/26d4437715bee60138dab4a7c8c59c92.jpg"
        },
        {
          "id": 42442,
          "name": "Открытый мир",
          "slug": "otkrytyi-mir",
          "language": "rus",
          "games_count": 7003,
          "image_background": "https://media.rawg.io/media/games/6cd/6cd653e0aaef5ff8bbd295bf4bcb12eb.jpg"
        },
        {
          "id": 42441,
          "name": "От третьего лица",
          "slug": "ot-tretego-litsa",
          "language": "rus",
          "games_count": 9458,
          "image_background": "https://media.rawg.io/media/games/b49/b4912b5dbfc7ed8927b65f05b8507f6c.jpg"
        },
        {
          "id": 42444,
          "name": "Песочница",
          "slug": "pesochnitsa",
          "language": "rus",
          "games_count": 5317,
          "image_background": "https://media.rawg.io/media/games/58a/58ac7f6569259dcc0b60b921869b19fc.jpg"
        },
        {
          "id": 42464,
          "name": "Исследование",
          "slug": "issledovanie",
          "language": "rus",
          "games_count": 2979,
          "image_background": "https://media.rawg.io/media/games/e6d/e6de699bd788497f4b52e2f41f9698f2.jpg"
        },
        {
          "id": 42439,
          "name": "Стелс",
          "slug": "stels",
          "language": "rus",
          "games_count": 2771,
          "image_background": "https://media.rawg.io/media/games/1bd/1bd2657b81eb0c99338120ad444b24ff.jpg"
        },
        {
          "id": 42489,
          "name": "Ролевой экшен",
          "slug": "rolevoi-ekshen",
          "language": "rus",
          "games_count": 5271,
          "image_background": "https://media.rawg.io/media/games/d1f/d1f872a48286b6b751670817d5c1e1be.jpg"
        },
        {
          "id": 42403,
          "name": "История",
          "slug": "istoriia",
          "language": "rus",
          "games_count": 940,
          "image_background": "https://media.rawg.io/media/games/bff/bff7d82316cddea9541261a045ba008a.jpg"
        },
        {
          "id": 42555,
          "name": "Симулятор ходьбы",
          "slug": "simuliator-khodby",
          "language": "rus",
          "games_count": 4020,
          "image_background": "https://media.rawg.io/media/games/813/813f9dab418a3d549f8b9ad8ef2f3d9c.jpg"
        },
        {
          "id": 42643,
          "name": "Паркур",
          "slug": "parkur-2",
          "language": "rus",
          "games_count": 1637,
          "image_background": "https://media.rawg.io/media/games/bd7/bd7cfccfececba1ec2b97a120a40373f.jpg"
        },
        {
          "id": 42440,
          "name": "Ассассины",
          "slug": "assassiny",
          "language": "rus",
          "games_count": 456,
          "image_background": "https://media.rawg.io/media/games/4e6/4e6e8e7f50c237d76f38f3c885dae3d2.jpg"
        },
        {
          "id": 42447,
          "name": "Ограбления",
          "slug": "ogrableniia",
          "language": "rus",
          "games_count": 314,
          "image_background": "https://media.rawg.io/media/games/b50/b501727147644474562935f19a60134e.jpg"
        },
        {
          "id": 42448,
          "name": "Иллюминаты",
          "slug": "illiuminaty",
          "language": "rus",
          "games_count": 311,
          "image_background": "https://media.rawg.io/media/games/050/050946c00aa9c48111af5e3c2469b209.jpg"
        }
      ],
      "esrb_rating": {
        "id": 4,
        "name": "Mature",
        "slug": "mature",
        "name_en": "Mature",
        "name_ru": "С 17 лет"
      },
      "user_game": null,
      "reviews_count": 2099,
      "saturated_color": "0f0f0f",
      "dominant_color": "0f0f0f",
      "short_screenshots": [
        {
          "id": -1,
          "image": "https://media.rawg.io/media/games/336/336c6bd63d83cf8e59937ab8895d1240.jpg"
        },
        {
          "id": 269374,
          "image": "https://media.rawg.io/media/screenshots/5c8/5c8c5889c81eb226b182e6df4018a29a.jpg"
        },
        {
          "id": 269376,
          "image": "https://media.rawg.io/media/screenshots/0cf/0cf5ed35a3906f32967cb476c11c5d49.jpg"
        },
        {
          "id": 287526,
          "image": "https://media.rawg.io/media/screenshots/313/3132876284966c4d055d752e7edc5509.jpg"
        },
        {
          "id": 287529,
          "image": "https://media.rawg.io/media/screenshots/b3f/b3fe4ade2ed930cbd8253269ff38ba28.jpg"
        },
        {
          "id": 313977,
          "image": "https://media.rawg.io/media/screenshots/2d7/2d7a5c1b08e5cc5bc7c371094376637c.jpg"
        },
        {
          "id": 2408505,
          "image": "https://media.rawg.io/media/screenshots/0a2/0a24d82ed3f2d35726d17e4c73593721.jpeg"
        }
      ],
      "parent_platforms": [
        {
          "platform": {
            "id": 1,
            "name": "PC",
            "slug": "pc"
          }
        },
        {
          "platform": {
            "id": 2,
            "name": "PlayStation",
            "slug": "playstation"
          }
        },
        {
          "platform": {
            "id": 3,
            "name": "Xbox",
            "slug": "xbox"
          }
        }
      ],
      "genres": [
        {
          "id": 4,
          "name": "Action",
          "slug": "action"
        },
        {
          "id": 5,
          "name": "RPG",
          "slug": "role-playing-games-rpg"
        }
      ]
    },
    {
      "slug": "assassins-creed-rebellion",
      "name": "Assassin's Creed: Rebellion",
      "playtime": 0,
      "platforms": [
        {
          "platform": {
            "id": 3,
            "name": "iOS",
            "slug": "ios"
          }
        },
        {
          "platform": {
            "id": 21,
            "name": "Android",
            "slug": "android"
          }
        }
      ],
      "stores": [
        {
          "store": {
            "id": 4,
            "name": "App Store",
            "slug": "apple-appstore"
          }
        },
        {
          "store": {
            "id": 8,
            "name": "Google Play",
            "slug": "google-play"
          }
        }
      ],
      "released": "2018-11-20",
      "tba": false,
      "background_image": "https://media.rawg.io/media/games/ba8/ba84e7677e6367f0dee820567387980d.jpg",
      "rating": 2.92,
      "rating_top": 4,
      "ratings": [
        {
          "id": 4,
          "title": "recommended",
          "count": 20,
          "percent": 39.22
        },
        {
          "id": 3,
          "title": "meh",
          "count": 19,
          "percent": 37.25
        },
        {
          "id": 1,
          "title": "skip",
          "count": 12,
          "percent": 23.53
        }
      ],
      "ratings_count": 51,
      "reviews_text_count": 0,
      "added": 94,
      "added_by_status": {
        "yet": 6,
        "owned": 19,
        "beaten": 12,
        "toplay": 5,
        "dropped": 51,
        "playing": 1
      },
      "metacritic": 63,
      "suggestions_count": 435,
      "updated": "2025-01-03T07:43:22",
      "id": 267229,
      "score": "59.411736",
      "clip": null,
      "tags": [
        {
          "id": 24,
          "name": "RPG",
          "slug": "rpg",
          "language": "eng",
          "games_count": 24938,
          "image_background": "https://media.rawg.io/media/games/ee3/ee3e10193aafc3230ba1cae426967d10.jpg"
        },
        {
          "id": 406,
          "name": "Story",
          "slug": "story",
          "language": "eng",
          "games_count": 11517,
          "image_background": "https://media.rawg.io/media/games/08e/08e8d09cd5aae30959c4486649fda3e6.jpg"
        },
        {
          "id": 413,
          "name": "online",
          "slug": "online",
          "language": "eng",
          "games_count": 6555,
          "image_background": "https://media.rawg.io/media/games/739/73990e3ec9f43a9e8ecafe207fa4f368.jpg"
        },
        {
          "id": 278,
          "name": "Assassin",
          "slug": "assassin",
          "language": "eng",
          "games_count": 930,
          "image_background": "https://media.rawg.io/media/games/742/74276457ebb9466e11d75a2be7722265.jpg"
        },
        {
          "id": 98,
          "name": "Loot",
          "slug": "loot",
          "language": "eng",
          "games_count": 2678,
          "image_background": "https://media.rawg.io/media/games/bad/bad95aa1f2edbbad2ae93981291b6560.jpg"
        },
        {
          "id": 808,
          "name": "character",
          "slug": "character",
          "language": "eng",
          "games_count": 8876,
          "image_background": "https://media.rawg.io/media/games/56e/56ed40948bebaf1968234aa6e3c74771.jpg"
        },
        {
          "id": 730,
          "name": "youtube",
          "slug": "youtube",
          "language": "eng",
          "games_count": 4215,
          "image_background": "https://media.rawg.io/media/screenshots/d7b/d7b7a8d13aa7fc8cfb0dabc5d597bc15_6qWuh2W.jpg"
        },
        {
          "id": 1787,
          "name": "mobile",
          "slug": "mobile",
          "language": "eng",
          "games_count": 4592,
          "image_background": "https://media.rawg.io/media/screenshots/452/45212651232aa13fbed24a6a925bf1f5.jpg"
        },
        {
          "id": 784,
          "name": "train",
          "slug": "train",
          "language": "eng",
          "games_count": 3126,
          "image_background": "https://media.rawg.io/media/games/7bf/7bfd58320fe723d7a7064099515f1131.jpeg"
        }
      ],
      "esrb_rating": {
        "id": 1,
        "name": "Everyone",
        "slug": "everyone",
        "name_en": "Everyone",
        "name_ru": "Для всех"
      },
      "user_game": null,
      "reviews_count": 51,
      "saturated_color": "0f0f0f",
      "dominant_color": "0f0f0f",
      "short_screenshots": [
        {
          "id": -1,
          "image": "https://media.rawg.io/media/games/ba8/ba84e7677e6367f0dee820567387980d.jpg"
        },
        {
          "id": 1741676,
          "image": "https://media.rawg.io/media/screenshots/67b/67bc3f5dbec9cefed1724eadefe65a1c_WEmdfVr.jpg"
        },
        {
          "id": 1741677,
          "image": "https://media.rawg.io/media/screenshots/265/2650461bc91e5ecfda71685ff1a22588_pE34zHR.jpg"
        },
        {
          "id": 1741678,
          "image": "https://media.rawg.io/media/screenshots/dac/dacedf330f150495634cfb2636579d7a.jpg"
        },
        {
          "id": 1741679,
          "image": "https://media.rawg.io/media/screenshots/da0/da0fdc542270639e6c591bc0fbfa4c49_WVgwSzh.jpg"
        },
        {
          "id": 1741680,
          "image": "https://media.rawg.io/media/screenshots/185/18545d7b9b087815745e119af4317113_1G9wWzq.jpg"
        },
        {
          "id": 1741487,
          "image": "https://media.rawg.io/media/screenshots/6fd/6fd98870bc0e1a3fdd463def55a0285a.jpg"
        }
      ],
      "parent_platforms": [
        {
          "platform": {
            "id": 4,
            "name": "iOS",
            "slug": "ios"
          }
        },
        {
          "platform": {
            "id": 8,
            "name": "Android",
            "slug": "android"
          }
        }
      ],
      "genres": [
        {
          "id": 10,
          "name": "Strategy",
          "slug": "strategy"
        },
        {
          "id": 3,
          "name": "Adventure",
          "slug": "adventure"
        },
        {
          "id": 4,
          "name": "Action",
          "slug": "action"
        },
        {
          "id": 5,
          "name": "RPG",
          "slug": "role-playing-games-rpg"
        }
      ]
    },
    {
      "slug": "assassins-creed-unity-2",
      "name": "Assassin's Creed Unity",
      "playtime": 14,
      "platforms": [
        {
          "platform": {
            "id": 4,
            "name": "PC",
            "slug": "pc"
          }
        },
        {
          "platform": {
            "id": 1,
            "name": "Xbox One",
            "slug": "xbox-one"
          }
        },
        {
          "platform": {
            "id": 18,
            "name": "PlayStation 4",
            "slug": "playstation4"
          }
        }
      ],
      "stores": [
        {
          "store": {
            "id": 1,
            "name": "Steam",
            "slug": "steam"
          }
        },
        {
          "store": {
            "id": 3,
            "name": "PlayStation Store",
            "slug": "playstation-store"
          }
        },
        {
          "store": {
            "id": 2,
            "name": "Xbox Store",
            "slug": "xbox-store"
          }
        }
      ],
      "released": "2014-11-11",
      "tba": false,
      "background_image": "https://media.rawg.io/media/games/59f/59fc1c5de1d29cb9234741c97d250150.jpg",
      "rating": 3.63,
      "rating_top": 4,
      "ratings": [
        {
          "id": 4,
          "title": "recommended",
          "count": 876,
          "percent": 51.05
        },
        {
          "id": 3,
          "title": "meh",
          "count": 479,
          "percent": 27.91
        },
        {
          "id": 5,
          "title": "exceptional",
          "count": 230,
          "percent": 13.4
        },
        {
          "id": 1,
          "title": "skip",
          "count": 131,
          "percent": 7.63
        }
      ],
      "ratings_count": 1694,
      "reviews_text_count": 17,
      "added": 6934,
      "added_by_status": {
        "yet": 458,
        "owned": 3939,
        "beaten": 1659,
        "toplay": 253,
        "dropped": 537,
        "playing": 88
      },
      "metacritic": 71,
      "suggestions_count": 497,
      "updated": "2025-07-30T08:56:43",
      "id": 8146,
      "score": "59.38251",
      "clip": null,
      "tags": [
        {
          "id": 31,
          "name": "Singleplayer",
          "slug": "singleplayer",
          "language": "eng",
          "games_count": 243828,
          "image_background": "https://media.rawg.io/media/games/f46/f466571d536f2e3ea9e815ad17177501.jpg"
        },
        {
          "id": 42396,
          "name": "Для одного игрока",
          "slug": "dlia-odnogo-igroka",
          "language": "rus",
          "games_count": 65063,
          "image_background": "https://media.rawg.io/media/games/511/5118aff5091cb3efec399c808f8c598f.jpg"
        },
        {
          "id": 42417,
          "name": "Экшен",
          "slug": "ekshen",
          "language": "rus",
          "games_count": 47885,
          "image_background": "https://media.rawg.io/media/games/7fa/7fa0b586293c5861ee32490e953a4996.jpg"
        },
        {
          "id": 42392,
          "name": "Приключение",
          "slug": "prikliuchenie",
          "language": "rus",
          "games_count": 46267,
          "image_background": "https://media.rawg.io/media/games/26d/26d4437715bee60138dab4a7c8c59c92.jpg"
        },
        {
          "id": 7,
          "name": "Multiplayer",
          "slug": "multiplayer",
          "language": "eng",
          "games_count": 41388,
          "image_background": "https://media.rawg.io/media/games/34b/34b1f1850a1c06fd971bc6ab3ac0ce0e.jpg"
        },
        {
          "id": 13,
          "name": "Atmospheric",
          "slug": "atmospheric",
          "language": "eng",
          "games_count": 37992,
          "image_background": "https://media.rawg.io/media/games/737/737ea5662211d2e0bbd6f5989189e4f1.jpg"
        },
        {
          "id": 42425,
          "name": "Для нескольких игроков",
          "slug": "dlia-neskolkikh-igrokov",
          "language": "rus",
          "games_count": 12143,
          "image_background": "https://media.rawg.io/media/games/ec3/ec3a7db7b8ab5a71aad622fe7c62632f.jpg"
        },
        {
          "id": 42400,
          "name": "Атмосфера",
          "slug": "atmosfera",
          "language": "rus",
          "games_count": 6083,
          "image_background": "https://media.rawg.io/media/games/737/737ea5662211d2e0bbd6f5989189e4f1.jpg"
        },
        {
          "id": 42401,
          "name": "Отличный саундтрек",
          "slug": "otlichnyi-saundtrek",
          "language": "rus",
          "games_count": 4658,
          "image_background": "https://media.rawg.io/media/games/20a/20aa03a10cda45239fe22d035c0ebe64.jpg"
        },
        {
          "id": 42,
          "name": "Great Soundtrack",
          "slug": "great-soundtrack",
          "language": "eng",
          "games_count": 3434,
          "image_background": "https://media.rawg.io/media/games/7cf/7cfc9220b401b7a300e409e539c9afd5.jpg"
        },
        {
          "id": 42394,
          "name": "Глубокий сюжет",
          "slug": "glubokii-siuzhet",
          "language": "rus",
          "games_count": 16612,
          "image_background": "https://media.rawg.io/media/games/6c5/6c55e22185876626881b76c11922b073.jpg"
        },
        {
          "id": 24,
          "name": "RPG",
          "slug": "rpg",
          "language": "eng",
          "games_count": 25171,
          "image_background": "https://media.rawg.io/media/games/b45/b45575f34285f2c4479c9a5f719d972e.jpg"
        },
        {
          "id": 18,
          "name": "Co-op",
          "slug": "co-op",
          "language": "eng",
          "games_count": 13658,
          "image_background": "https://media.rawg.io/media/games/15c/15c95a4915f88a3e89c821526afe05fc.jpg"
        },
        {
          "id": 42412,
          "name": "Ролевая игра",
          "slug": "rolevaia-igra",
          "language": "rus",
          "games_count": 21574,
          "image_background": "https://media.rawg.io/media/games/26d/26d4437715bee60138dab4a7c8c59c92.jpg"
        },
        {
          "id": 118,
          "name": "Story Rich",
          "slug": "story-rich",
          "language": "eng",
          "games_count": 25746,
          "image_background": "https://media.rawg.io/media/games/26d/26d4437715bee60138dab4a7c8c59c92.jpg"
        },
        {
          "id": 42442,
          "name": "Открытый мир",
          "slug": "otkrytyi-mir",
          "language": "rus",
          "games_count": 7003,
          "image_background": "https://media.rawg.io/media/games/6cd/6cd653e0aaef5ff8bbd295bf4bcb12eb.jpg"
        },
        {
          "id": 36,
          "name": "Open World",
          "slug": "open-world",
          "language": "eng",
          "games_count": 8816,
          "image_background": "https://media.rawg.io/media/games/e6d/e6de699bd788497f4b52e2f41f9698f2.jpg"
        },
        {
          "id": 411,
          "name": "cooperative",
          "slug": "cooperative",
          "language": "eng",
          "games_count": 6178,
          "image_background": "https://media.rawg.io/media/games/ec3/ec3a7db7b8ab5a71aad622fe7c62632f.jpg"
        },
        {
          "id": 42441,
          "name": "От третьего лица",
          "slug": "ot-tretego-litsa",
          "language": "rus",
          "games_count": 9458,
          "image_background": "https://media.rawg.io/media/games/b49/b4912b5dbfc7ed8927b65f05b8507f6c.jpg"
        },
        {
          "id": 149,
          "name": "Third Person",
          "slug": "third-person",
          "language": "eng",
          "games_count": 13934,
          "image_background": "https://media.rawg.io/media/games/562/562553814dd54e001a541e4ee83a591c.jpg"
        },
        {
          "id": 40845,
          "name": "Partial Controller Support",
          "slug": "partial-controller-support",
          "language": "eng",
          "games_count": 13444,
          "image_background": "https://media.rawg.io/media/games/2ad/2ad87a4a69b1104f02435c14c5196095.jpg"
        },
        {
          "id": 42413,
          "name": "Симулятор",
          "slug": "simuliator",
          "language": "rus",
          "games_count": 24208,
          "image_background": "https://media.rawg.io/media/games/e40/e40cc9d1957b0a0ed7e389834457b524.jpg"
        },
        {
          "id": 9,
          "name": "Online Co-Op",
          "slug": "online-co-op",
          "language": "eng",
          "games_count": 7121,
          "image_background": "https://media.rawg.io/media/games/21c/21cc15d233117c6809ec86870559e105.jpg"
        },
        {
          "id": 37,
          "name": "Sandbox",
          "slug": "sandbox",
          "language": "eng",
          "games_count": 8088,
          "image_background": "https://media.rawg.io/media/games/849/849414b978db37d4563ff9e4b0d3a787.jpg"
        },
        {
          "id": 42444,
          "name": "Песочница",
          "slug": "pesochnitsa",
          "language": "rus",
          "games_count": 5317,
          "image_background": "https://media.rawg.io/media/games/58a/58ac7f6569259dcc0b60b921869b19fc.jpg"
        },
        {
          "id": 42433,
          "name": "Совместная игра по сети",
          "slug": "sovmestnaia-igra-po-seti",
          "language": "rus",
          "games_count": 1226,
          "image_background": "https://media.rawg.io/media/games/e74/e74458058b35e01c1ae3feeb39a3f724.jpg"
        },
        {
          "id": 15,
          "name": "Stealth",
          "slug": "stealth",
          "language": "eng",
          "games_count": 6913,
          "image_background": "https://media.rawg.io/media/games/7ac/7aca7ccf0e70cd0974cb899ab9e5158e.jpg"
        },
        {
          "id": 42439,
          "name": "Стелс",
          "slug": "stels",
          "language": "rus",
          "games_count": 2771,
          "image_background": "https://media.rawg.io/media/games/1bd/1bd2657b81eb0c99338120ad444b24ff.jpg"
        },
        {
          "id": 97,
          "name": "Action RPG",
          "slug": "action-rpg",
          "language": "eng",
          "games_count": 8280,
          "image_background": "https://media.rawg.io/media/games/bc0/bc06a29ceac58652b684deefe7d56099.jpg"
        },
        {
          "id": 42436,
          "name": "Тактика",
          "slug": "taktika",
          "language": "rus",
          "games_count": 4854,
          "image_background": "https://media.rawg.io/media/games/737/737ea5662211d2e0bbd6f5989189e4f1.jpg"
        },
        {
          "id": 42489,
          "name": "Ролевой экшен",
          "slug": "rolevoi-ekshen",
          "language": "rus",
          "games_count": 5271,
          "image_background": "https://media.rawg.io/media/games/d1f/d1f872a48286b6b751670817d5c1e1be.jpg"
        },
        {
          "id": 80,
          "name": "Tactical",
          "slug": "tactical",
          "language": "eng",
          "games_count": 6227,
          "image_background": "https://media.rawg.io/media/games/9bf/9bfac18ff678f41a4674250fa0e04a52.jpg"
        },
        {
          "id": 89,
          "name": "Historical",
          "slug": "historical",
          "language": "eng",
          "games_count": 3791,
          "image_background": "https://media.rawg.io/media/games/849/849414b978db37d4563ff9e4b0d3a787.jpg"
        },
        {
          "id": 42403,
          "name": "История",
          "slug": "istoriia",
          "language": "rus",
          "games_count": 940,
          "image_background": "https://media.rawg.io/media/games/bff/bff7d82316cddea9541261a045ba008a.jpg"
        },
        {
          "id": 42643,
          "name": "Паркур",
          "slug": "parkur-2",
          "language": "rus",
          "games_count": 1637,
          "image_background": "https://media.rawg.io/media/games/bd7/bd7cfccfececba1ec2b97a120a40373f.jpg"
        },
        {
          "id": 188,
          "name": "Parkour",
          "slug": "parkour",
          "language": "eng",
          "games_count": 3956,
          "image_background": "https://media.rawg.io/media/games/9f1/9f189c639f70f91166df415811a8b525.jpg"
        },
        {
          "id": 278,
          "name": "Assassin",
          "slug": "assassin",
          "language": "eng",
          "games_count": 938,
          "image_background": "https://media.rawg.io/media/games/c35/c354856af9151dc63844be4f9843d2c2.jpg"
        },
        {
          "id": 42440,
          "name": "Ассассины",
          "slug": "assassiny",
          "language": "rus",
          "games_count": 456,
          "image_background": "https://media.rawg.io/media/games/4e6/4e6e8e7f50c237d76f38f3c885dae3d2.jpg"
        }
      ],
      "esrb_rating": {
        "id": 4,
        "name": "Mature",
        "slug": "mature",
        "name_en": "Mature",
        "name_ru": "С 17 лет"
      },
      "user_game": null,
      "reviews_count": 1716,
      "saturated_color": "0f0f0f",
      "dominant_color": "0f0f0f",
      "short_screenshots": [
        {
          "id": -1,
          "image": "https://media.rawg.io/media/games/59f/59fc1c5de1d29cb9234741c97d250150.jpg"
        },
        {
          "id": 56623,
          "image": "https://media.rawg.io/media/screenshots/bd3/bd3302a08d8c9ffbb73ffd4cd40714aa.jpg"
        },
        {
          "id": 56626,
          "image": "https://media.rawg.io/media/screenshots/bd8/bd84c249c0629a21eb100e9f85741af4.jpg"
        },
        {
          "id": 56629,
          "image": "https://media.rawg.io/media/screenshots/896/896a031eff2e03dc483e2c72c9709457.jpg"
        },
        {
          "id": 56637,
          "image": "https://media.rawg.io/media/screenshots/8b1/8b189e10ce9c9276d052ee5cb04ff4b8.jpg"
        },
        {
          "id": 56639,
          "image": "https://media.rawg.io/media/screenshots/5e0/5e076dd9935da9e829a2508ee1e64d18.jpg"
        },
        {
          "id": 56644,
          "image": "https://media.rawg.io/media/screenshots/192/192e78d96471392a05fef86dbc13a7d1.jpg"
        }
      ],
      "parent_platforms": [
        {
          "platform": {
            "id": 1,
            "name": "PC",
            "slug": "pc"
          }
        },
        {
          "platform": {
            "id": 2,
            "name": "PlayStation",
            "slug": "playstation"
          }
        },
        {
          "platform": {
            "id": 3,
            "name": "Xbox",
            "slug": "xbox"
          }
        }
      ],
      "genres": [
        {
          "id": 4,
          "name": "Action",
          "slug": "action"
        }
      ]
    },
    {
      "slug": "assassins-creed-syndicate-2",
      "name": "Assassin's Creed Syndicate",
      "playtime": 22,
      "platforms": [
        {
          "platform": {
            "id": 4,
            "name": "PC",
            "slug": "pc"
          }
        },
        {
          "platform": {
            "id": 1,
            "name": "Xbox One",
            "slug": "xbox-one"
          }
        },
        {
          "platform": {
            "id": 18,
            "name": "PlayStation 4",
            "slug": "playstation4"
          }
        }
      ],
      "stores": [
        {
          "store": {
            "id": 1,
            "name": "Steam",
            "slug": "steam"
          }
        },
        {
          "store": {
            "id": 3,
            "name": "PlayStation Store",
            "slug": "playstation-store"
          }
        },
        {
          "store": {
            "id": 2,
            "name": "Xbox Store",
            "slug": "xbox-store"
          }
        },
        {
          "store": {
            "id": 11,
            "name": "Epic Games",
            "slug": "epic-games"
          }
        }
      ],
      "released": "2015-10-23",
      "tba": false,
      "background_image": "https://media.rawg.io/media/games/9f1/9f189c639f70f91166df415811a8b525.jpg",
      "rating": 3.66,
      "rating_top": 4,
      "ratings": [
        {
          "id": 4,
          "title": "recommended",
          "count": 790,
          "percent": 51.94
        },
        {
          "id": 3,
          "title": "meh",
          "count": 444,
          "percent": 29.19
        },
        {
          "id": 5,
          "title": "exceptional",
          "count": 198,
          "percent": 13.02
        },
        {
          "id": 1,
          "title": "skip",
          "count": 89,
          "percent": 5.85
        }
      ],
      "ratings_count": 1502,
      "reviews_text_count": 12,
      "added": 5951,
      "added_by_status": {
        "yet": 452,
        "owned": 3268,
        "beaten": 1406,
        "toplay": 269,
        "dropped": 470,
        "playing": 86
      },
      "metacritic": 74,
      "suggestions_count": 685,
      "updated": "2025-07-30T08:56:28",
      "id": 42895,
      "score": "58.797012",
      "clip": null,
      "tags": [
        {
          "id": 31,
          "name": "Singleplayer",
          "slug": "singleplayer",
          "language": "eng",
          "games_count": 243828,
          "image_background": "https://media.rawg.io/media/games/f46/f466571d536f2e3ea9e815ad17177501.jpg"
        },
        {
          "id": 42396,
          "name": "Для одного игрока",
          "slug": "dlia-odnogo-igroka",
          "language": "rus",
          "games_count": 65063,
          "image_background": "https://media.rawg.io/media/games/511/5118aff5091cb3efec399c808f8c598f.jpg"
        },
        {
          "id": 42417,
          "name": "Экшен",
          "slug": "ekshen",
          "language": "rus",
          "games_count": 47885,
          "image_background": "https://media.rawg.io/media/games/7fa/7fa0b586293c5861ee32490e953a4996.jpg"
        },
        {
          "id": 42392,
          "name": "Приключение",
          "slug": "prikliuchenie",
          "language": "rus",
          "games_count": 46267,
          "image_background": "https://media.rawg.io/media/games/26d/26d4437715bee60138dab4a7c8c59c92.jpg"
        },
        {
          "id": 7,
          "name": "Multiplayer",
          "slug": "multiplayer",
          "language": "eng",
          "games_count": 41388,
          "image_background": "https://media.rawg.io/media/games/34b/34b1f1850a1c06fd971bc6ab3ac0ce0e.jpg"
        },
        {
          "id": 13,
          "name": "Atmospheric",
          "slug": "atmospheric",
          "language": "eng",
          "games_count": 37992,
          "image_background": "https://media.rawg.io/media/games/737/737ea5662211d2e0bbd6f5989189e4f1.jpg"
        },
        {
          "id": 42425,
          "name": "Для нескольких игроков",
          "slug": "dlia-neskolkikh-igrokov",
          "language": "rus",
          "games_count": 12143,
          "image_background": "https://media.rawg.io/media/games/ec3/ec3a7db7b8ab5a71aad622fe7c62632f.jpg"
        },
        {
          "id": 42400,
          "name": "Атмосфера",
          "slug": "atmosfera",
          "language": "rus",
          "games_count": 6083,
          "image_background": "https://media.rawg.io/media/games/737/737ea5662211d2e0bbd6f5989189e4f1.jpg"
        },
        {
          "id": 42401,
          "name": "Отличный саундтрек",
          "slug": "otlichnyi-saundtrek",
          "language": "rus",
          "games_count": 4658,
          "image_background": "https://media.rawg.io/media/games/20a/20aa03a10cda45239fe22d035c0ebe64.jpg"
        },
        {
          "id": 42,
          "name": "Great Soundtrack",
          "slug": "great-soundtrack",
          "language": "eng",
          "games_count": 3434,
          "image_background": "https://media.rawg.io/media/games/7cf/7cfc9220b401b7a300e409e539c9afd5.jpg"
        },
        {
          "id": 42394,
          "name": "Глубокий сюжет",
          "slug": "glubokii-siuzhet",
          "language": "rus",
          "games_count": 16612,
          "image_background": "https://media.rawg.io/media/games/6c5/6c55e22185876626881b76c11922b073.jpg"
        },
        {
          "id": 18,
          "name": "Co-op",
          "slug": "co-op",
          "language": "eng",
          "games_count": 13658,
          "image_background": "https://media.rawg.io/media/games/15c/15c95a4915f88a3e89c821526afe05fc.jpg"
        },
        {
          "id": 118,
          "name": "Story Rich",
          "slug": "story-rich",
          "language": "eng",
          "games_count": 25746,
          "image_background": "https://media.rawg.io/media/games/26d/26d4437715bee60138dab4a7c8c59c92.jpg"
        },
        {
          "id": 42442,
          "name": "Открытый мир",
          "slug": "otkrytyi-mir",
          "language": "rus",
          "games_count": 7003,
          "image_background": "https://media.rawg.io/media/games/6cd/6cd653e0aaef5ff8bbd295bf4bcb12eb.jpg"
        },
        {
          "id": 36,
          "name": "Open World",
          "slug": "open-world",
          "language": "eng",
          "games_count": 8816,
          "image_background": "https://media.rawg.io/media/games/e6d/e6de699bd788497f4b52e2f41f9698f2.jpg"
        },
        {
          "id": 42421,
          "name": "Стратегия",
          "slug": "strategiia",
          "language": "rus",
          "games_count": 23260,
          "image_background": "https://media.rawg.io/media/games/c22/c22d804ac753c72f2617b3708a625dec.jpg"
        },
        {
          "id": 411,
          "name": "cooperative",
          "slug": "cooperative",
          "language": "eng",
          "games_count": 6178,
          "image_background": "https://media.rawg.io/media/games/ec3/ec3a7db7b8ab5a71aad622fe7c62632f.jpg"
        },
        {
          "id": 42441,
          "name": "От третьего лица",
          "slug": "ot-tretego-litsa",
          "language": "rus",
          "games_count": 9458,
          "image_background": "https://media.rawg.io/media/games/b49/b4912b5dbfc7ed8927b65f05b8507f6c.jpg"
        },
        {
          "id": 149,
          "name": "Third Person",
          "slug": "third-person",
          "language": "eng",
          "games_count": 13934,
          "image_background": "https://media.rawg.io/media/games/562/562553814dd54e001a541e4ee83a591c.jpg"
        },
        {
          "id": 40845,
          "name": "Partial Controller Support",
          "slug": "partial-controller-support",
          "language": "eng",
          "games_count": 13444,
          "image_background": "https://media.rawg.io/media/games/2ad/2ad87a4a69b1104f02435c14c5196095.jpg"
        },
        {
          "id": 42482,
          "name": "Смешная",
          "slug": "smeshnaia",
          "language": "rus",
          "games_count": 11815,
          "image_background": "https://media.rawg.io/media/games/960/960b601d9541cec776c5fa42a00bf6c4.jpg"
        },
        {
          "id": 4,
          "name": "Funny",
          "slug": "funny",
          "language": "eng",
          "games_count": 27804,
          "image_background": "https://media.rawg.io/media/screenshots/8f0/8f0b94922ad5e59968852649697b2643.jpg"
        },
        {
          "id": 42491,
          "name": "Мясо",
          "slug": "miaso",
          "language": "rus",
          "games_count": 4962,
          "image_background": "https://media.rawg.io/media/games/c6b/c6bd26767c1053fef2b10bb852943559.jpg"
        },
        {
          "id": 26,
          "name": "Gore",
          "slug": "gore",
          "language": "eng",
          "games_count": 6372,
          "image_background": "https://media.rawg.io/media/games/858/858c016de0cf7bc21a57dcc698a04a0c.jpg"
        },
        {
          "id": 189,
          "name": "Female Protagonist",
          "slug": "female-protagonist",
          "language": "eng",
          "games_count": 14719,
          "image_background": "https://media.rawg.io/media/games/e3d/e3ddc524c6292a435d01d97cc5f42ea7.jpg"
        },
        {
          "id": 42404,
          "name": "Женщина-протагонист",
          "slug": "zhenshchina-protagonist",
          "language": "rus",
          "games_count": 2413,
          "image_background": "https://media.rawg.io/media/games/424/424facd40f4eb1f2794fe4b4bb28a277.jpg"
        },
        {
          "id": 15,
          "name": "Stealth",
          "slug": "stealth",
          "language": "eng",
          "games_count": 6913,
          "image_background": "https://media.rawg.io/media/games/7ac/7aca7ccf0e70cd0974cb899ab9e5158e.jpg"
        },
        {
          "id": 42439,
          "name": "Стелс",
          "slug": "stels",
          "language": "rus",
          "games_count": 2771,
          "image_background": "https://media.rawg.io/media/games/1bd/1bd2657b81eb0c99338120ad444b24ff.jpg"
        },
        {
          "id": 89,
          "name": "Historical",
          "slug": "historical",
          "language": "eng",
          "games_count": 3791,
          "image_background": "https://media.rawg.io/media/games/849/849414b978db37d4563ff9e4b0d3a787.jpg"
        },
        {
          "id": 42403,
          "name": "История",
          "slug": "istoriia",
          "language": "rus",
          "games_count": 940,
          "image_background": "https://media.rawg.io/media/games/bff/bff7d82316cddea9541261a045ba008a.jpg"
        },
        {
          "id": 42643,
          "name": "Паркур",
          "slug": "parkur-2",
          "language": "rus",
          "games_count": 1637,
          "image_background": "https://media.rawg.io/media/games/bd7/bd7cfccfececba1ec2b97a120a40373f.jpg"
        },
        {
          "id": 188,
          "name": "Parkour",
          "slug": "parkour",
          "language": "eng",
          "games_count": 3956,
          "image_background": "https://media.rawg.io/media/games/9f1/9f189c639f70f91166df415811a8b525.jpg"
        },
        {
          "id": 154,
          "name": "Steampunk",
          "slug": "steampunk",
          "language": "eng",
          "games_count": 1317,
          "image_background": "https://media.rawg.io/media/games/3c3/3c363e31f4add887affadc82c641de72.jpg"
        },
        {
          "id": 42629,
          "name": "Стимпанк",
          "slug": "stimpank",
          "language": "rus",
          "games_count": 601,
          "image_background": "https://media.rawg.io/media/games/f89/f899f0bdeb6bcd7419d9b2281a693ad8.jpg"
        },
        {
          "id": 278,
          "name": "Assassin",
          "slug": "assassin",
          "language": "eng",
          "games_count": 938,
          "image_background": "https://media.rawg.io/media/games/c35/c354856af9151dc63844be4f9843d2c2.jpg"
        },
        {
          "id": 42440,
          "name": "Ассассины",
          "slug": "assassiny",
          "language": "rus",
          "games_count": 456,
          "image_background": "https://media.rawg.io/media/games/4e6/4e6e8e7f50c237d76f38f3c885dae3d2.jpg"
        },
        {
          "id": 178,
          "name": "Illuminati",
          "slug": "illuminati",
          "language": "eng",
          "games_count": 367,
          "image_background": "https://media.rawg.io/media/screenshots/ad4/ad445a12ee46543d4d117f3893041ebf.jpg"
        },
        {
          "id": 42448,
          "name": "Иллюминаты",
          "slug": "illiuminaty",
          "language": "rus",
          "games_count": 311,
          "image_background": "https://media.rawg.io/media/games/050/050946c00aa9c48111af5e3c2469b209.jpg"
        }
      ],
      "esrb_rating": {
        "id": 4,
        "name": "Mature",
        "slug": "mature",
        "name_en": "Mature",
        "name_ru": "С 17 лет"
      },
      "user_game": null,
      "reviews_count": 1521,
      "saturated_color": "0f0f0f",
      "dominant_color": "0f0f0f",
      "short_screenshots": [
        {
          "id": -1,
          "image": "https://media.rawg.io/media/games/9f1/9f189c639f70f91166df415811a8b525.jpg"
        },
        {
          "id": 621056,
          "image": "https://media.rawg.io/media/screenshots/578/57836521fc9d7f0a5b743c5d3aabbac2.jpg"
        },
        {
          "id": 621057,
          "image": "https://media.rawg.io/media/screenshots/240/2402b360498dc27ac594774a968e028f.jpg"
        },
        {
          "id": 621058,
          "image": "https://media.rawg.io/media/screenshots/cdd/cdda74e097646eda1ae8c87c46942530.jpg"
        },
        {
          "id": 621059,
          "image": "https://media.rawg.io/media/screenshots/6cb/6cb68bc408c6c0e4e0f1b2782ad03e86.jpg"
        },
        {
          "id": 621060,
          "image": "https://media.rawg.io/media/screenshots/b90/b909dc646a468a33b1a5e9d97fb2b979.jpg"
        },
        {
          "id": 621061,
          "image": "https://media.rawg.io/media/screenshots/82f/82fe6e74ec918f4c7c0df69cd991a04b.jpg"
        }
      ],
      "parent_platforms": [
        {
          "platform": {
            "id": 1,
            "name": "PC",
            "slug": "pc"
          }
        },
        {
          "platform": {
            "id": 2,
            "name": "PlayStation",
            "slug": "playstation"
          }
        },
        {
          "platform": {
            "id": 3,
            "name": "Xbox",
            "slug": "xbox"
          }
        }
      ],
      "genres": [
        {
          "id": 4,
          "name": "Action",
          "slug": "action"
        }
      ]
    },
    {
      "slug": "assassins-creed-odyssey",
      "name": "Assassin's Creed Odyssey",
      "playtime": 31,
      "platforms": [
        {
          "platform": {
            "id": 4,
            "name": "PC",
            "slug": "pc"
          }
        },
        {
          "platform": {
            "id": 1,
            "name": "Xbox One",
            "slug": "xbox-one"
          }
        },
        {
          "platform": {
            "id": 18,
            "name": "PlayStation 4",
            "slug": "playstation4"
          }
        },
        {
          "platform": {
            "id": 7,
            "name": "Nintendo Switch",
            "slug": "nintendo-switch"
          }
        }
      ],
      "stores": [
        {
          "store": {
            "id": 1,
            "name": "Steam",
            "slug": "steam"
          }
        },
        {
          "store": {
            "id": 3,
            "name": "PlayStation Store",
            "slug": "playstation-store"
          }
        },
        {
          "store": {
            "id": 2,
            "name": "Xbox Store",
            "slug": "xbox-store"
          }
        },
        {
          "store": {
            "id": 6,
            "name": "Nintendo Store",
            "slug": "nintendo"
          }
        },
        {
          "store": {
            "id": 11,
            "name": "Epic Games",
            "slug": "epic-games"
          }
        }
      ],
      "released": "2018-10-05",
      "tba": false,
      "background_image": "https://media.rawg.io/media/games/c6b/c6bd26767c1053fef2b10bb852943559.jpg",
      "rating": 3.98,
      "rating_top": 4,
      "ratings": [
        {
          "id": 4,
          "title": "recommended",
          "count": 1015,
          "percent": 48.17
        },
        {
          "id": 5,
          "title": "exceptional",
          "count": 637,
          "percent": 30.23
        },
        {
          "id": 3,
          "title": "meh",
          "count": 344,
          "percent": 16.33
        },
        {
          "id": 1,
          "title": "skip",
          "count": 111,
          "percent": 5.27
        }
      ],
      "ratings_count": 2073,
      "reviews_text_count": 24,
      "added": 8133,
      "added_by_status": {
        "yet": 539,
        "owned": 4459,
        "beaten": 1477,
        "toplay": 709,
        "dropped": 575,
        "playing": 374
      },
      "metacritic": 85,
      "suggestions_count": 646,
      "updated": "2025-07-28T22:31:26",
      "id": 58616,
      "score": "58.797012",
      "clip": null,
      "tags": [
        {
          "id": 31,
          "name": "Singleplayer",
          "slug": "singleplayer",
          "language": "eng",
          "games_count": 243828,
          "image_background": "https://media.rawg.io/media/games/f46/f466571d536f2e3ea9e815ad17177501.jpg"
        },
        {
          "id": 42396,
          "name": "Для одного игрока",
          "slug": "dlia-odnogo-igroka",
          "language": "rus",
          "games_count": 65063,
          "image_background": "https://media.rawg.io/media/games/511/5118aff5091cb3efec399c808f8c598f.jpg"
        },
        {
          "id": 42417,
          "name": "Экшен",
          "slug": "ekshen",
          "language": "rus",
          "games_count": 47885,
          "image_background": "https://media.rawg.io/media/games/7fa/7fa0b586293c5861ee32490e953a4996.jpg"
        },
        {
          "id": 42392,
          "name": "Приключение",
          "slug": "prikliuchenie",
          "language": "rus",
          "games_count": 46267,
          "image_background": "https://media.rawg.io/media/games/26d/26d4437715bee60138dab4a7c8c59c92.jpg"
        },
        {
          "id": 13,
          "name": "Atmospheric",
          "slug": "atmospheric",
          "language": "eng",
          "games_count": 37992,
          "image_background": "https://media.rawg.io/media/games/737/737ea5662211d2e0bbd6f5989189e4f1.jpg"
        },
        {
          "id": 42425,
          "name": "Для нескольких игроков",
          "slug": "dlia-neskolkikh-igrokov",
          "language": "rus",
          "games_count": 12143,
          "image_background": "https://media.rawg.io/media/games/ec3/ec3a7db7b8ab5a71aad622fe7c62632f.jpg"
        },
        {
          "id": 42400,
          "name": "Атмосфера",
          "slug": "atmosfera",
          "language": "rus",
          "games_count": 6083,
          "image_background": "https://media.rawg.io/media/games/737/737ea5662211d2e0bbd6f5989189e4f1.jpg"
        },
        {
          "id": 7808,
          "name": "steam-trading-cards",
          "slug": "steam-trading-cards",
          "language": "eng",
          "games_count": 7568,
          "image_background": "https://media.rawg.io/media/games/d0f/d0f91fe1d92332147e5db74e207cfc7a.jpg"
        },
        {
          "id": 42401,
          "name": "Отличный саундтрек",
          "slug": "otlichnyi-saundtrek",
          "language": "rus",
          "games_count": 4658,
          "image_background": "https://media.rawg.io/media/games/20a/20aa03a10cda45239fe22d035c0ebe64.jpg"
        },
        {
          "id": 42394,
          "name": "Глубокий сюжет",
          "slug": "glubokii-siuzhet",
          "language": "rus",
          "games_count": 16612,
          "image_background": "https://media.rawg.io/media/games/6c5/6c55e22185876626881b76c11922b073.jpg"
        },
        {
          "id": 24,
          "name": "RPG",
          "slug": "rpg",
          "language": "eng",
          "games_count": 25171,
          "image_background": "https://media.rawg.io/media/games/b45/b45575f34285f2c4479c9a5f719d972e.jpg"
        },
        {
          "id": 42412,
          "name": "Ролевая игра",
          "slug": "rolevaia-igra",
          "language": "rus",
          "games_count": 21574,
          "image_background": "https://media.rawg.io/media/games/26d/26d4437715bee60138dab4a7c8c59c92.jpg"
        },
        {
          "id": 118,
          "name": "Story Rich",
          "slug": "story-rich",
          "language": "eng",
          "games_count": 25746,
          "image_background": "https://media.rawg.io/media/games/26d/26d4437715bee60138dab4a7c8c59c92.jpg"
        },
        {
          "id": 42442,
          "name": "Открытый мир",
          "slug": "otkrytyi-mir",
          "language": "rus",
          "games_count": 7003,
          "image_background": "https://media.rawg.io/media/games/6cd/6cd653e0aaef5ff8bbd295bf4bcb12eb.jpg"
        },
        {
          "id": 36,
          "name": "Open World",
          "slug": "open-world",
          "language": "eng",
          "games_count": 8816,
          "image_background": "https://media.rawg.io/media/games/e6d/e6de699bd788497f4b52e2f41f9698f2.jpg"
        },
        {
          "id": 42441,
          "name": "От третьего лица",
          "slug": "ot-tretego-litsa",
          "language": "rus",
          "games_count": 9458,
          "image_background": "https://media.rawg.io/media/games/b49/b4912b5dbfc7ed8927b65f05b8507f6c.jpg"
        },
        {
          "id": 149,
          "name": "Third Person",
          "slug": "third-person",
          "language": "eng",
          "games_count": 13934,
          "image_background": "https://media.rawg.io/media/games/562/562553814dd54e001a541e4ee83a591c.jpg"
        },
        {
          "id": 40845,
          "name": "Partial Controller Support",
          "slug": "partial-controller-support",
          "language": "eng",
          "games_count": 13444,
          "image_background": "https://media.rawg.io/media/games/2ad/2ad87a4a69b1104f02435c14c5196095.jpg"
        },
        {
          "id": 42491,
          "name": "Мясо",
          "slug": "miaso",
          "language": "rus",
          "games_count": 4962,
          "image_background": "https://media.rawg.io/media/games/c6b/c6bd26767c1053fef2b10bb852943559.jpg"
        },
        {
          "id": 189,
          "name": "Female Protagonist",
          "slug": "female-protagonist",
          "language": "eng",
          "games_count": 14719,
          "image_background": "https://media.rawg.io/media/games/e3d/e3ddc524c6292a435d01d97cc5f42ea7.jpg"
        },
        {
          "id": 42404,
          "name": "Женщина-протагонист",
          "slug": "zhenshchina-protagonist",
          "language": "rus",
          "games_count": 2413,
          "image_background": "https://media.rawg.io/media/games/424/424facd40f4eb1f2794fe4b4bb28a277.jpg"
        },
        {
          "id": 42402,
          "name": "Насилие",
          "slug": "nasilie",
          "language": "rus",
          "games_count": 6484,
          "image_background": "https://media.rawg.io/media/games/5bf/5bf88a28de96321c86561a65ee48e6c2.jpg"
        },
        {
          "id": 15,
          "name": "Stealth",
          "slug": "stealth",
          "language": "eng",
          "games_count": 6913,
          "image_background": "https://media.rawg.io/media/games/7ac/7aca7ccf0e70cd0974cb899ab9e5158e.jpg"
        },
        {
          "id": 42439,
          "name": "Стелс",
          "slug": "stels",
          "language": "rus",
          "games_count": 2771,
          "image_background": "https://media.rawg.io/media/games/1bd/1bd2657b81eb0c99338120ad444b24ff.jpg"
        },
        {
          "id": 42406,
          "name": "Нагота",
          "slug": "nagota",
          "language": "rus",
          "games_count": 7775,
          "image_background": "https://media.rawg.io/media/games/260/26023c855f1769a93411d6a7ea084632.jpeg"
        },
        {
          "id": 42390,
          "name": "Решения с последствиями",
          "slug": "resheniia-s-posledstviiami",
          "language": "rus",
          "games_count": 7775,
          "image_background": "https://media.rawg.io/media/games/dc0/dc0926d3f84ffbcc00968fe8a6f0aed3.jpg"
        },
        {
          "id": 40837,
          "name": "In-App Purchases",
          "slug": "in-app-purchases",
          "language": "eng",
          "games_count": 3217,
          "image_background": "https://media.rawg.io/media/games/742/7424c1f7d0a8da9ae29cd866f985698b.jpg"
        },
        {
          "id": 40833,
          "name": "Captions available",
          "slug": "captions-available",
          "language": "eng",
          "games_count": 1458,
          "image_background": "https://media.rawg.io/media/games/b8c/b8c243eaa0fbac8115e0cdccac3f91dc.jpg"
        },
        {
          "id": 42405,
          "name": "Сексуальный контент",
          "slug": "seksualnyi-kontent",
          "language": "rus",
          "games_count": 8010,
          "image_background": "https://media.rawg.io/media/games/934/9346092ae11bf7582c883869468171cc.jpg"
        },
        {
          "id": 89,
          "name": "Historical",
          "slug": "historical",
          "language": "eng",
          "games_count": 3791,
          "image_background": "https://media.rawg.io/media/games/849/849414b978db37d4563ff9e4b0d3a787.jpg"
        },
        {
          "id": 42403,
          "name": "История",
          "slug": "istoriia",
          "language": "rus",
          "games_count": 940,
          "image_background": "https://media.rawg.io/media/games/bff/bff7d82316cddea9541261a045ba008a.jpg"
        },
        {
          "id": 42643,
          "name": "Паркур",
          "slug": "parkur-2",
          "language": "rus",
          "games_count": 1637,
          "image_background": "https://media.rawg.io/media/games/bd7/bd7cfccfececba1ec2b97a120a40373f.jpg"
        },
        {
          "id": 188,
          "name": "Parkour",
          "slug": "parkour",
          "language": "eng",
          "games_count": 3956,
          "image_background": "https://media.rawg.io/media/games/9f1/9f189c639f70f91166df415811a8b525.jpg"
        },
        {
          "id": 278,
          "name": "Assassin",
          "slug": "assassin",
          "language": "eng",
          "games_count": 938,
          "image_background": "https://media.rawg.io/media/games/c35/c354856af9151dc63844be4f9843d2c2.jpg"
        },
        {
          "id": 42440,
          "name": "Ассассины",
          "slug": "assassiny",
          "language": "rus",
          "games_count": 456,
          "image_background": "https://media.rawg.io/media/games/4e6/4e6e8e7f50c237d76f38f3c885dae3d2.jpg"
        }
      ],
      "esrb_rating": {
        "id": 4,
        "name": "Mature",
        "slug": "mature",
        "name_en": "Mature",
        "name_ru": "С 17 лет"
      },
      "user_game": null,
      "reviews_count": 2107,
      "saturated_color": "0f0f0f",
      "dominant_color": "0f0f0f",
      "short_screenshots": [
        {
          "id": -1,
          "image": "https://media.rawg.io/media/games/c6b/c6bd26767c1053fef2b10bb852943559.jpg"
        },
        {
          "id": 779118,
          "image": "https://media.rawg.io/media/screenshots/412/412b1dd5c880b80d8404451d3ff44360.jpg"
        },
        {
          "id": 779119,
          "image": "https://media.rawg.io/media/screenshots/9b5/9b59a790deab688ea923e0cd7b0cadbd_sNpbwUf.jpg"
        },
        {
          "id": 779120,
          "image": "https://media.rawg.io/media/screenshots/b09/b09a53fb76ea832671599a5f287ab34a.jpg"
        },
        {
          "id": 779121,
          "image": "https://media.rawg.io/media/screenshots/2f9/2f993667330526171e4056c0a0663437.jpg"
        },
        {
          "id": 779150,
          "image": "https://media.rawg.io/media/screenshots/6d8/6d8c268dff506f890478e6a0a492858b.jpg"
        },
        {
          "id": 779151,
          "image": "https://media.rawg.io/media/screenshots/588/5883818edafd22c8a2e1a45bf6fe07b1.jpg"
        }
      ],
      "parent_platforms": [
        {
          "platform": {
            "id": 1,
            "name": "PC",
            "slug": "pc"
          }
        },
        {
          "platform": {
            "id": 2,
            "name": "PlayStation",
            "slug": "playstation"
          }
        },
        {
          "platform": {
            "id": 3,
            "name": "Xbox",
            "slug": "xbox"
          }
        },
        {
          "platform": {
            "id": 7,
            "name": "Nintendo",
            "slug": "nintendo"
          }
        }
      ],
      "genres": [
        {
          "id": 4,
          "name": "Action",
          "slug": "action"
        },
        {
          "id": 5,
          "name": "RPG",
          "slug": "role-playing-games-rpg"
        }
      ]
    },
    {
      "slug": "assassins-creed-bloodlines",
      "name": "Assassin's Creed: Bloodlines",
      "playtime": 6,
      "platforms": [
        {
          "platform": {
            "id": 17,
            "name": "PSP",
            "slug": "psp"
          }
        }
      ],
      "stores": [
        {
          "store": {
            "id": 3,
            "name": "PlayStation Store",
            "slug": "playstation-store"
          }
        }
      ],
      "released": "2009-11-17",
      "tba": false,
      "background_image": "https://media.rawg.io/media/games/071/0711f22aeaf7927ccd071b186743ca5e.jpg",
      "rating": 3.59,
      "rating_top": 4,
      "ratings": [
        {
          "id": 4,
          "title": "recommended",
          "count": 89,
          "percent": 55.28
        },
        {
          "id": 3,
          "title": "meh",
          "count": 53,
          "percent": 32.92
        },
        {
          "id": 5,
          "title": "exceptional",
          "count": 11,
          "percent": 6.83
        },
        {
          "id": 1,
          "title": "skip",
          "count": 8,
          "percent": 4.97
        }
      ],
      "ratings_count": 158,
      "reviews_text_count": 1,
      "added": 391,
      "added_by_status": {
        "yet": 26,
        "owned": 56,
        "beaten": 208,
        "toplay": 41,
        "dropped": 58,
        "playing": 2
      },
      "metacritic": 63,
      "suggestions_count": 125,
      "updated": "2025-08-02T08:45:27",
      "id": 5160,
      "score": "58.797012",
      "clip": null,
      "tags": [
        {
          "id": 37796,
          "name": "exclusive",
          "slug": "exclusive",
          "language": "eng",
          "games_count": 4491,
          "image_background": "https://media.rawg.io/media/games/364/3642d850efb217c58feab80b8affaa89.jpg"
        },
        {
          "id": 37797,
          "name": "true exclusive",
          "slug": "true-exclusive",
          "language": "eng",
          "games_count": 3980,
          "image_background": "https://media.rawg.io/media/games/276/2769b1982cd132a60c69dc5d574445fa.jpg"
        }
      ],
      "esrb_rating": {
        "id": 4,
        "name": "Mature",
        "slug": "mature",
        "name_en": "Mature",
        "name_ru": "С 17 лет"
      },
      "user_game": null,
      "reviews_count": 161,
      "saturated_color": "0f0f0f",
      "dominant_color": "0f0f0f",
      "short_screenshots": [
        {
          "id": -1,
          "image": "https://media.rawg.io/media/games/071/0711f22aeaf7927ccd071b186743ca5e.jpg"
        },
        {
          "id": 806249,
          "image": "https://media.rawg.io/media/screenshots/cbb/cbb4eb0cb4b2c36f398244ae1f4f744e.jpg"
        },
        {
          "id": 806250,
          "image": "https://media.rawg.io/media/screenshots/08e/08eef0e66c3ce6be31f3ba95216869b1.jpg"
        },
        {
          "id": 806251,
          "image": "https://media.rawg.io/media/screenshots/6a8/6a82f23fc8bbcaeeebc834a0a5e016c9.jpg"
        },
        {
          "id": 2096764,
          "image": "https://media.rawg.io/media/screenshots/101/101d3a2660a94580b066a5ae13788c4b.jpg"
        }
      ],
      "parent_platforms": [
        {
          "platform": {
            "id": 2,
            "name": "PlayStation",
            "slug": "playstation"
          }
        }
      ],
      "genres": [
        {
          "id": 3,
          "name": "Adventure",
          "slug": "adventure"
        },
        {
          "id": 4,
          "name": "Action",
          "slug": "action"
        }
      ]
    },
    {
      "slug": "assassins-creed-mirage",
      "name": "Assassin's Creed Mirage",
      "playtime": 8,
      "platforms": [
        {
          "platform": {
            "id": 4,
            "name": "PC",
            "slug": "pc"
          }
        },
        {
          "platform": {
            "id": 187,
            "name": "PlayStation 5",
            "slug": "playstation5"
          }
        },
        {
          "platform": {
            "id": 1,
            "name": "Xbox One",
            "slug": "xbox-one"
          }
        },
        {
          "platform": {
            "id": 18,
            "name": "PlayStation 4",
            "slug": "playstation4"
          }
        },
        {
          "platform": {
            "id": 186,
            "name": "Xbox Series S/X",
            "slug": "xbox-series-x"
          }
        },
        {
          "platform": {
            "id": 3,
            "name": "iOS",
            "slug": "ios"
          }
        }
      ],
      "stores": [
        {
          "store": {
            "id": 1,
            "name": "Steam",
            "slug": "steam"
          }
        },
        {
          "store": {
            "id": 3,
            "name": "PlayStation Store",
            "slug": "playstation-store"
          }
        },
        {
          "store": {
            "id": 11,
            "name": "Epic Games",
            "slug": "epic-games"
          }
        }
      ],
      "released": "2023-10-05",
      "tba": false,
      "background_image": "https://media.rawg.io/media/games/fbd/fbd0128013b7965904be571e75fb30c0.jpg",
      "rating": 3.37,
      "rating_top": 4,
      "ratings": [
        {
          "id": 4,
          "title": "recommended",
          "count": 59,
          "percent": 39.6
        },
        {
          "id": 3,
          "title": "meh",
          "count": 50,
          "percent": 33.56
        },
        {
          "id": 1,
          "title": "skip",
          "count": 21,
          "percent": 14.09
        },
        {
          "id": 5,
          "title": "exceptional",
          "count": 19,
          "percent": 12.75
        }
      ],
      "ratings_count": 142,
      "reviews_text_count": 5,
      "added": 898,
      "added_by_status": {
        "yet": 135,
        "owned": 149,
        "beaten": 145,
        "toplay": 406,
        "dropped": 42,
        "playing": 21
      },
      "metacritic": null,
      "suggestions_count": 480,
      "updated": "2025-07-30T08:55:23",
      "id": 845261,
      "score": "58.76829",
      "clip": null,
      "tags": [
        {
          "id": 31,
          "name": "Singleplayer",
          "slug": "singleplayer",
          "language": "eng",
          "games_count": 243828,
          "image_background": "https://media.rawg.io/media/games/f46/f466571d536f2e3ea9e815ad17177501.jpg"
        },
        {
          "id": 42396,
          "name": "Для одного игрока",
          "slug": "dlia-odnogo-igroka",
          "language": "rus",
          "games_count": 65063,
          "image_background": "https://media.rawg.io/media/games/511/5118aff5091cb3efec399c808f8c598f.jpg"
        },
        {
          "id": 42417,
          "name": "Экшен",
          "slug": "ekshen",
          "language": "rus",
          "games_count": 47885,
          "image_background": "https://media.rawg.io/media/games/7fa/7fa0b586293c5861ee32490e953a4996.jpg"
        },
        {
          "id": 42392,
          "name": "Приключение",
          "slug": "prikliuchenie",
          "language": "rus",
          "games_count": 46267,
          "image_background": "https://media.rawg.io/media/games/26d/26d4437715bee60138dab4a7c8c59c92.jpg"
        },
        {
          "id": 42394,
          "name": "Глубокий сюжет",
          "slug": "glubokii-siuzhet",
          "language": "rus",
          "games_count": 16612,
          "image_background": "https://media.rawg.io/media/games/6c5/6c55e22185876626881b76c11922b073.jpg"
        },
        {
          "id": 24,
          "name": "RPG",
          "slug": "rpg",
          "language": "eng",
          "games_count": 25171,
          "image_background": "https://media.rawg.io/media/games/b45/b45575f34285f2c4479c9a5f719d972e.jpg"
        },
        {
          "id": 42412,
          "name": "Ролевая игра",
          "slug": "rolevaia-igra",
          "language": "rus",
          "games_count": 21574,
          "image_background": "https://media.rawg.io/media/games/26d/26d4437715bee60138dab4a7c8c59c92.jpg"
        },
        {
          "id": 118,
          "name": "Story Rich",
          "slug": "story-rich",
          "language": "eng",
          "games_count": 25746,
          "image_background": "https://media.rawg.io/media/games/26d/26d4437715bee60138dab4a7c8c59c92.jpg"
        },
        {
          "id": 42442,
          "name": "Открытый мир",
          "slug": "otkrytyi-mir",
          "language": "rus",
          "games_count": 7003,
          "image_background": "https://media.rawg.io/media/games/6cd/6cd653e0aaef5ff8bbd295bf4bcb12eb.jpg"
        },
        {
          "id": 36,
          "name": "Open World",
          "slug": "open-world",
          "language": "eng",
          "games_count": 8816,
          "image_background": "https://media.rawg.io/media/games/e6d/e6de699bd788497f4b52e2f41f9698f2.jpg"
        },
        {
          "id": 42441,
          "name": "От третьего лица",
          "slug": "ot-tretego-litsa",
          "language": "rus",
          "games_count": 9458,
          "image_background": "https://media.rawg.io/media/games/b49/b4912b5dbfc7ed8927b65f05b8507f6c.jpg"
        },
        {
          "id": 149,
          "name": "Third Person",
          "slug": "third-person",
          "language": "eng",
          "games_count": 13934,
          "image_background": "https://media.rawg.io/media/games/562/562553814dd54e001a541e4ee83a591c.jpg"
        },
        {
          "id": 16,
          "name": "Horror",
          "slug": "horror",
          "language": "eng",
          "games_count": 47881,
          "image_background": "https://media.rawg.io/media/games/2ad/2ad87a4a69b1104f02435c14c5196095.jpg"
        },
        {
          "id": 42402,
          "name": "Насилие",
          "slug": "nasilie",
          "language": "rus",
          "games_count": 6484,
          "image_background": "https://media.rawg.io/media/games/5bf/5bf88a28de96321c86561a65ee48e6c2.jpg"
        },
        {
          "id": 34,
          "name": "Violent",
          "slug": "violent",
          "language": "eng",
          "games_count": 7522,
          "image_background": "https://media.rawg.io/media/games/67f/67f62d1f062a6164f57575e0604ee9f6.jpg"
        },
        {
          "id": 15,
          "name": "Stealth",
          "slug": "stealth",
          "language": "eng",
          "games_count": 6913,
          "image_background": "https://media.rawg.io/media/games/7ac/7aca7ccf0e70cd0974cb899ab9e5158e.jpg"
        },
        {
          "id": 42439,
          "name": "Стелс",
          "slug": "stels",
          "language": "rus",
          "games_count": 2771,
          "image_background": "https://media.rawg.io/media/games/1bd/1bd2657b81eb0c99338120ad444b24ff.jpg"
        },
        {
          "id": 69,
          "name": "Action-Adventure",
          "slug": "action-adventure",
          "language": "eng",
          "games_count": 19877,
          "image_background": "https://media.rawg.io/media/games/fc3/fc30790a3b3c738d7a271b02c1e26dc2.jpg"
        },
        {
          "id": 97,
          "name": "Action RPG",
          "slug": "action-rpg",
          "language": "eng",
          "games_count": 8280,
          "image_background": "https://media.rawg.io/media/games/bc0/bc06a29ceac58652b684deefe7d56099.jpg"
        },
        {
          "id": 42489,
          "name": "Ролевой экшен",
          "slug": "rolevoi-ekshen",
          "language": "rus",
          "games_count": 5271,
          "image_background": "https://media.rawg.io/media/games/d1f/d1f872a48286b6b751670817d5c1e1be.jpg"
        },
        {
          "id": 42490,
          "name": "Приключенческий экшен",
          "slug": "prikliuchencheskii-ekshen",
          "language": "rus",
          "games_count": 12267,
          "image_background": "https://media.rawg.io/media/games/baf/baf9905270314e07e6850cffdb51df41.jpg"
        },
        {
          "id": 89,
          "name": "Historical",
          "slug": "historical",
          "language": "eng",
          "games_count": 3791,
          "image_background": "https://media.rawg.io/media/games/849/849414b978db37d4563ff9e4b0d3a787.jpg"
        },
        {
          "id": 42643,
          "name": "Паркур",
          "slug": "parkur-2",
          "language": "rus",
          "games_count": 1637,
          "image_background": "https://media.rawg.io/media/games/bd7/bd7cfccfececba1ec2b97a120a40373f.jpg"
        },
        {
          "id": 188,
          "name": "Parkour",
          "slug": "parkour",
          "language": "eng",
          "games_count": 3956,
          "image_background": "https://media.rawg.io/media/games/9f1/9f189c639f70f91166df415811a8b525.jpg"
        },
        {
          "id": 278,
          "name": "Assassin",
          "slug": "assassin",
          "language": "eng",
          "games_count": 938,
          "image_background": "https://media.rawg.io/media/games/c35/c354856af9151dc63844be4f9843d2c2.jpg"
        },
        {
          "id": 42440,
          "name": "Ассассины",
          "slug": "assassiny",
          "language": "rus",
          "games_count": 456,
          "image_background": "https://media.rawg.io/media/games/4e6/4e6e8e7f50c237d76f38f3c885dae3d2.jpg"
        },
        {
          "id": 42410,
          "name": "LGBTQ+",
          "slug": "lgbtq-2",
          "language": "eng",
          "games_count": 2529,
          "image_background": "https://media.rawg.io/media/games/1d3/1d36765d65a9916aa519c93a8a60bd7c.jpg"
        },
        {
          "id": 66539,
          "name": "Историческая",
          "slug": "istoricheskaia",
          "language": "rus",
          "games_count": 2052,
          "image_background": "https://media.rawg.io/media/games/32e/32ec3c0a53bf3ff458211ea45d8a3bdb.jpg"
        },
        {
          "id": 59756,
          "name": "ЛГБТК+",
          "slug": "lgbtk",
          "language": "rus",
          "games_count": 2182,
          "image_background": "https://media.rawg.io/media/screenshots/1cb/1cbd9105ccd254570fb255fccf0fe9b0.jpg"
        },
        {
          "id": 56824,
          "name": "单人",
          "slug": "dan-ren",
          "language": "eng",
          "games_count": 27,
          "image_background": "https://media.rawg.io/media/screenshots/ad6/ad67b020416aad4e09cc5aacc0c2a230.jpg"
        },
        {
          "id": 59174,
          "name": "Steam 成就",
          "slug": "steam-cheng-jiu",
          "language": "eng",
          "games_count": 17,
          "image_background": "https://media.rawg.io/media/screenshots/2a5/2a5c874a0b86452362e28206836c2632.jpg"
        },
        {
          "id": 77160,
          "name": "部分支持控制器",
          "slug": "bu-fen-zhi-chi-kong-zhi-qi",
          "language": "eng",
          "games_count": 3,
          "image_background": "https://media.rawg.io/media/games/312/3121ba5c3d5fbe8b747475099f3e63b8.jpg"
        },
        {
          "id": 91986,
          "name": "支持字幕",
          "slug": "zhi-chi-zi-mu",
          "language": "eng",
          "games_count": 2,
          "image_background": "https://media.rawg.io/media/games/fbd/fbd0128013b7965904be571e75fb30c0.jpg"
        }
      ],
      "esrb_rating": null,
      "user_game": null,
      "reviews_count": 149,
      "saturated_color": "0f0f0f",
      "dominant_color": "0f0f0f",
      "short_screenshots": [
        {
          "id": -1,
          "image": "https://media.rawg.io/media/games/fbd/fbd0128013b7965904be571e75fb30c0.jpg"
        },
        {
          "id": 3548417,
          "image": "https://media.rawg.io/media/screenshots/214/2144e4a308f6df915a0ce6b9c6b0536a.jpg"
        },
        {
          "id": 3560449,
          "image": "https://media.rawg.io/media/screenshots/a8d/a8d22377af727e1404c96022b1333095.jpg"
        },
        {
          "id": 3560450,
          "image": "https://media.rawg.io/media/screenshots/935/9357652d65a3d714426a22ef44e0f0da.jpg"
        },
        {
          "id": 3560451,
          "image": "https://media.rawg.io/media/screenshots/2b0/2b0a877f30e8113f0e99b41ee3781d56.jpg"
        },
        {
          "id": 3560452,
          "image": "https://media.rawg.io/media/screenshots/6ce/6cecbbd2a905d94f8f64dd932a3e32d7.jpg"
        },
        {
          "id": 3561955,
          "image": "https://media.rawg.io/media/screenshots/59d/59d2671c96228757abe81f38749918ff.jpg"
        }
      ],
      "parent_platforms": [
        {
          "platform": {
            "id": 1,
            "name": "PC",
            "slug": "pc"
          }
        },
        {
          "platform": {
            "id": 2,
            "name": "PlayStation",
            "slug": "playstation"
          }
        },
        {
          "platform": {
            "id": 3,
            "name": "Xbox",
            "slug": "xbox"
          }
        },
        {
          "platform": {
            "id": 4,
            "name": "iOS",
            "slug": "ios"
          }
        }
      ],
      "genres": [
        {
          "id": 4,
          "name": "Action",
          "slug": "action"
        }
      ]
    },
    {
      "slug": "assassins-creed-rogue-2",
      "name": "Assassin’s Creed Rogue",
      "playtime": 12,
      "platforms": [
        {
          "platform": {
            "id": 4,
            "name": "PC",
            "slug": "pc"
          }
        },
        {
          "platform": {
            "id": 1,
            "name": "Xbox One",
            "slug": "xbox-one"
          }
        },
        {
          "platform": {
            "id": 18,
            "name": "PlayStation 4",
            "slug": "playstation4"
          }
        },
        {
          "platform": {
            "id": 7,
            "name": "Nintendo Switch",
            "slug": "nintendo-switch"
          }
        },
        {
          "platform": {
            "id": 14,
            "name": "Xbox 360",
            "slug": "xbox360"
          }
        },
        {
          "platform": {
            "id": 16,
            "name": "PlayStation 3",
            "slug": "playstation3"
          }
        }
      ],
      "stores": [
        {
          "store": {
            "id": 1,
            "name": "Steam",
            "slug": "steam"
          }
        },
        {
          "store": {
            "id": 3,
            "name": "PlayStation Store",
            "slug": "playstation-store"
          }
        },
        {
          "store": {
            "id": 2,
            "name": "Xbox Store",
            "slug": "xbox-store"
          }
        },
        {
          "store": {
            "id": 7,
            "name": "Xbox 360 Store",
            "slug": "xbox360"
          }
        }
      ],
      "released": "2014-11-11",
      "tba": false,
      "background_image": "https://media.rawg.io/media/games/3c4/3c4a44ed99c87c56e0cdcfaaaf5c3628.jpg",
      "rating": 3.71,
      "rating_top": 4,
      "ratings": [
        {
          "id": 4,
          "title": "recommended",
          "count": 431,
          "percent": 55.47
        },
        {
          "id": 3,
          "title": "meh",
          "count": 212,
          "percent": 27.28
        },
        {
          "id": 5,
          "title": "exceptional",
          "count": 98,
          "percent": 12.61
        },
        {
          "id": 1,
          "title": "skip",
          "count": 36,
          "percent": 4.63
        }
      ],
      "ratings_count": 767,
      "reviews_text_count": 8,
      "added": 3132,
      "added_by_status": {
        "yet": 257,
        "owned": 1568,
        "beaten": 929,
        "toplay": 187,
        "dropped": 167,
        "playing": 24
      },
      "metacritic": 74,
      "suggestions_count": 602,
      "updated": "2025-07-27T18:56:41",
      "id": 17545,
      "score": "58.76829",
      "clip": null,
      "tags": [
        {
          "id": 31,
          "name": "Singleplayer",
          "slug": "singleplayer",
          "language": "eng",
          "games_count": 243431,
          "image_background": "https://media.rawg.io/media/games/bc0/bc06a29ceac58652b684deefe7d56099.jpg"
        },
        {
          "id": 42396,
          "name": "Для одного игрока",
          "slug": "dlia-odnogo-igroka",
          "language": "rus",
          "games_count": 64755,
          "image_background": "https://media.rawg.io/media/games/7cf/7cfc9220b401b7a300e409e539c9afd5.jpg"
        },
        {
          "id": 42417,
          "name": "Экшен",
          "slug": "ekshen",
          "language": "rus",
          "games_count": 47736,
          "image_background": "https://media.rawg.io/media/games/7cf/7cfc9220b401b7a300e409e539c9afd5.jpg"
        },
        {
          "id": 42392,
          "name": "Приключение",
          "slug": "prikliuchenie",
          "language": "rus",
          "games_count": 46088,
          "image_background": "https://media.rawg.io/media/games/ee3/ee3e10193aafc3230ba1cae426967d10.jpg"
        },
        {
          "id": 13,
          "name": "Atmospheric",
          "slug": "atmospheric",
          "language": "eng",
          "games_count": 37903,
          "image_background": "https://media.rawg.io/media/games/6cd/6cd653e0aaef5ff8bbd295bf4bcb12eb.jpg"
        },
        {
          "id": 42400,
          "name": "Атмосфера",
          "slug": "atmosfera",
          "language": "rus",
          "games_count": 6083,
          "image_background": "https://media.rawg.io/media/games/737/737ea5662211d2e0bbd6f5989189e4f1.jpg"
        },
        {
          "id": 42394,
          "name": "Глубокий сюжет",
          "slug": "glubokii-siuzhet",
          "language": "rus",
          "games_count": 16522,
          "image_background": "https://media.rawg.io/media/games/4be/4be6a6ad0364751a96229c56bf69be59.jpg"
        },
        {
          "id": 118,
          "name": "Story Rich",
          "slug": "story-rich",
          "language": "eng",
          "games_count": 25656,
          "image_background": "https://media.rawg.io/media/games/7fa/7fa0b586293c5861ee32490e953a4996.jpg"
        },
        {
          "id": 42442,
          "name": "Открытый мир",
          "slug": "otkrytyi-mir",
          "language": "rus",
          "games_count": 6977,
          "image_background": "https://media.rawg.io/media/games/49c/49c3dfa4ce2f6f140cc4825868e858cb.jpg"
        },
        {
          "id": 36,
          "name": "Open World",
          "slug": "open-world",
          "language": "eng",
          "games_count": 8790,
          "image_background": "https://media.rawg.io/media/games/9aa/9aa42d16d425fa6f179fc9dc2f763647.jpg"
        },
        {
          "id": 42435,
          "name": "Шедевр",
          "slug": "shedevr",
          "language": "rus",
          "games_count": 1059,
          "image_background": "https://media.rawg.io/media/games/7cf/7cfc9220b401b7a300e409e539c9afd5.jpg"
        },
        {
          "id": 42441,
          "name": "От третьего лица",
          "slug": "ot-tretego-litsa",
          "language": "rus",
          "games_count": 9405,
          "image_background": "https://media.rawg.io/media/games/6cd/6cd653e0aaef5ff8bbd295bf4bcb12eb.jpg"
        },
        {
          "id": 149,
          "name": "Third Person",
          "slug": "third-person",
          "language": "eng",
          "games_count": 13881,
          "image_background": "https://media.rawg.io/media/games/6cd/6cd653e0aaef5ff8bbd295bf4bcb12eb.jpg"
        },
        {
          "id": 40845,
          "name": "Partial Controller Support",
          "slug": "partial-controller-support",
          "language": "eng",
          "games_count": 13409,
          "image_background": "https://media.rawg.io/media/games/095/0953bf01cd4e4dd204aba85489ac9868.jpg"
        },
        {
          "id": 42413,
          "name": "Симулятор",
          "slug": "simuliator",
          "language": "rus",
          "games_count": 24104,
          "image_background": "https://media.rawg.io/media/games/dd5/dd50d4266915d56dd5b63ae1bf72606a.jpg"
        },
        {
          "id": 42465,
          "name": "Головоломка",
          "slug": "golovolomka",
          "language": "rus",
          "games_count": 19891,
          "image_background": "https://media.rawg.io/media/games/1fb/1fb1c5f7a71d771f440b27ce7f71e7eb.jpg"
        },
        {
          "id": 37,
          "name": "Sandbox",
          "slug": "sandbox",
          "language": "eng",
          "games_count": 8064,
          "image_background": "https://media.rawg.io/media/games/b4e/b4e4c73d5aa4ec66bbf75375c4847a2b.jpg"
        },
        {
          "id": 42444,
          "name": "Песочница",
          "slug": "pesochnitsa",
          "language": "rus",
          "games_count": 5293,
          "image_background": "https://media.rawg.io/media/games/48e/48e63bbddeddbe9ba81942772b156664.jpg"
        },
        {
          "id": 15,
          "name": "Stealth",
          "slug": "stealth",
          "language": "eng",
          "games_count": 6904,
          "image_background": "https://media.rawg.io/media/games/f6b/f6bed028b02369d4cab548f4f9337e81.jpg"
        },
        {
          "id": 42439,
          "name": "Стелс",
          "slug": "stels",
          "language": "rus",
          "games_count": 2762,
          "image_background": "https://media.rawg.io/media/games/7f6/7f6cd70ba2ad57053b4847c13569f2d8.jpg"
        },
        {
          "id": 69,
          "name": "Action-Adventure",
          "slug": "action-adventure",
          "language": "eng",
          "games_count": 19816,
          "image_background": "https://media.rawg.io/media/games/849/849414b978db37d4563ff9e4b0d3a787.jpg"
        },
        {
          "id": 42490,
          "name": "Приключенческий экшен",
          "slug": "prikliuchencheskii-ekshen",
          "language": "rus",
          "games_count": 12206,
          "image_background": "https://media.rawg.io/media/games/fc3/fc30790a3b3c738d7a271b02c1e26dc2.jpg"
        },
        {
          "id": 89,
          "name": "Historical",
          "slug": "historical",
          "language": "eng",
          "games_count": 3781,
          "image_background": "https://media.rawg.io/media/games/849/849414b978db37d4563ff9e4b0d3a787.jpg"
        },
        {
          "id": 110,
          "name": "Cinematic",
          "slug": "cinematic",
          "language": "eng",
          "games_count": 3043,
          "image_background": "https://media.rawg.io/media/games/2ad/2ad87a4a69b1104f02435c14c5196095.jpg"
        },
        {
          "id": 42403,
          "name": "История",
          "slug": "istoriia",
          "language": "rus",
          "games_count": 940,
          "image_background": "https://media.rawg.io/media/games/bff/bff7d82316cddea9541261a045ba008a.jpg"
        },
        {
          "id": 42643,
          "name": "Паркур",
          "slug": "parkur-2",
          "language": "rus",
          "games_count": 1622,
          "image_background": "https://media.rawg.io/media/games/336/336c6bd63d83cf8e59937ab8895d1240.jpg"
        },
        {
          "id": 188,
          "name": "Parkour",
          "slug": "parkour",
          "language": "eng",
          "games_count": 3941,
          "image_background": "https://media.rawg.io/media/games/193/19390fa5e75e9048b22c9a736cf9992f.jpg"
        },
        {
          "id": 42623,
          "name": "Кинематографичная",
          "slug": "kinematografichnaia",
          "language": "rus",
          "games_count": 2951,
          "image_background": "https://media.rawg.io/media/games/0b3/0b34647c42271600399b93d19b10f1aa.jpg"
        },
        {
          "id": 305,
          "name": "Linear",
          "slug": "linear",
          "language": "eng",
          "games_count": 8764,
          "image_background": "https://media.rawg.io/media/games/395/395ad028483d6cd9076b746a3eec993d.jpg"
        },
        {
          "id": 278,
          "name": "Assassin",
          "slug": "assassin",
          "language": "eng",
          "games_count": 934,
          "image_background": "https://media.rawg.io/media/games/3f6/3f6a397ec36acfcc18bb6ab3414c7658.jpg"
        },
        {
          "id": 42440,
          "name": "Ассассины",
          "slug": "assassiny",
          "language": "rus",
          "games_count": 452,
          "image_background": "https://media.rawg.io/media/games/275/2759da6fcaa8f81f21800926168c85f6.jpg"
        },
        {
          "id": 178,
          "name": "Illuminati",
          "slug": "illuminati",
          "language": "eng",
          "games_count": 364,
          "image_background": "https://media.rawg.io/media/screenshots/95a/95a557d6dfa6430dd662a136d71e5915.jpg"
        },
        {
          "id": 269,
          "name": "Quick-Time Events",
          "slug": "quick-time-events",
          "language": "eng",
          "games_count": 836,
          "image_background": "https://media.rawg.io/media/games/b45/b45575f34285f2c4479c9a5f719d972e.jpg"
        },
        {
          "id": 42448,
          "name": "Иллюминаты",
          "slug": "illiuminaty",
          "language": "rus",
          "games_count": 308,
          "image_background": "https://media.rawg.io/media/games/f52/f52cf6ba08089cd5f1a9c8f7fcc93d1f.jpg"
        },
        {
          "id": 255,
          "name": "Pirates",
          "slug": "pirates",
          "language": "eng",
          "games_count": 2298,
          "image_background": "https://media.rawg.io/media/screenshots/89c/89c786468e50fab24d6859b7edaf91c0.jpg"
        },
        {
          "id": 42499,
          "name": "Пираты",
          "slug": "piraty",
          "language": "rus",
          "games_count": 599,
          "image_background": "https://media.rawg.io/media/screenshots/fb3/fb3d19e8da6a4fc13515c344c0e8c6ce.jpg"
        }
      ],
      "esrb_rating": {
        "id": 4,
        "name": "Mature",
        "slug": "mature",
        "name_en": "Mature",
        "name_ru": "С 17 лет"
      },
      "user_game": null,
      "reviews_count": 777,
      "saturated_color": "0f0f0f",
      "dominant_color": "0f0f0f",
      "short_screenshots": [
        {
          "id": -1,
          "image": "https://media.rawg.io/media/games/3c4/3c4a44ed99c87c56e0cdcfaaaf5c3628.jpg"
        },
        {
          "id": 160185,
          "image": "https://media.rawg.io/media/screenshots/37d/37d2f487abad3fbfe73b355224e73522.jpg"
        },
        {
          "id": 160186,
          "image": "https://media.rawg.io/media/screenshots/eac/eac7037fbcbbee5c2df5418ba367bcfc.jpg"
        },
        {
          "id": 160187,
          "image": "https://media.rawg.io/media/screenshots/fbb/fbb236226c2490364ff457e92a048a00.jpg"
        },
        {
          "id": 160188,
          "image": "https://media.rawg.io/media/screenshots/886/886b4aab77406fd49aea1c8b73849a9b.jpg"
        },
        {
          "id": 277572,
          "image": "https://media.rawg.io/media/screenshots/483/483c515648d2521662ada949081897cb.jpg"
        },
        {
          "id": 277573,
          "image": "https://media.rawg.io/media/screenshots/441/441d4493bdf5ee9d1b6703bceda074ea.jpg"
        }
      ],
      "parent_platforms": [
        {
          "platform": {
            "id": 1,
            "name": "PC",
            "slug": "pc"
          }
        },
        {
          "platform": {
            "id": 2,
            "name": "PlayStation",
            "slug": "playstation"
          }
        },
        {
          "platform": {
            "id": 3,
            "name": "Xbox",
            "slug": "xbox"
          }
        },
        {
          "platform": {
            "id": 7,
            "name": "Nintendo",
            "slug": "nintendo"
          }
        }
      ],
      "genres": [
        {
          "id": 3,
          "name": "Adventure",
          "slug": "adventure"
        },
        {
          "id": 4,
          "name": "Action",
          "slug": "action"
        }
      ]
    },
    {
      "slug": "assassins-creed-identity",
      "name": "Assassin’s Creed: Identity",
      "playtime": 0,
      "platforms": [
        {
          "platform": {
            "id": 3,
            "name": "iOS",
            "slug": "ios"
          }
        },
        {
          "platform": {
            "id": 21,
            "name": "Android",
            "slug": "android"
          }
        }
      ],
      "stores": [
        {
          "store": {
            "id": 4,
            "name": "App Store",
            "slug": "apple-appstore"
          }
        },
        {
          "store": {
            "id": 8,
            "name": "Google Play",
            "slug": "google-play"
          }
        }
      ],
      "released": "2016-02-25",
      "tba": false,
      "background_image": "https://media.rawg.io/media/games/057/057d16809624e4907142a6922a7e7f41.jpg",
      "rating": 2.86,
      "rating_top": 4,
      "ratings": [
        {
          "id": 4,
          "title": "recommended",
          "count": 7,
          "percent": 33.33
        },
        {
          "id": 1,
          "title": "skip",
          "count": 7,
          "percent": 33.33
        },
        {
          "id": 3,
          "title": "meh",
          "count": 5,
          "percent": 23.81
        },
        {
          "id": 5,
          "title": "exceptional",
          "count": 2,
          "percent": 9.52
        }
      ],
      "ratings_count": 19,
      "reviews_text_count": 1,
      "added": 64,
      "added_by_status": {
        "yet": 9,
        "owned": 8,
        "beaten": 15,
        "toplay": 7,
        "dropped": 21,
        "playing": 4
      },
      "metacritic": null,
      "suggestions_count": 529,
      "updated": "2024-01-18T10:00:39",
      "id": 332170,
      "score": "58.30242",
      "clip": null,
      "tags": [
        {
          "id": 24,
          "name": "RPG",
          "slug": "rpg",
          "language": "eng",
          "games_count": 24895,
          "image_background": "https://media.rawg.io/media/games/15c/15c95a4915f88a3e89c821526afe05fc.jpg"
        },
        {
          "id": 117,
          "name": "Mystery",
          "slug": "mystery",
          "language": "eng",
          "games_count": 15497,
          "image_background": "https://media.rawg.io/media/games/be0/be084b850302abe81675bc4ffc08a0d0.jpg"
        },
        {
          "id": 413,
          "name": "online",
          "slug": "online",
          "language": "eng",
          "games_count": 6555,
          "image_background": "https://media.rawg.io/media/games/739/73990e3ec9f43a9e8ecafe207fa4f368.jpg"
        },
        {
          "id": 278,
          "name": "Assassin",
          "slug": "assassin",
          "language": "eng",
          "games_count": 928,
          "image_background": "https://media.rawg.io/media/games/934/9346092ae11bf7582c883869468171cc.jpg"
        },
        {
          "id": 98,
          "name": "Loot",
          "slug": "loot",
          "language": "eng",
          "games_count": 2674,
          "image_background": "https://media.rawg.io/media/games/3be/3be0e624424d3453005019799a760af2.jpg"
        },
        {
          "id": 581,
          "name": "Epic",
          "slug": "epic",
          "language": "eng",
          "games_count": 4128,
          "image_background": "https://media.rawg.io/media/screenshots/53b/53b07d7d8979bd4a5cb4e484c7aacc33.jpg"
        },
        {
          "id": 607,
          "name": "Unity",
          "slug": "unity",
          "language": "eng",
          "games_count": 70824,
          "image_background": "https://media.rawg.io/media/screenshots/78c/78cda9566a67924bd658e61256d7a037.jpg"
        },
        {
          "id": 835,
          "name": "Swords",
          "slug": "swords",
          "language": "eng",
          "games_count": 1461,
          "image_background": "https://media.rawg.io/media/screenshots/86a/86a1ca92bee366c36e30aad87c0604ee.jpg"
        },
        {
          "id": 1994,
          "name": "tap",
          "slug": "tap",
          "language": "eng",
          "games_count": 7836,
          "image_background": "https://media.rawg.io/media/screenshots/525/525b5da62342fa726bfe2820e8f93c09.jpg"
        },
        {
          "id": 706,
          "name": "gamepad",
          "slug": "gamepad",
          "language": "eng",
          "games_count": 2457,
          "image_background": "https://media.rawg.io/media/screenshots/75d/75d8e5ed7536427f9f08ec58ffcb1246.jpg"
        }
      ],
      "esrb_rating": null,
      "user_game": null,
      "reviews_count": 21,
      "saturated_color": "0f0f0f",
      "dominant_color": "0f0f0f",
      "short_screenshots": [
        {
          "id": -1,
          "image": "https://media.rawg.io/media/games/057/057d16809624e4907142a6922a7e7f41.jpg"
        },
        {
          "id": 822294,
          "image": "https://media.rawg.io/media/screenshots/572/5721898564f238a4719625aa53637460.jpg"
        },
        {
          "id": 822295,
          "image": "https://media.rawg.io/media/screenshots/9cc/9cc8ab06c84df85ce670a9aa2c617ad1.jpg"
        },
        {
          "id": 822296,
          "image": "https://media.rawg.io/media/screenshots/f50/f503d8a9c03391c7e77259f1bad1cde1.jpg"
        },
        {
          "id": 822297,
          "image": "https://media.rawg.io/media/screenshots/f53/f534397f7d53d25697f8267c64ba5c50.jpg"
        },
        {
          "id": 822298,
          "image": "https://media.rawg.io/media/screenshots/e58/e58e71be711d4296ddfe09dc9ce69946.jpg"
        },
        {
          "id": 1974508,
          "image": "https://media.rawg.io/media/screenshots/a67/a673e102ba6105df629017f22ffb7f67.jpg"
        }
      ],
      "parent_platforms": [
        {
          "platform": {
            "id": 4,
            "name": "iOS",
            "slug": "ios"
          }
        },
        {
          "platform": {
            "id": 8,
            "name": "Android",
            "slug": "android"
          }
        }
      ],
      "genres": [
        {
          "id": 4,
          "name": "Action",
          "slug": "action"
        },
        {
          "id": 5,
          "name": "RPG",
          "slug": "role-playing-games-rpg"
        }
      ]
    },
    {
      "slug": "assassins-creed-revelations",
      "name": "Assassin's Creed Revelations",
      "playtime": 14,
      "platforms": [
        {
          "platform": {
            "id": 4,
            "name": "PC",
            "slug": "pc"
          }
        },
        {
          "platform": {
            "id": 1,
            "name": "Xbox One",
            "slug": "xbox-one"
          }
        },
        {
          "platform": {
            "id": 18,
            "name": "PlayStation 4",
            "slug": "playstation4"
          }
        },
        {
          "platform": {
            "id": 14,
            "name": "Xbox 360",
            "slug": "xbox360"
          }
        },
        {
          "platform": {
            "id": 16,
            "name": "PlayStation 3",
            "slug": "playstation3"
          }
        }
      ],
      "stores": [
        {
          "store": {
            "id": 1,
            "name": "Steam",
            "slug": "steam"
          }
        },
        {
          "store": {
            "id": 3,
            "name": "PlayStation Store",
            "slug": "playstation-store"
          }
        },
        {
          "store": {
            "id": 2,
            "name": "Xbox Store",
            "slug": "xbox-store"
          }
        },
        {
          "store": {
            "id": 7,
            "name": "Xbox 360 Store",
            "slug": "xbox360"
          }
        }
      ],
      "released": "2011-11-15",
      "tba": false,
      "background_image": "https://media.rawg.io/media/games/193/19390fa5e75e9048b22c9a736cf9992f.jpg",
      "rating": 3.99,
      "rating_top": 4,
      "ratings": [
        {
          "id": 4,
          "title": "recommended",
          "count": 887,
          "percent": 60.92
        },
        {
          "id": 5,
          "title": "exceptional",
          "count": 301,
          "percent": 20.67
        },
        {
          "id": 3,
          "title": "meh",
          "count": 242,
          "percent": 16.62
        },
        {
          "id": 1,
          "title": "skip",
          "count": 26,
          "percent": 1.79
        }
      ],
      "ratings_count": 1435,
      "reviews_text_count": 14,
      "added": 4844,
      "added_by_status": {
        "yet": 221,
        "owned": 2217,
        "beaten": 2053,
        "toplay": 142,
        "dropped": 185,
        "playing": 26
      },
      "metacritic": 80,
      "suggestions_count": 635,
      "updated": "2025-07-30T08:56:56",
      "id": 4358,
      "score": "58.255196",
      "clip": null,
      "tags": [
        {
          "id": 31,
          "name": "Singleplayer",
          "slug": "singleplayer",
          "language": "eng",
          "games_count": 243828,
          "image_background": "https://media.rawg.io/media/games/f46/f466571d536f2e3ea9e815ad17177501.jpg"
        },
        {
          "id": 42396,
          "name": "Для одного игрока",
          "slug": "dlia-odnogo-igroka",
          "language": "rus",
          "games_count": 65063,
          "image_background": "https://media.rawg.io/media/games/511/5118aff5091cb3efec399c808f8c598f.jpg"
        },
        {
          "id": 42417,
          "name": "Экшен",
          "slug": "ekshen",
          "language": "rus",
          "games_count": 47885,
          "image_background": "https://media.rawg.io/media/games/7fa/7fa0b586293c5861ee32490e953a4996.jpg"
        },
        {
          "id": 42392,
          "name": "Приключение",
          "slug": "prikliuchenie",
          "language": "rus",
          "games_count": 46267,
          "image_background": "https://media.rawg.io/media/games/26d/26d4437715bee60138dab4a7c8c59c92.jpg"
        },
        {
          "id": 7,
          "name": "Multiplayer",
          "slug": "multiplayer",
          "language": "eng",
          "games_count": 41388,
          "image_background": "https://media.rawg.io/media/games/34b/34b1f1850a1c06fd971bc6ab3ac0ce0e.jpg"
        },
        {
          "id": 13,
          "name": "Atmospheric",
          "slug": "atmospheric",
          "language": "eng",
          "games_count": 37992,
          "image_background": "https://media.rawg.io/media/games/737/737ea5662211d2e0bbd6f5989189e4f1.jpg"
        },
        {
          "id": 42425,
          "name": "Для нескольких игроков",
          "slug": "dlia-neskolkikh-igrokov",
          "language": "rus",
          "games_count": 12143,
          "image_background": "https://media.rawg.io/media/games/ec3/ec3a7db7b8ab5a71aad622fe7c62632f.jpg"
        },
        {
          "id": 42400,
          "name": "Атмосфера",
          "slug": "atmosfera",
          "language": "rus",
          "games_count": 6083,
          "image_background": "https://media.rawg.io/media/games/737/737ea5662211d2e0bbd6f5989189e4f1.jpg"
        },
        {
          "id": 42401,
          "name": "Отличный саундтрек",
          "slug": "otlichnyi-saundtrek",
          "language": "rus",
          "games_count": 4658,
          "image_background": "https://media.rawg.io/media/games/20a/20aa03a10cda45239fe22d035c0ebe64.jpg"
        },
        {
          "id": 42,
          "name": "Great Soundtrack",
          "slug": "great-soundtrack",
          "language": "eng",
          "games_count": 3434,
          "image_background": "https://media.rawg.io/media/games/7cf/7cfc9220b401b7a300e409e539c9afd5.jpg"
        },
        {
          "id": 42394,
          "name": "Глубокий сюжет",
          "slug": "glubokii-siuzhet",
          "language": "rus",
          "games_count": 16612,
          "image_background": "https://media.rawg.io/media/games/6c5/6c55e22185876626881b76c11922b073.jpg"
        },
        {
          "id": 24,
          "name": "RPG",
          "slug": "rpg",
          "language": "eng",
          "games_count": 25171,
          "image_background": "https://media.rawg.io/media/games/b45/b45575f34285f2c4479c9a5f719d972e.jpg"
        },
        {
          "id": 42412,
          "name": "Ролевая игра",
          "slug": "rolevaia-igra",
          "language": "rus",
          "games_count": 21574,
          "image_background": "https://media.rawg.io/media/games/26d/26d4437715bee60138dab4a7c8c59c92.jpg"
        },
        {
          "id": 118,
          "name": "Story Rich",
          "slug": "story-rich",
          "language": "eng",
          "games_count": 25746,
          "image_background": "https://media.rawg.io/media/games/26d/26d4437715bee60138dab4a7c8c59c92.jpg"
        },
        {
          "id": 42442,
          "name": "Открытый мир",
          "slug": "otkrytyi-mir",
          "language": "rus",
          "games_count": 7003,
          "image_background": "https://media.rawg.io/media/games/6cd/6cd653e0aaef5ff8bbd295bf4bcb12eb.jpg"
        },
        {
          "id": 36,
          "name": "Open World",
          "slug": "open-world",
          "language": "eng",
          "games_count": 8816,
          "image_background": "https://media.rawg.io/media/games/e6d/e6de699bd788497f4b52e2f41f9698f2.jpg"
        },
        {
          "id": 42435,
          "name": "Шедевр",
          "slug": "shedevr",
          "language": "rus",
          "games_count": 1059,
          "image_background": "https://media.rawg.io/media/games/7cf/7cfc9220b401b7a300e409e539c9afd5.jpg"
        },
        {
          "id": 42441,
          "name": "От третьего лица",
          "slug": "ot-tretego-litsa",
          "language": "rus",
          "games_count": 9458,
          "image_background": "https://media.rawg.io/media/games/b49/b4912b5dbfc7ed8927b65f05b8507f6c.jpg"
        },
        {
          "id": 149,
          "name": "Third Person",
          "slug": "third-person",
          "language": "eng",
          "games_count": 13934,
          "image_background": "https://media.rawg.io/media/games/562/562553814dd54e001a541e4ee83a591c.jpg"
        },
        {
          "id": 32,
          "name": "Sci-fi",
          "slug": "sci-fi",
          "language": "eng",
          "games_count": 21333,
          "image_background": "https://media.rawg.io/media/games/157/15742f2f67eacff546738e1ab5c19d20.jpg"
        },
        {
          "id": 37,
          "name": "Sandbox",
          "slug": "sandbox",
          "language": "eng",
          "games_count": 8088,
          "image_background": "https://media.rawg.io/media/games/849/849414b978db37d4563ff9e4b0d3a787.jpg"
        },
        {
          "id": 42444,
          "name": "Песочница",
          "slug": "pesochnitsa",
          "language": "rus",
          "games_count": 5317,
          "image_background": "https://media.rawg.io/media/games/58a/58ac7f6569259dcc0b60b921869b19fc.jpg"
        },
        {
          "id": 15,
          "name": "Stealth",
          "slug": "stealth",
          "language": "eng",
          "games_count": 6913,
          "image_background": "https://media.rawg.io/media/games/7ac/7aca7ccf0e70cd0974cb899ab9e5158e.jpg"
        },
        {
          "id": 42439,
          "name": "Стелс",
          "slug": "stels",
          "language": "rus",
          "games_count": 2771,
          "image_background": "https://media.rawg.io/media/games/1bd/1bd2657b81eb0c99338120ad444b24ff.jpg"
        },
        {
          "id": 69,
          "name": "Action-Adventure",
          "slug": "action-adventure",
          "language": "eng",
          "games_count": 19877,
          "image_background": "https://media.rawg.io/media/games/fc3/fc30790a3b3c738d7a271b02c1e26dc2.jpg"
        },
        {
          "id": 42416,
          "name": "Контроллер",
          "slug": "kontroller",
          "language": "rus",
          "games_count": 8614,
          "image_background": "https://media.rawg.io/media/games/04a/04a7e7e185fb51493bdcbe1693a8b3dc.jpg"
        },
        {
          "id": 115,
          "name": "Controller",
          "slug": "controller",
          "language": "eng",
          "games_count": 14169,
          "image_background": "https://media.rawg.io/media/games/c50/c5085506fe4b5e20fc7aa5ace842c20b.jpg"
        },
        {
          "id": 42490,
          "name": "Приключенческий экшен",
          "slug": "prikliuchencheskii-ekshen",
          "language": "rus",
          "games_count": 12267,
          "image_background": "https://media.rawg.io/media/games/baf/baf9905270314e07e6850cffdb51df41.jpg"
        },
        {
          "id": 89,
          "name": "Historical",
          "slug": "historical",
          "language": "eng",
          "games_count": 3791,
          "image_background": "https://media.rawg.io/media/games/849/849414b978db37d4563ff9e4b0d3a787.jpg"
        },
        {
          "id": 42403,
          "name": "История",
          "slug": "istoriia",
          "language": "rus",
          "games_count": 940,
          "image_background": "https://media.rawg.io/media/games/bff/bff7d82316cddea9541261a045ba008a.jpg"
        },
        {
          "id": 42391,
          "name": "Средневековье",
          "slug": "srednevekove",
          "language": "rus",
          "games_count": 4584,
          "image_background": "https://media.rawg.io/media/screenshots/c97/c97b943741f5fbc936fe054d9d58851d.jpg"
        },
        {
          "id": 42643,
          "name": "Паркур",
          "slug": "parkur-2",
          "language": "rus",
          "games_count": 1637,
          "image_background": "https://media.rawg.io/media/games/bd7/bd7cfccfececba1ec2b97a120a40373f.jpg"
        },
        {
          "id": 66,
          "name": "Medieval",
          "slug": "medieval",
          "language": "eng",
          "games_count": 7646,
          "image_background": "https://media.rawg.io/media/games/c81/c812e158129e00c9b0f096ae8a0bb7d6.jpg"
        },
        {
          "id": 188,
          "name": "Parkour",
          "slug": "parkour",
          "language": "eng",
          "games_count": 3956,
          "image_background": "https://media.rawg.io/media/games/9f1/9f189c639f70f91166df415811a8b525.jpg"
        },
        {
          "id": 278,
          "name": "Assassin",
          "slug": "assassin",
          "language": "eng",
          "games_count": 938,
          "image_background": "https://media.rawg.io/media/games/c35/c354856af9151dc63844be4f9843d2c2.jpg"
        },
        {
          "id": 42440,
          "name": "Ассассины",
          "slug": "assassiny",
          "language": "rus",
          "games_count": 456,
          "image_background": "https://media.rawg.io/media/games/4e6/4e6e8e7f50c237d76f38f3c885dae3d2.jpg"
        },
        {
          "id": 291,
          "name": "Conspiracy",
          "slug": "conspiracy",
          "language": "eng",
          "games_count": 978,
          "image_background": "https://media.rawg.io/media/screenshots/ca0/ca06700d8184f451b99396c23b4ffbe4.jpg"
        },
        {
          "id": 42641,
          "name": "Заговор",
          "slug": "zagovor",
          "language": "rus",
          "games_count": 732,
          "image_background": "https://media.rawg.io/media/screenshots/5f0/5f00e2338ab8fa6c48d05d4a2bb9dc60.jpg"
        }
      ],
      "esrb_rating": {
        "id": 4,
        "name": "Mature",
        "slug": "mature",
        "name_en": "Mature",
        "name_ru": "С 17 лет"
      },
      "user_game": null,
      "reviews_count": 1456,
      "saturated_color": "0f0f0f",
      "dominant_color": "0f0f0f",
      "short_screenshots": [
        {
          "id": -1,
          "image": "https://media.rawg.io/media/games/193/19390fa5e75e9048b22c9a736cf9992f.jpg"
        },
        {
          "id": 183063,
          "image": "https://media.rawg.io/media/screenshots/23d/23d919e7ca933bf608c2869f40480f27.jpg"
        },
        {
          "id": 183064,
          "image": "https://media.rawg.io/media/screenshots/8a6/8a6239be63c8bebdb1abd817046ed610.jpg"
        },
        {
          "id": 183065,
          "image": "https://media.rawg.io/media/screenshots/ba7/ba7a272b58309a621b16eee60b0a7c86.jpg"
        },
        {
          "id": 183066,
          "image": "https://media.rawg.io/media/screenshots/474/474d379e5b5d7bd021cad5d7f965f3cc.jpg"
        },
        {
          "id": 183067,
          "image": "https://media.rawg.io/media/screenshots/e4a/e4a628ce348f7531fad2e23ee6d2ce97.jpg"
        },
        {
          "id": 183068,
          "image": "https://media.rawg.io/media/screenshots/915/9156bb553e10c5245840026551d1acc2.jpg"
        }
      ],
      "parent_platforms": [
        {
          "platform": {
            "id": 1,
            "name": "PC",
            "slug": "pc"
          }
        },
        {
          "platform": {
            "id": 2,
            "name": "PlayStation",
            "slug": "playstation"
          }
        },
        {
          "platform": {
            "id": 3,
            "name": "Xbox",
            "slug": "xbox"
          }
        }
      ],
      "genres": [
        {
          "id": 4,
          "name": "Action",
          "slug": "action"
        }
      ]
    },
    {
      "slug": "assassins-creed-chronicles",
      "name": "Assassin's Creed Chronicles",
      "playtime": 0,
      "platforms": [
        {
          "platform": {
            "id": 4,
            "name": "PC",
            "slug": "pc"
          }
        },
        {
          "platform": {
            "id": 1,
            "name": "Xbox One",
            "slug": "xbox-one"
          }
        },
        {
          "platform": {
            "id": 18,
            "name": "PlayStation 4",
            "slug": "playstation4"
          }
        },
        {
          "platform": {
            "id": 19,
            "name": "PS Vita",
            "slug": "ps-vita"
          }
        }
      ],
      "stores": [
        {
          "store": {
            "id": 3,
            "name": "PlayStation Store",
            "slug": "playstation-store"
          }
        },
        {
          "store": {
            "id": 2,
            "name": "Xbox Store",
            "slug": "xbox-store"
          }
        }
      ],
      "released": "2016-02-09",
      "tba": false,
      "background_image": "https://media.rawg.io/media/games/b86/b86c1a368a97b1fb0b757429f7659c70.jpg",
      "rating": 2.95,
      "rating_top": 4,
      "ratings": [
        {
          "id": 4,
          "title": "recommended",
          "count": 29,
          "percent": 43.94
        },
        {
          "id": 1,
          "title": "skip",
          "count": 18,
          "percent": 27.27
        },
        {
          "id": 3,
          "title": "meh",
          "count": 17,
          "percent": 25.76
        },
        {
          "id": 5,
          "title": "exceptional",
          "count": 2,
          "percent": 3.03
        }
      ],
      "ratings_count": 65,
      "reviews_text_count": 0,
      "added": 293,
      "added_by_status": {
        "yet": 42,
        "owned": 121,
        "beaten": 49,
        "toplay": 42,
        "dropped": 37,
        "playing": 2
      },
      "metacritic": 70,
      "suggestions_count": 364,
      "updated": "2025-07-27T18:56:41",
      "id": 330884,
      "score": "57.64041",
      "clip": null,
      "tags": [
        {
          "id": 15,
          "name": "Stealth",
          "slug": "stealth",
          "language": "eng",
          "games_count": 6904,
          "image_background": "https://media.rawg.io/media/games/f6b/f6bed028b02369d4cab548f4f9337e81.jpg"
        },
        {
          "id": 1465,
          "name": "combat",
          "slug": "combat",
          "language": "eng",
          "games_count": 15250,
          "image_background": "https://media.rawg.io/media/games/260/26023c855f1769a93411d6a7ea084632.jpeg"
        },
        {
          "id": 413,
          "name": "online",
          "slug": "online",
          "language": "eng",
          "games_count": 6555,
          "image_background": "https://media.rawg.io/media/games/af2/af2b640fa820e8a8135948a4cd399539.jpg"
        },
        {
          "id": 278,
          "name": "Assassin",
          "slug": "assassin",
          "language": "eng",
          "games_count": 934,
          "image_background": "https://media.rawg.io/media/games/3f6/3f6a397ec36acfcc18bb6ab3414c7658.jpg"
        },
        {
          "id": 1221,
          "name": "history",
          "slug": "history",
          "language": "eng",
          "games_count": 2386,
          "image_background": "https://media.rawg.io/media/games/4e9/4e908c9270228430128105bcd88e51bc.jpg"
        },
        {
          "id": 1626,
          "name": "collection",
          "slug": "collection",
          "language": "eng",
          "games_count": 3698,
          "image_background": "https://media.rawg.io/media/screenshots/e51/e51f9a3d6694ceb8bbae0124593f7bd8.jpg"
        },
        {
          "id": 822,
          "name": "escape",
          "slug": "escape",
          "language": "eng",
          "games_count": 7643,
          "image_background": "https://media.rawg.io/media/games/d0d/d0dc606686338de79d9cbb418adb74bf.jpg"
        },
        {
          "id": 1303,
          "name": "Shadows",
          "slug": "shadows",
          "language": "eng",
          "games_count": 803,
          "image_background": "https://media.rawg.io/media/screenshots/fbe/fbe0636ae090cdf40ef074896466bd8b.jpg"
        },
        {
          "id": 5222,
          "name": "avoid",
          "slug": "avoid",
          "language": "eng",
          "games_count": 4690,
          "image_background": "https://media.rawg.io/media/screenshots/5fb/5fbad757fa71162546f26440d62e966a.jpg"
        },
        {
          "id": 5641,
          "name": "bundle",
          "slug": "bundle",
          "language": "eng",
          "games_count": 507,
          "image_background": "https://media.rawg.io/media/games/abd/abd7b98d0ebe13e7e8f2b3bb8300bc0b.jpg"
        }
      ],
      "esrb_rating": {
        "id": 3,
        "name": "Teen",
        "slug": "teen",
        "name_en": "Teen",
        "name_ru": "С 13 лет"
      },
      "user_game": null,
      "reviews_count": 66,
      "saturated_color": "0f0f0f",
      "dominant_color": "0f0f0f",
      "short_screenshots": [
        {
          "id": -1,
          "image": "https://media.rawg.io/media/games/b86/b86c1a368a97b1fb0b757429f7659c70.jpg"
        },
        {
          "id": 56285,
          "image": "https://media.rawg.io/media/screenshots/dcd/dcd319c9c3db9312c640c560a4495df6.jpg"
        },
        {
          "id": 56286,
          "image": "https://media.rawg.io/media/screenshots/d07/d0709ed56ac5cc13a4366532e585dad6.jpg"
        },
        {
          "id": 56288,
          "image": "https://media.rawg.io/media/screenshots/dbe/dbebef30abfce4d7d34eb42db5763bf0_9tcVjqI.jpg"
        },
        {
          "id": 56293,
          "image": "https://media.rawg.io/media/screenshots/929/929394ba5d7cf753281d7ba9f64ea936.jpg"
        },
        {
          "id": 56296,
          "image": "https://media.rawg.io/media/screenshots/d72/d724aec138313439dba8347af641ce93.jpg"
        },
        {
          "id": 56300,
          "image": "https://media.rawg.io/media/screenshots/591/591ff62f686bd5d09c14a9c9d70346f3.jpg"
        }
      ],
      "parent_platforms": [
        {
          "platform": {
            "id": 1,
            "name": "PC",
            "slug": "pc"
          }
        },
        {
          "platform": {
            "id": 2,
            "name": "PlayStation",
            "slug": "playstation"
          }
        },
        {
          "platform": {
            "id": 3,
            "name": "Xbox",
            "slug": "xbox"
          }
        }
      ],
      "genres": [
        {
          "id": 3,
          "name": "Adventure",
          "slug": "adventure"
        },
        {
          "id": 4,
          "name": "Action",
          "slug": "action"
        }
      ]
    },
    {
      "slug": "assassins-creed-brotherhood-2",
      "name": "Assassin’s Creed Brotherhood",
      "playtime": 16,
      "platforms": [
        {
          "platform": {
            "id": 4,
            "name": "PC",
            "slug": "pc"
          }
        },
        {
          "platform": {
            "id": 1,
            "name": "Xbox One",
            "slug": "xbox-one"
          }
        },
        {
          "platform": {
            "id": 18,
            "name": "PlayStation 4",
            "slug": "playstation4"
          }
        },
        {
          "platform": {
            "id": 5,
            "name": "macOS",
            "slug": "macos"
          }
        },
        {
          "platform": {
            "id": 14,
            "name": "Xbox 360",
            "slug": "xbox360"
          }
        },
        {
          "platform": {
            "id": 16,
            "name": "PlayStation 3",
            "slug": "playstation3"
          }
        }
      ],
      "stores": [
        {
          "store": {
            "id": 1,
            "name": "Steam",
            "slug": "steam"
          }
        },
        {
          "store": {
            "id": 3,
            "name": "PlayStation Store",
            "slug": "playstation-store"
          }
        },
        {
          "store": {
            "id": 7,
            "name": "Xbox 360 Store",
            "slug": "xbox360"
          }
        }
      ],
      "released": "2010-11-16",
      "tba": false,
      "background_image": "https://media.rawg.io/media/games/116/116b93c6876a361a96b2eee3ee58ab13.jpg",
      "rating": 4.28,
      "rating_top": 4,
      "ratings": [
        {
          "id": 4,
          "title": "recommended",
          "count": 922,
          "percent": 53.89
        },
        {
          "id": 5,
          "title": "exceptional",
          "count": 658,
          "percent": 38.46
        },
        {
          "id": 3,
          "title": "meh",
          "count": 103,
          "percent": 6.02
        },
        {
          "id": 1,
          "title": "skip",
          "count": 28,
          "percent": 1.64
        }
      ],
      "ratings_count": 1692,
      "reviews_text_count": 14,
      "added": 5349,
      "added_by_status": {
        "yet": 189,
        "owned": 2326,
        "beaten": 2468,
        "toplay": 130,
        "dropped": 192,
        "playing": 44
      },
      "metacritic": 88,
      "suggestions_count": 657,
      "updated": "2025-07-30T08:56:59",
      "id": 10064,
      "score": "57.49059",
      "clip": null,
      "tags": [
        {
          "id": 31,
          "name": "Singleplayer",
          "slug": "singleplayer",
          "language": "eng",
          "games_count": 243828,
          "image_background": "https://media.rawg.io/media/games/f46/f466571d536f2e3ea9e815ad17177501.jpg"
        },
        {
          "id": 42396,
          "name": "Для одного игрока",
          "slug": "dlia-odnogo-igroka",
          "language": "rus",
          "games_count": 65063,
          "image_background": "https://media.rawg.io/media/games/511/5118aff5091cb3efec399c808f8c598f.jpg"
        },
        {
          "id": 42417,
          "name": "Экшен",
          "slug": "ekshen",
          "language": "rus",
          "games_count": 47885,
          "image_background": "https://media.rawg.io/media/games/7fa/7fa0b586293c5861ee32490e953a4996.jpg"
        },
        {
          "id": 42392,
          "name": "Приключение",
          "slug": "prikliuchenie",
          "language": "rus",
          "games_count": 46267,
          "image_background": "https://media.rawg.io/media/games/26d/26d4437715bee60138dab4a7c8c59c92.jpg"
        },
        {
          "id": 7,
          "name": "Multiplayer",
          "slug": "multiplayer",
          "language": "eng",
          "games_count": 41388,
          "image_background": "https://media.rawg.io/media/games/34b/34b1f1850a1c06fd971bc6ab3ac0ce0e.jpg"
        },
        {
          "id": 13,
          "name": "Atmospheric",
          "slug": "atmospheric",
          "language": "eng",
          "games_count": 37992,
          "image_background": "https://media.rawg.io/media/games/737/737ea5662211d2e0bbd6f5989189e4f1.jpg"
        },
        {
          "id": 42425,
          "name": "Для нескольких игроков",
          "slug": "dlia-neskolkikh-igrokov",
          "language": "rus",
          "games_count": 12143,
          "image_background": "https://media.rawg.io/media/games/ec3/ec3a7db7b8ab5a71aad622fe7c62632f.jpg"
        },
        {
          "id": 42400,
          "name": "Атмосфера",
          "slug": "atmosfera",
          "language": "rus",
          "games_count": 6083,
          "image_background": "https://media.rawg.io/media/games/737/737ea5662211d2e0bbd6f5989189e4f1.jpg"
        },
        {
          "id": 42401,
          "name": "Отличный саундтрек",
          "slug": "otlichnyi-saundtrek",
          "language": "rus",
          "games_count": 4658,
          "image_background": "https://media.rawg.io/media/games/20a/20aa03a10cda45239fe22d035c0ebe64.jpg"
        },
        {
          "id": 42,
          "name": "Great Soundtrack",
          "slug": "great-soundtrack",
          "language": "eng",
          "games_count": 3434,
          "image_background": "https://media.rawg.io/media/games/7cf/7cfc9220b401b7a300e409e539c9afd5.jpg"
        },
        {
          "id": 42394,
          "name": "Глубокий сюжет",
          "slug": "glubokii-siuzhet",
          "language": "rus",
          "games_count": 16612,
          "image_background": "https://media.rawg.io/media/games/6c5/6c55e22185876626881b76c11922b073.jpg"
        },
        {
          "id": 118,
          "name": "Story Rich",
          "slug": "story-rich",
          "language": "eng",
          "games_count": 25746,
          "image_background": "https://media.rawg.io/media/games/26d/26d4437715bee60138dab4a7c8c59c92.jpg"
        },
        {
          "id": 42442,
          "name": "Открытый мир",
          "slug": "otkrytyi-mir",
          "language": "rus",
          "games_count": 7003,
          "image_background": "https://media.rawg.io/media/games/6cd/6cd653e0aaef5ff8bbd295bf4bcb12eb.jpg"
        },
        {
          "id": 36,
          "name": "Open World",
          "slug": "open-world",
          "language": "eng",
          "games_count": 8816,
          "image_background": "https://media.rawg.io/media/games/e6d/e6de699bd788497f4b52e2f41f9698f2.jpg"
        },
        {
          "id": 42435,
          "name": "Шедевр",
          "slug": "shedevr",
          "language": "rus",
          "games_count": 1059,
          "image_background": "https://media.rawg.io/media/games/7cf/7cfc9220b401b7a300e409e539c9afd5.jpg"
        },
        {
          "id": 42441,
          "name": "От третьего лица",
          "slug": "ot-tretego-litsa",
          "language": "rus",
          "games_count": 9458,
          "image_background": "https://media.rawg.io/media/games/b49/b4912b5dbfc7ed8927b65f05b8507f6c.jpg"
        },
        {
          "id": 149,
          "name": "Third Person",
          "slug": "third-person",
          "language": "eng",
          "games_count": 13934,
          "image_background": "https://media.rawg.io/media/games/562/562553814dd54e001a541e4ee83a591c.jpg"
        },
        {
          "id": 40845,
          "name": "Partial Controller Support",
          "slug": "partial-controller-support",
          "language": "eng",
          "games_count": 13444,
          "image_background": "https://media.rawg.io/media/games/2ad/2ad87a4a69b1104f02435c14c5196095.jpg"
        },
        {
          "id": 37,
          "name": "Sandbox",
          "slug": "sandbox",
          "language": "eng",
          "games_count": 8088,
          "image_background": "https://media.rawg.io/media/games/849/849414b978db37d4563ff9e4b0d3a787.jpg"
        },
        {
          "id": 42444,
          "name": "Песочница",
          "slug": "pesochnitsa",
          "language": "rus",
          "games_count": 5317,
          "image_background": "https://media.rawg.io/media/games/58a/58ac7f6569259dcc0b60b921869b19fc.jpg"
        },
        {
          "id": 15,
          "name": "Stealth",
          "slug": "stealth",
          "language": "eng",
          "games_count": 6913,
          "image_background": "https://media.rawg.io/media/games/7ac/7aca7ccf0e70cd0974cb899ab9e5158e.jpg"
        },
        {
          "id": 42439,
          "name": "Стелс",
          "slug": "stels",
          "language": "rus",
          "games_count": 2771,
          "image_background": "https://media.rawg.io/media/games/1bd/1bd2657b81eb0c99338120ad444b24ff.jpg"
        },
        {
          "id": 69,
          "name": "Action-Adventure",
          "slug": "action-adventure",
          "language": "eng",
          "games_count": 19877,
          "image_background": "https://media.rawg.io/media/games/fc3/fc30790a3b3c738d7a271b02c1e26dc2.jpg"
        },
        {
          "id": 42416,
          "name": "Контроллер",
          "slug": "kontroller",
          "language": "rus",
          "games_count": 8614,
          "image_background": "https://media.rawg.io/media/games/04a/04a7e7e185fb51493bdcbe1693a8b3dc.jpg"
        },
        {
          "id": 115,
          "name": "Controller",
          "slug": "controller",
          "language": "eng",
          "games_count": 14169,
          "image_background": "https://media.rawg.io/media/games/c50/c5085506fe4b5e20fc7aa5ace842c20b.jpg"
        },
        {
          "id": 42490,
          "name": "Приключенческий экшен",
          "slug": "prikliuchencheskii-ekshen",
          "language": "rus",
          "games_count": 12267,
          "image_background": "https://media.rawg.io/media/games/baf/baf9905270314e07e6850cffdb51df41.jpg"
        },
        {
          "id": 89,
          "name": "Historical",
          "slug": "historical",
          "language": "eng",
          "games_count": 3791,
          "image_background": "https://media.rawg.io/media/games/849/849414b978db37d4563ff9e4b0d3a787.jpg"
        },
        {
          "id": 42403,
          "name": "История",
          "slug": "istoriia",
          "language": "rus",
          "games_count": 940,
          "image_background": "https://media.rawg.io/media/games/bff/bff7d82316cddea9541261a045ba008a.jpg"
        },
        {
          "id": 42391,
          "name": "Средневековье",
          "slug": "srednevekove",
          "language": "rus",
          "games_count": 4584,
          "image_background": "https://media.rawg.io/media/screenshots/c97/c97b943741f5fbc936fe054d9d58851d.jpg"
        },
        {
          "id": 42643,
          "name": "Паркур",
          "slug": "parkur-2",
          "language": "rus",
          "games_count": 1637,
          "image_background": "https://media.rawg.io/media/games/bd7/bd7cfccfececba1ec2b97a120a40373f.jpg"
        },
        {
          "id": 66,
          "name": "Medieval",
          "slug": "medieval",
          "language": "eng",
          "games_count": 7646,
          "image_background": "https://media.rawg.io/media/games/c81/c812e158129e00c9b0f096ae8a0bb7d6.jpg"
        },
        {
          "id": 188,
          "name": "Parkour",
          "slug": "parkour",
          "language": "eng",
          "games_count": 3956,
          "image_background": "https://media.rawg.io/media/games/9f1/9f189c639f70f91166df415811a8b525.jpg"
        },
        {
          "id": 278,
          "name": "Assassin",
          "slug": "assassin",
          "language": "eng",
          "games_count": 938,
          "image_background": "https://media.rawg.io/media/games/c35/c354856af9151dc63844be4f9843d2c2.jpg"
        },
        {
          "id": 42440,
          "name": "Ассассины",
          "slug": "assassiny",
          "language": "rus",
          "games_count": 456,
          "image_background": "https://media.rawg.io/media/games/4e6/4e6e8e7f50c237d76f38f3c885dae3d2.jpg"
        },
        {
          "id": 291,
          "name": "Conspiracy",
          "slug": "conspiracy",
          "language": "eng",
          "games_count": 978,
          "image_background": "https://media.rawg.io/media/screenshots/ca0/ca06700d8184f451b99396c23b4ffbe4.jpg"
        },
        {
          "id": 42641,
          "name": "Заговор",
          "slug": "zagovor",
          "language": "rus",
          "games_count": 732,
          "image_background": "https://media.rawg.io/media/screenshots/5f0/5f00e2338ab8fa6c48d05d4a2bb9dc60.jpg"
        },
        {
          "id": 42689,
          "name": "Рим",
          "slug": "rim",
          "language": "rus",
          "games_count": 180,
          "image_background": "https://media.rawg.io/media/screenshots/949/949a970eaf4304dfcbe33c29f77a01ef.jpg"
        },
        {
          "id": 292,
          "name": "Rome",
          "slug": "rome",
          "language": "eng",
          "games_count": 234,
          "image_background": "https://media.rawg.io/media/screenshots/dfc/dfc88887160d34d7c8d3e3acdc2ac491.jpg"
        }
      ],
      "esrb_rating": {
        "id": 4,
        "name": "Mature",
        "slug": "mature",
        "name_en": "Mature",
        "name_ru": "С 17 лет"
      },
      "user_game": null,
      "reviews_count": 1711,
      "saturated_color": "0f0f0f",
      "dominant_color": "0f0f0f",
      "short_screenshots": [
        {
          "id": -1,
          "image": "https://media.rawg.io/media/games/116/116b93c6876a361a96b2eee3ee58ab13.jpg"
        },
        {
          "id": 76420,
          "image": "https://media.rawg.io/media/screenshots/0d2/0d22156635a002c37ce9bf7d2769a6ee.jpg"
        },
        {
          "id": 76421,
          "image": "https://media.rawg.io/media/screenshots/99b/99b3beb99beb663e807b959d2e310832.jpg"
        },
        {
          "id": 76422,
          "image": "https://media.rawg.io/media/screenshots/ba1/ba178bf7bf726331a168427c1b6085cd.jpg"
        },
        {
          "id": 76423,
          "image": "https://media.rawg.io/media/screenshots/2e5/2e5f45b6e46a0425e305ce98c4739fae.jpg"
        },
        {
          "id": 76424,
          "image": "https://media.rawg.io/media/screenshots/c65/c659f0917ca7082c71ba824e7d34b37c.jpg"
        },
        {
          "id": 76425,
          "image": "https://media.rawg.io/media/screenshots/60f/60ff8d39c22d907bda1165bc2b92bfc5.jpg"
        }
      ],
      "parent_platforms": [
        {
          "platform": {
            "id": 1,
            "name": "PC",
            "slug": "pc"
          }
        },
        {
          "platform": {
            "id": 2,
            "name": "PlayStation",
            "slug": "playstation"
          }
        },
        {
          "platform": {
            "id": 3,
            "name": "Xbox",
            "slug": "xbox"
          }
        },
        {
          "platform": {
            "id": 5,
            "name": "Apple Macintosh",
            "slug": "mac"
          }
        }
      ],
      "genres": [
        {
          "id": 4,
          "name": "Action",
          "slug": "action"
        }
      ]
    },
    {
      "slug": "assassins-creed-ii",
      "name": "Assassin's Creed II",
      "playtime": 14,
      "platforms": [
        {
          "platform": {
            "id": 4,
            "name": "PC",
            "slug": "pc"
          }
        },
        {
          "platform": {
            "id": 1,
            "name": "Xbox One",
            "slug": "xbox-one"
          }
        },
        {
          "platform": {
            "id": 18,
            "name": "PlayStation 4",
            "slug": "playstation4"
          }
        },
        {
          "platform": {
            "id": 5,
            "name": "macOS",
            "slug": "macos"
          }
        },
        {
          "platform": {
            "id": 14,
            "name": "Xbox 360",
            "slug": "xbox360"
          }
        },
        {
          "platform": {
            "id": 16,
            "name": "PlayStation 3",
            "slug": "playstation3"
          }
        }
      ],
      "stores": [
        {
          "store": {
            "id": 1,
            "name": "Steam",
            "slug": "steam"
          }
        },
        {
          "store": {
            "id": 2,
            "name": "Xbox Store",
            "slug": "xbox-store"
          }
        },
        {
          "store": {
            "id": 7,
            "name": "Xbox 360 Store",
            "slug": "xbox360"
          }
        }
      ],
      "released": "2009-11-17",
      "tba": false,
      "background_image": "https://media.rawg.io/media/games/1be/1bed7fae69d1004c09dfe1101d5a3a94.jpg",
      "rating": 4.42,
      "rating_top": 5,
      "ratings": [
        {
          "id": 5,
          "title": "exceptional",
          "count": 1603,
          "percent": 54.9
        },
        {
          "id": 4,
          "title": "recommended",
          "count": 1080,
          "percent": 36.99
        },
        {
          "id": 3,
          "title": "meh",
          "count": 171,
          "percent": 5.86
        },
        {
          "id": 1,
          "title": "skip",
          "count": 66,
          "percent": 2.26
        }
      ],
      "ratings_count": 2896,
      "reviews_text_count": 17,
      "added": 8033,
      "added_by_status": {
        "yet": 224,
        "owned": 3635,
        "beaten": 3564,
        "toplay": 175,
        "dropped": 384,
        "playing": 51
      },
      "metacritic": 89,
      "suggestions_count": 635,
      "updated": "2025-07-31T19:25:34",
      "id": 28568,
      "score": "53.38249",
      "clip": null,
      "tags": [
        {
          "id": 278,
          "name": "Assassin",
          "slug": "assassin",
          "language": "eng",
          "games_count": 938,
          "image_background": "https://media.rawg.io/media/games/c35/c354856af9151dc63844be4f9843d2c2.jpg"
        },
        {
          "id": 1309,
          "name": "hero",
          "slug": "hero",
          "language": "eng",
          "games_count": 4858,
          "image_background": "https://media.rawg.io/media/games/55a/55a685051caa3d478836fa7c1d074694.jpg"
        },
        {
          "id": 835,
          "name": "Swords",
          "slug": "swords",
          "language": "eng",
          "games_count": 1461,
          "image_background": "https://media.rawg.io/media/screenshots/86a/86a1ca92bee366c36e30aad87c0604ee.jpg"
        }
      ],
      "esrb_rating": {
        "id": 4,
        "name": "Mature",
        "slug": "mature",
        "name_en": "Mature",
        "name_ru": "С 17 лет"
      },
      "user_game": null,
      "reviews_count": 2920,
      "saturated_color": "0f0f0f",
      "dominant_color": "0f0f0f",
      "short_screenshots": [
        {
          "id": -1,
          "image": "https://media.rawg.io/media/games/1be/1bed7fae69d1004c09dfe1101d5a3a94.jpg"
        },
        {
          "id": 526178,
          "image": "https://media.rawg.io/media/screenshots/e73/e731183e3f545daa3283ca29f4f254cc.jpg"
        },
        {
          "id": 526179,
          "image": "https://media.rawg.io/media/screenshots/fe9/fe9db29056872c1699dde43155c16329.jpg"
        },
        {
          "id": 526180,
          "image": "https://media.rawg.io/media/screenshots/65b/65bced397e2946d6880238c6f9ffddb4_ai30aa1.jpg"
        },
        {
          "id": 526181,
          "image": "https://media.rawg.io/media/screenshots/96e/96e16a1458f1606b2df4d1a623f62b61.jpg"
        },
        {
          "id": 526182,
          "image": "https://media.rawg.io/media/screenshots/447/4470e0dace64fe81b0e1a8bafc0f4686.jpg"
        },
        {
          "id": 526183,
          "image": "https://media.rawg.io/media/screenshots/02b/02bfb9bd79a284db6c9acf5fd30fb8d3.jpg"
        }
      ],
      "parent_platforms": [
        {
          "platform": {
            "id": 1,
            "name": "PC",
            "slug": "pc"
          }
        },
        {
          "platform": {
            "id": 2,
            "name": "PlayStation",
            "slug": "playstation"
          }
        },
        {
          "platform": {
            "id": 3,
            "name": "Xbox",
            "slug": "xbox"
          }
        },
        {
          "platform": {
            "id": 5,
            "name": "Apple Macintosh",
            "slug": "mac"
          }
        }
      ],
      "genres": [
        {
          "id": 4,
          "name": "Action",
          "slug": "action"
        }
      ]
    },
    {
      "slug": "assassins-creed-chronicles-india-2",
      "name": "Assassin’s Creed Chronicles: India",
      "playtime": 3,
      "platforms": [
        {
          "platform": {
            "id": 4,
            "name": "PC",
            "slug": "pc"
          }
        },
        {
          "platform": {
            "id": 1,
            "name": "Xbox One",
            "slug": "xbox-one"
          }
        },
        {
          "platform": {
            "id": 18,
            "name": "PlayStation 4",
            "slug": "playstation4"
          }
        },
        {
          "platform": {
            "id": 19,
            "name": "PS Vita",
            "slug": "ps-vita"
          }
        }
      ],
      "stores": [
        {
          "store": {
            "id": 1,
            "name": "Steam",
            "slug": "steam"
          }
        },
        {
          "store": {
            "id": 3,
            "name": "PlayStation Store",
            "slug": "playstation-store"
          }
        },
        {
          "store": {
            "id": 2,
            "name": "Xbox Store",
            "slug": "xbox-store"
          }
        },
        {
          "store": {
            "id": 11,
            "name": "Epic Games",
            "slug": "epic-games"
          }
        }
      ],
      "released": "2016-01-12",
      "tba": false,
      "background_image": "https://media.rawg.io/media/games/e99/e9969ab76756fe041aaa72cdeb768649.jpg",
      "rating": 3.12,
      "rating_top": 4,
      "ratings": [
        {
          "id": 4,
          "title": "recommended",
          "count": 54,
          "percent": 42.19
        },
        {
          "id": 3,
          "title": "meh",
          "count": 47,
          "percent": 36.72
        },
        {
          "id": 1,
          "title": "skip",
          "count": 23,
          "percent": 17.97
        },
        {
          "id": 5,
          "title": "exceptional",
          "count": 4,
          "percent": 3.12
        }
      ],
      "ratings_count": 124,
      "reviews_text_count": 4,
      "added": 825,
      "added_by_status": {
        "yet": 134,
        "owned": 482,
        "beaten": 116,
        "toplay": 49,
        "dropped": 39,
        "playing": 5
      },
      "metacritic": 63,
      "suggestions_count": 590,
      "updated": "2025-07-27T18:56:39",
      "id": 19274,
      "score": "52.29052",
      "clip": null,
      "tags": [
        {
          "id": 31,
          "name": "Singleplayer",
          "slug": "singleplayer",
          "language": "eng",
          "games_count": 243828,
          "image_background": "https://media.rawg.io/media/games/f46/f466571d536f2e3ea9e815ad17177501.jpg"
        },
        {
          "id": 42396,
          "name": "Для одного игрока",
          "slug": "dlia-odnogo-igroka",
          "language": "rus",
          "games_count": 65063,
          "image_background": "https://media.rawg.io/media/games/511/5118aff5091cb3efec399c808f8c598f.jpg"
        },
        {
          "id": 42417,
          "name": "Экшен",
          "slug": "ekshen",
          "language": "rus",
          "games_count": 47885,
          "image_background": "https://media.rawg.io/media/games/7fa/7fa0b586293c5861ee32490e953a4996.jpg"
        },
        {
          "id": 42392,
          "name": "Приключение",
          "slug": "prikliuchenie",
          "language": "rus",
          "games_count": 46267,
          "image_background": "https://media.rawg.io/media/games/26d/26d4437715bee60138dab4a7c8c59c92.jpg"
        },
        {
          "id": 45,
          "name": "2D",
          "slug": "2d",
          "language": "eng",
          "games_count": 204487,
          "image_background": "https://media.rawg.io/media/games/f99/f9979698c43fd84c3ab69280576dd3af.jpg"
        },
        {
          "id": 40845,
          "name": "Partial Controller Support",
          "slug": "partial-controller-support",
          "language": "eng",
          "games_count": 13444,
          "image_background": "https://media.rawg.io/media/games/2ad/2ad87a4a69b1104f02435c14c5196095.jpg"
        },
        {
          "id": 42463,
          "name": "Платформер",
          "slug": "platformer-2",
          "language": "rus",
          "games_count": 10635,
          "image_background": "https://media.rawg.io/media/games/8d4/8d46786ca86b1d95f3dc7e700e2dc4dd.jpg"
        },
        {
          "id": 15,
          "name": "Stealth",
          "slug": "stealth",
          "language": "eng",
          "games_count": 6913,
          "image_background": "https://media.rawg.io/media/games/7ac/7aca7ccf0e70cd0974cb899ab9e5158e.jpg"
        },
        {
          "id": 42439,
          "name": "Стелс",
          "slug": "stels",
          "language": "rus",
          "games_count": 2771,
          "image_background": "https://media.rawg.io/media/games/1bd/1bd2657b81eb0c99338120ad444b24ff.jpg"
        },
        {
          "id": 42469,
          "name": "Вид сбоку",
          "slug": "vid-sboku",
          "language": "rus",
          "games_count": 5124,
          "image_background": "https://media.rawg.io/media/games/283/283e7e600366b0da7021883d27159b27.jpg"
        },
        {
          "id": 42643,
          "name": "Паркур",
          "slug": "parkur-2",
          "language": "rus",
          "games_count": 1637,
          "image_background": "https://media.rawg.io/media/games/bd7/bd7cfccfececba1ec2b97a120a40373f.jpg"
        },
        {
          "id": 188,
          "name": "Parkour",
          "slug": "parkour",
          "language": "eng",
          "games_count": 3956,
          "image_background": "https://media.rawg.io/media/games/9f1/9f189c639f70f91166df415811a8b525.jpg"
        },
        {
          "id": 42667,
          "name": "Псевдотрёхмерность",
          "slug": "psevdotriokhmernost",
          "language": "rus",
          "games_count": 2627,
          "image_background": "https://media.rawg.io/media/games/ba0/ba006ef12175ad4773e5964c320099c4.jpg"
        },
        {
          "id": 278,
          "name": "Assassin",
          "slug": "assassin",
          "language": "eng",
          "games_count": 938,
          "image_background": "https://media.rawg.io/media/games/c35/c354856af9151dc63844be4f9843d2c2.jpg"
        },
        {
          "id": 42440,
          "name": "Ассассины",
          "slug": "assassiny",
          "language": "rus",
          "games_count": 456,
          "image_background": "https://media.rawg.io/media/games/4e6/4e6e8e7f50c237d76f38f3c885dae3d2.jpg"
        },
        {
          "id": 116,
          "name": "2.5D",
          "slug": "25d",
          "language": "eng",
          "games_count": 2712,
          "image_background": "https://media.rawg.io/media/games/8a0/8a02f84a5916ede2f923b88d5f8217ba.jpg"
        }
      ],
      "esrb_rating": {
        "id": 3,
        "name": "Teen",
        "slug": "teen",
        "name_en": "Teen",
        "name_ru": "С 13 лет"
      },
      "user_game": null,
      "reviews_count": 128,
      "saturated_color": "0f0f0f",
      "dominant_color": "0f0f0f",
      "short_screenshots": [
        {
          "id": -1,
          "image": "https://media.rawg.io/media/games/e99/e9969ab76756fe041aaa72cdeb768649.jpg"
        },
        {
          "id": 179477,
          "image": "https://media.rawg.io/media/screenshots/270/2705efbd0c3ff98bf61589a4418e2b8d.jpg"
        },
        {
          "id": 179478,
          "image": "https://media.rawg.io/media/screenshots/000/00042367dff2429b53975165cf2b2e2e.jpg"
        },
        {
          "id": 179479,
          "image": "https://media.rawg.io/media/screenshots/3f5/3f54967f3adbe3a0db6646c404aeb4f4.jpg"
        },
        {
          "id": 179480,
          "image": "https://media.rawg.io/media/screenshots/436/4369d4a34dcb425a1b7fd98bd73c598e.jpg"
        },
        {
          "id": 179481,
          "image": "https://media.rawg.io/media/screenshots/e67/e67c61fe1b91edaa025f2a579281c232.jpg"
        },
        {
          "id": 179482,
          "image": "https://media.rawg.io/media/screenshots/0f6/0f6f6f5550b4d24d735b8307095e1751.jpg"
        }
      ],
      "parent_platforms": [
        {
          "platform": {
            "id": 1,
            "name": "PC",
            "slug": "pc"
          }
        },
        {
          "platform": {
            "id": 2,
            "name": "PlayStation",
            "slug": "playstation"
          }
        },
        {
          "platform": {
            "id": 3,
            "name": "Xbox",
            "slug": "xbox"
          }
        }
      ],
      "genres": [
        {
          "id": 3,
          "name": "Adventure",
          "slug": "adventure"
        },
        {
          "id": 4,
          "name": "Action",
          "slug": "action"
        }
      ]
    },
    {
      "slug": "assassins-creed-chronicles-china-2",
      "name": "Assassin’s Creed Chronicles: China",
      "playtime": 4,
      "platforms": [
        {
          "platform": {
            "id": 4,
            "name": "PC",
            "slug": "pc"
          }
        },
        {
          "platform": {
            "id": 1,
            "name": "Xbox One",
            "slug": "xbox-one"
          }
        },
        {
          "platform": {
            "id": 18,
            "name": "PlayStation 4",
            "slug": "playstation4"
          }
        },
        {
          "platform": {
            "id": 19,
            "name": "PS Vita",
            "slug": "ps-vita"
          }
        }
      ],
      "stores": [
        {
          "store": {
            "id": 1,
            "name": "Steam",
            "slug": "steam"
          }
        },
        {
          "store": {
            "id": 3,
            "name": "PlayStation Store",
            "slug": "playstation-store"
          }
        },
        {
          "store": {
            "id": 2,
            "name": "Xbox Store",
            "slug": "xbox-store"
          }
        },
        {
          "store": {
            "id": 11,
            "name": "Epic Games",
            "slug": "epic-games"
          }
        }
      ],
      "released": "2015-04-21",
      "tba": false,
      "background_image": "https://media.rawg.io/media/games/c5a/c5a362394197a5aa0cb8371a62154c8b.jpg",
      "rating": 3.11,
      "rating_top": 3,
      "ratings": [
        {
          "id": 3,
          "title": "meh",
          "count": 131,
          "percent": 45.8
        },
        {
          "id": 4,
          "title": "recommended",
          "count": 91,
          "percent": 31.82
        },
        {
          "id": 1,
          "title": "skip",
          "count": 47,
          "percent": 16.43
        },
        {
          "id": 5,
          "title": "exceptional",
          "count": 17,
          "percent": 5.94
        }
      ],
      "ratings_count": 281,
      "reviews_text_count": 4,
      "added": 1615,
      "added_by_status": {
        "yet": 181,
        "owned": 1025,
        "beaten": 193,
        "toplay": 57,
        "dropped": 144,
        "playing": 15
      },
      "metacritic": 68,
      "suggestions_count": 428,
      "updated": "2025-07-27T18:56:29",
      "id": 20180,
      "score": "52.26821",
      "clip": null,
      "tags": [
        {
          "id": 31,
          "name": "Singleplayer",
          "slug": "singleplayer",
          "language": "eng",
          "games_count": 243431,
          "image_background": "https://media.rawg.io/media/games/bc0/bc06a29ceac58652b684deefe7d56099.jpg"
        },
        {
          "id": 42396,
          "name": "Для одного игрока",
          "slug": "dlia-odnogo-igroka",
          "language": "rus",
          "games_count": 64755,
          "image_background": "https://media.rawg.io/media/games/7cf/7cfc9220b401b7a300e409e539c9afd5.jpg"
        },
        {
          "id": 42417,
          "name": "Экшен",
          "slug": "ekshen",
          "language": "rus",
          "games_count": 47736,
          "image_background": "https://media.rawg.io/media/games/7cf/7cfc9220b401b7a300e409e539c9afd5.jpg"
        },
        {
          "id": 42392,
          "name": "Приключение",
          "slug": "prikliuchenie",
          "language": "rus",
          "games_count": 46088,
          "image_background": "https://media.rawg.io/media/games/ee3/ee3e10193aafc3230ba1cae426967d10.jpg"
        },
        {
          "id": 42442,
          "name": "Открытый мир",
          "slug": "otkrytyi-mir",
          "language": "rus",
          "games_count": 6977,
          "image_background": "https://media.rawg.io/media/games/49c/49c3dfa4ce2f6f140cc4825868e858cb.jpg"
        },
        {
          "id": 36,
          "name": "Open World",
          "slug": "open-world",
          "language": "eng",
          "games_count": 8790,
          "image_background": "https://media.rawg.io/media/games/9aa/9aa42d16d425fa6f179fc9dc2f763647.jpg"
        },
        {
          "id": 42399,
          "name": "Казуальная игра",
          "slug": "kazualnaia-igra",
          "language": "rus",
          "games_count": 51098,
          "image_background": "https://media.rawg.io/media/games/d82/d82990b9c67ba0d2d09d4e6fa88885a7.jpg"
        },
        {
          "id": 45,
          "name": "2D",
          "slug": "2d",
          "language": "eng",
          "games_count": 204316,
          "image_background": "https://media.rawg.io/media/games/4cf/4cfc6b7f1850590a4634b08bfab308ab.jpg"
        },
        {
          "id": 40845,
          "name": "Partial Controller Support",
          "slug": "partial-controller-support",
          "language": "eng",
          "games_count": 13409,
          "image_background": "https://media.rawg.io/media/games/095/0953bf01cd4e4dd204aba85489ac9868.jpg"
        },
        {
          "id": 189,
          "name": "Female Protagonist",
          "slug": "female-protagonist",
          "language": "eng",
          "games_count": 14673,
          "image_background": "https://media.rawg.io/media/games/d69/d69810315bd7e226ea2d21f9156af629.jpg"
        },
        {
          "id": 42404,
          "name": "Женщина-протагонист",
          "slug": "zhenshchina-protagonist",
          "language": "rus",
          "games_count": 2413,
          "image_background": "https://media.rawg.io/media/games/424/424facd40f4eb1f2794fe4b4bb28a277.jpg"
        },
        {
          "id": 42463,
          "name": "Платформер",
          "slug": "platformer-2",
          "language": "rus",
          "games_count": 10599,
          "image_background": "https://media.rawg.io/media/games/c89/c89ca70716080733d03724277df2c6c7.jpg"
        },
        {
          "id": 15,
          "name": "Stealth",
          "slug": "stealth",
          "language": "eng",
          "games_count": 6904,
          "image_background": "https://media.rawg.io/media/games/f6b/f6bed028b02369d4cab548f4f9337e81.jpg"
        },
        {
          "id": 42439,
          "name": "Стелс",
          "slug": "stels",
          "language": "rus",
          "games_count": 2762,
          "image_background": "https://media.rawg.io/media/games/7f6/7f6cd70ba2ad57053b4847c13569f2d8.jpg"
        },
        {
          "id": 42469,
          "name": "Вид сбоку",
          "slug": "vid-sboku",
          "language": "rus",
          "games_count": 5105,
          "image_background": "https://media.rawg.io/media/games/23a/23acbd56da0c30bca0227967a5720c96.jpg"
        },
        {
          "id": 113,
          "name": "Side Scroller",
          "slug": "side-scroller",
          "language": "eng",
          "games_count": 11484,
          "image_background": "https://media.rawg.io/media/games/9cc/9cc11e2e81403186c7fa9c00c143d6e4.jpg"
        },
        {
          "id": 89,
          "name": "Historical",
          "slug": "historical",
          "language": "eng",
          "games_count": 3781,
          "image_background": "https://media.rawg.io/media/games/849/849414b978db37d4563ff9e4b0d3a787.jpg"
        },
        {
          "id": 42403,
          "name": "История",
          "slug": "istoriia",
          "language": "rus",
          "games_count": 940,
          "image_background": "https://media.rawg.io/media/games/bff/bff7d82316cddea9541261a045ba008a.jpg"
        },
        {
          "id": 42643,
          "name": "Паркур",
          "slug": "parkur-2",
          "language": "rus",
          "games_count": 1622,
          "image_background": "https://media.rawg.io/media/games/336/336c6bd63d83cf8e59937ab8895d1240.jpg"
        },
        {
          "id": 188,
          "name": "Parkour",
          "slug": "parkour",
          "language": "eng",
          "games_count": 3941,
          "image_background": "https://media.rawg.io/media/games/193/19390fa5e75e9048b22c9a736cf9992f.jpg"
        },
        {
          "id": 42494,
          "name": "3D-платформер",
          "slug": "3d-platformer-2",
          "language": "rus",
          "games_count": 5654,
          "image_background": "https://media.rawg.io/media/games/5aa/5aa4c12a53bc5f606bf8d92461ec747d.jpg"
        },
        {
          "id": 42667,
          "name": "Псевдотрёхмерность",
          "slug": "psevdotriokhmernost",
          "language": "rus",
          "games_count": 2627,
          "image_background": "https://media.rawg.io/media/games/ba0/ba006ef12175ad4773e5964c320099c4.jpg"
        },
        {
          "id": 278,
          "name": "Assassin",
          "slug": "assassin",
          "language": "eng",
          "games_count": 934,
          "image_background": "https://media.rawg.io/media/games/3f6/3f6a397ec36acfcc18bb6ab3414c7658.jpg"
        },
        {
          "id": 42440,
          "name": "Ассассины",
          "slug": "assassiny",
          "language": "rus",
          "games_count": 452,
          "image_background": "https://media.rawg.io/media/games/275/2759da6fcaa8f81f21800926168c85f6.jpg"
        },
        {
          "id": 116,
          "name": "2.5D",
          "slug": "25d",
          "language": "eng",
          "games_count": 2701,
          "image_background": "https://media.rawg.io/media/games/04a/04a7e7e185fb51493bdcbe1693a8b3dc.jpg"
        }
      ],
      "esrb_rating": {
        "id": 3,
        "name": "Teen",
        "slug": "teen",
        "name_en": "Teen",
        "name_ru": "С 13 лет"
      },
      "user_game": null,
      "reviews_count": 286,
      "saturated_color": "0f0f0f",
      "dominant_color": "0f0f0f",
      "short_screenshots": [
        {
          "id": -1,
          "image": "https://media.rawg.io/media/games/c5a/c5a362394197a5aa0cb8371a62154c8b.jpg"
        },
        {
          "id": 190735,
          "image": "https://media.rawg.io/media/screenshots/569/569454df51319779ee25b9ab986ddd36.jpg"
        },
        {
          "id": 190736,
          "image": "https://media.rawg.io/media/screenshots/801/801969642a499f6d7f547dd6a94a2106.jpg"
        },
        {
          "id": 190737,
          "image": "https://media.rawg.io/media/screenshots/46d/46d001bcc86ca0d10727f4588555f510.jpg"
        },
        {
          "id": 190738,
          "image": "https://media.rawg.io/media/screenshots/e0a/e0ab2a7f8b5ce90c72d790cb82ab8cfa.jpg"
        },
        {
          "id": 190739,
          "image": "https://media.rawg.io/media/screenshots/cbe/cbefab25bbcfdf7667bed10b492eeb9b.jpg"
        },
        {
          "id": 190740,
          "image": "https://media.rawg.io/media/screenshots/b25/b25ced568ae3b17c55fd342855fe4762.jpg"
        }
      ],
      "parent_platforms": [
        {
          "platform": {
            "id": 1,
            "name": "PC",
            "slug": "pc"
          }
        },
        {
          "platform": {
            "id": 2,
            "name": "PlayStation",
            "slug": "playstation"
          }
        },
        {
          "platform": {
            "id": 3,
            "name": "Xbox",
            "slug": "xbox"
          }
        }
      ],
      "genres": [
        {
          "id": 3,
          "name": "Adventure",
          "slug": "adventure"
        },
        {
          "id": 4,
          "name": "Action",
          "slug": "action"
        }
      ]
    },
    {
      "slug": "assassins-creed-chronicles-russia-2",
      "name": "Assassin’s Creed Chronicles: Russia",
      "playtime": 3,
      "platforms": [
        {
          "platform": {
            "id": 4,
            "name": "PC",
            "slug": "pc"
          }
        },
        {
          "platform": {
            "id": 1,
            "name": "Xbox One",
            "slug": "xbox-one"
          }
        },
        {
          "platform": {
            "id": 18,
            "name": "PlayStation 4",
            "slug": "playstation4"
          }
        },
        {
          "platform": {
            "id": 19,
            "name": "PS Vita",
            "slug": "ps-vita"
          }
        }
      ],
      "stores": [
        {
          "store": {
            "id": 1,
            "name": "Steam",
            "slug": "steam"
          }
        },
        {
          "store": {
            "id": 3,
            "name": "PlayStation Store",
            "slug": "playstation-store"
          }
        },
        {
          "store": {
            "id": 2,
            "name": "Xbox Store",
            "slug": "xbox-store"
          }
        },
        {
          "store": {
            "id": 11,
            "name": "Epic Games",
            "slug": "epic-games"
          }
        }
      ],
      "released": "2016-02-09",
      "tba": false,
      "background_image": "https://media.rawg.io/media/games/cd9/cd9a44c7a80b8319a84ea737e71cb592.jpg",
      "rating": 3.03,
      "rating_top": 3,
      "ratings": [
        {
          "id": 3,
          "title": "meh",
          "count": 45,
          "percent": 38.46
        },
        {
          "id": 4,
          "title": "recommended",
          "count": 40,
          "percent": 34.19
        },
        {
          "id": 1,
          "title": "skip",
          "count": 25,
          "percent": 21.37
        },
        {
          "id": 5,
          "title": "exceptional",
          "count": 7,
          "percent": 5.98
        }
      ],
      "ratings_count": 115,
      "reviews_text_count": 2,
      "added": 793,
      "added_by_status": {
        "yet": 130,
        "owned": 460,
        "beaten": 100,
        "toplay": 53,
        "dropped": 44,
        "playing": 6
      },
      "metacritic": 58,
      "suggestions_count": 515,
      "updated": "2025-07-27T18:56:39",
      "id": 19338,
      "score": "52.26821",
      "clip": null,
      "tags": [
        {
          "id": 31,
          "name": "Singleplayer",
          "slug": "singleplayer",
          "language": "eng",
          "games_count": 243431,
          "image_background": "https://media.rawg.io/media/games/bc0/bc06a29ceac58652b684deefe7d56099.jpg"
        },
        {
          "id": 42396,
          "name": "Для одного игрока",
          "slug": "dlia-odnogo-igroka",
          "language": "rus",
          "games_count": 64755,
          "image_background": "https://media.rawg.io/media/games/7cf/7cfc9220b401b7a300e409e539c9afd5.jpg"
        },
        {
          "id": 42417,
          "name": "Экшен",
          "slug": "ekshen",
          "language": "rus",
          "games_count": 47736,
          "image_background": "https://media.rawg.io/media/games/7cf/7cfc9220b401b7a300e409e539c9afd5.jpg"
        },
        {
          "id": 42392,
          "name": "Приключение",
          "slug": "prikliuchenie",
          "language": "rus",
          "games_count": 46088,
          "image_background": "https://media.rawg.io/media/games/ee3/ee3e10193aafc3230ba1cae426967d10.jpg"
        },
        {
          "id": 40845,
          "name": "Partial Controller Support",
          "slug": "partial-controller-support",
          "language": "eng",
          "games_count": 13409,
          "image_background": "https://media.rawg.io/media/games/095/0953bf01cd4e4dd204aba85489ac9868.jpg"
        },
        {
          "id": 42463,
          "name": "Платформер",
          "slug": "platformer-2",
          "language": "rus",
          "games_count": 10599,
          "image_background": "https://media.rawg.io/media/games/c89/c89ca70716080733d03724277df2c6c7.jpg"
        },
        {
          "id": 15,
          "name": "Stealth",
          "slug": "stealth",
          "language": "eng",
          "games_count": 6904,
          "image_background": "https://media.rawg.io/media/games/f6b/f6bed028b02369d4cab548f4f9337e81.jpg"
        },
        {
          "id": 42439,
          "name": "Стелс",
          "slug": "stels",
          "language": "rus",
          "games_count": 2762,
          "image_background": "https://media.rawg.io/media/games/7f6/7f6cd70ba2ad57053b4847c13569f2d8.jpg"
        },
        {
          "id": 42643,
          "name": "Паркур",
          "slug": "parkur-2",
          "language": "rus",
          "games_count": 1622,
          "image_background": "https://media.rawg.io/media/games/336/336c6bd63d83cf8e59937ab8895d1240.jpg"
        },
        {
          "id": 188,
          "name": "Parkour",
          "slug": "parkour",
          "language": "eng",
          "games_count": 3941,
          "image_background": "https://media.rawg.io/media/games/193/19390fa5e75e9048b22c9a736cf9992f.jpg"
        },
        {
          "id": 42667,
          "name": "Псевдотрёхмерность",
          "slug": "psevdotriokhmernost",
          "language": "rus",
          "games_count": 2627,
          "image_background": "https://media.rawg.io/media/games/ba0/ba006ef12175ad4773e5964c320099c4.jpg"
        },
        {
          "id": 278,
          "name": "Assassin",
          "slug": "assassin",
          "language": "eng",
          "games_count": 934,
          "image_background": "https://media.rawg.io/media/games/3f6/3f6a397ec36acfcc18bb6ab3414c7658.jpg"
        },
        {
          "id": 42440,
          "name": "Ассассины",
          "slug": "assassiny",
          "language": "rus",
          "games_count": 452,
          "image_background": "https://media.rawg.io/media/games/275/2759da6fcaa8f81f21800926168c85f6.jpg"
        },
        {
          "id": 116,
          "name": "2.5D",
          "slug": "25d",
          "language": "eng",
          "games_count": 2701,
          "image_background": "https://media.rawg.io/media/games/04a/04a7e7e185fb51493bdcbe1693a8b3dc.jpg"
        }
      ],
      "esrb_rating": {
        "id": 3,
        "name": "Teen",
        "slug": "teen",
        "name_en": "Teen",
        "name_ru": "С 13 лет"
      },
      "user_game": null,
      "reviews_count": 117,
      "saturated_color": "0f0f0f",
      "dominant_color": "0f0f0f",
      "short_screenshots": [
        {
          "id": -1,
          "image": "https://media.rawg.io/media/games/cd9/cd9a44c7a80b8319a84ea737e71cb592.jpg"
        },
        {
          "id": 180199,
          "image": "https://media.rawg.io/media/screenshots/565/56534595d4c19edb31ed6a56ecb43d03.jpg"
        },
        {
          "id": 180200,
          "image": "https://media.rawg.io/media/screenshots/8aa/8aab0c89fe3a7ddd6798db0ac7ef1275.jpg"
        },
        {
          "id": 180201,
          "image": "https://media.rawg.io/media/screenshots/06a/06a3fb5267cbbc0c6b869259608812dd.jpg"
        },
        {
          "id": 180202,
          "image": "https://media.rawg.io/media/screenshots/154/154dbabd61bf305dcbbb1fce1af365c1.jpg"
        },
        {
          "id": 180203,
          "image": "https://media.rawg.io/media/screenshots/c3d/c3d21e4fbcb94c3891981fd66df62c77.jpg"
        },
        {
          "id": 180204,
          "image": "https://media.rawg.io/media/screenshots/bb8/bb8445dc01655495a5a2ea64bd33212c.jpg"
        }
      ],
      "parent_platforms": [
        {
          "platform": {
            "id": 1,
            "name": "PC",
            "slug": "pc"
          }
        },
        {
          "platform": {
            "id": 2,
            "name": "PlayStation",
            "slug": "playstation"
          }
        },
        {
          "platform": {
            "id": 3,
            "name": "Xbox",
            "slug": "xbox"
          }
        }
      ],
      "genres": [
        {
          "id": 83,
          "name": "Platformer",
          "slug": "platformer"
        },
        {
          "id": 3,
          "name": "Adventure",
          "slug": "adventure"
        },
        {
          "id": 4,
          "name": "Action",
          "slug": "action"
        }
      ]
    },
    {
      "slug": "assassins-creed-rogue-remastered-2",
      "name": "Assassin’s Creed Rogue Remastered",
      "playtime": 0,
      "platforms": [
        {
          "platform": {
            "id": 1,
            "name": "Xbox One",
            "slug": "xbox-one"
          }
        },
        {
          "platform": {
            "id": 18,
            "name": "PlayStation 4",
            "slug": "playstation4"
          }
        }
      ],
      "stores": [
        {
          "store": {
            "id": 3,
            "name": "PlayStation Store",
            "slug": "playstation-store"
          }
        },
        {
          "store": {
            "id": 2,
            "name": "Xbox Store",
            "slug": "xbox-store"
          }
        }
      ],
      "released": "2018-03-20",
      "tba": false,
      "background_image": "https://media.rawg.io/media/games/1ef/1efc680174828ac07312dbb1f6265ba9.jpg",
      "rating": 3.69,
      "rating_top": 4,
      "ratings": [
        {
          "id": 4,
          "title": "recommended",
          "count": 74,
          "percent": 62.18
        },
        {
          "id": 3,
          "title": "meh",
          "count": 25,
          "percent": 21.01
        },
        {
          "id": 5,
          "title": "exceptional",
          "count": 12,
          "percent": 10.08
        },
        {
          "id": 1,
          "title": "skip",
          "count": 8,
          "percent": 6.72
        }
      ],
      "ratings_count": 116,
      "reviews_text_count": 3,
      "added": 564,
      "added_by_status": {
        "yet": 39,
        "owned": 337,
        "beaten": 106,
        "toplay": 52,
        "dropped": 21,
        "playing": 9
      },
      "metacritic": 71,
      "suggestions_count": 283,
      "updated": "2025-06-12T14:27:26",
      "id": 57885,
      "score": "50.889565",
      "clip": null,
      "tags": [
        {
          "id": 118,
          "name": "Story Rich",
          "slug": "story-rich",
          "language": "eng",
          "games_count": 25656,
          "image_background": "https://media.rawg.io/media/games/7fa/7fa0b586293c5861ee32490e953a4996.jpg"
        },
        {
          "id": 36,
          "name": "Open World",
          "slug": "open-world",
          "language": "eng",
          "games_count": 8790,
          "image_background": "https://media.rawg.io/media/games/9aa/9aa42d16d425fa6f179fc9dc2f763647.jpg"
        },
        {
          "id": 15,
          "name": "Stealth",
          "slug": "stealth",
          "language": "eng",
          "games_count": 6904,
          "image_background": "https://media.rawg.io/media/games/f6b/f6bed028b02369d4cab548f4f9337e81.jpg"
        },
        {
          "id": 188,
          "name": "Parkour",
          "slug": "parkour",
          "language": "eng",
          "games_count": 3941,
          "image_background": "https://media.rawg.io/media/games/193/19390fa5e75e9048b22c9a736cf9992f.jpg"
        },
        {
          "id": 278,
          "name": "Assassin",
          "slug": "assassin",
          "language": "eng",
          "games_count": 934,
          "image_background": "https://media.rawg.io/media/games/3f6/3f6a397ec36acfcc18bb6ab3414c7658.jpg"
        },
        {
          "id": 255,
          "name": "Pirates",
          "slug": "pirates",
          "language": "eng",
          "games_count": 2298,
          "image_background": "https://media.rawg.io/media/screenshots/89c/89c786468e50fab24d6859b7edaf91c0.jpg"
        },
        {
          "id": 256,
          "name": "Naval",
          "slug": "naval",
          "language": "eng",
          "games_count": 395,
          "image_background": "https://media.rawg.io/media/screenshots/8d5/8d5a29af32d359d57d196f56876c9639.jpg"
        },
        {
          "id": 257,
          "name": "Sailing",
          "slug": "sailing",
          "language": "eng",
          "games_count": 513,
          "image_background": "https://media.rawg.io/media/screenshots/b49/b491ba691c347d45b4f78119572aa869.jpg"
        }
      ],
      "esrb_rating": {
        "id": 4,
        "name": "Mature",
        "slug": "mature",
        "name_en": "Mature",
        "name_ru": "С 17 лет"
      },
      "user_game": null,
      "reviews_count": 119,
      "saturated_color": "0f0f0f",
      "dominant_color": "0f0f0f",
      "short_screenshots": [
        {
          "id": -1,
          "image": "https://media.rawg.io/media/games/1ef/1efc680174828ac07312dbb1f6265ba9.jpg"
        },
        {
          "id": 764939,
          "image": "https://media.rawg.io/media/screenshots/a44/a449fd8056b70ba56d0211359f6d76af.jpg"
        },
        {
          "id": 764941,
          "image": "https://media.rawg.io/media/screenshots/389/389024d87c01c48f5ad173824bbc241b.jpg"
        },
        {
          "id": 764942,
          "image": "https://media.rawg.io/media/screenshots/45f/45fa92f345fa99f5ae545f2d9af7e268_pPYwsJa.jpg"
        },
        {
          "id": 764944,
          "image": "https://media.rawg.io/media/screenshots/1fb/1fb806729afc1e219b154d6599bd2ae1.jpg"
        }
      ],
      "parent_platforms": [
        {
          "platform": {
            "id": 2,
            "name": "PlayStation",
            "slug": "playstation"
          }
        },
        {
          "platform": {
            "id": 3,
            "name": "Xbox",
            "slug": "xbox"
          }
        }
      ],
      "genres": [
        {
          "id": 3,
          "name": "Adventure",
          "slug": "adventure"
        },
        {
          "id": 4,
          "name": "Action",
          "slug": "action"
        }
      ]
    },
    {
      "slug": "assassins-creed-pirates",
      "name": "Assassin's Creed Pirates",
      "playtime": 3,
      "platforms": [
        {
          "platform": {
            "id": 4,
            "name": "PC",
            "slug": "pc"
          }
        },
        {
          "platform": {
            "id": 3,
            "name": "iOS",
            "slug": "ios"
          }
        },
        {
          "platform": {
            "id": 21,
            "name": "Android",
            "slug": "android"
          }
        }
      ],
      "stores": [
        {
          "store": {
            "id": 4,
            "name": "App Store",
            "slug": "apple-appstore"
          }
        },
        {
          "store": {
            "id": 8,
            "name": "Google Play",
            "slug": "google-play"
          }
        }
      ],
      "released": "2013-12-05",
      "tba": false,
      "background_image": "https://media.rawg.io/media/games/9aa/9aab60ca72399232ccedfd767d84deb8.jpg",
      "rating": 3.13,
      "rating_top": 3,
      "ratings": [
        {
          "id": 3,
          "title": "meh",
          "count": 13,
          "percent": 43.33
        },
        {
          "id": 4,
          "title": "recommended",
          "count": 10,
          "percent": 33.33
        },
        {
          "id": 1,
          "title": "skip",
          "count": 5,
          "percent": 16.67
        },
        {
          "id": 5,
          "title": "exceptional",
          "count": 2,
          "percent": 6.67
        }
      ],
      "ratings_count": 29,
      "reviews_text_count": 0,
      "added": 84,
      "added_by_status": {
        "yet": 12,
        "owned": 12,
        "beaten": 22,
        "toplay": 10,
        "dropped": 27,
        "playing": 1
      },
      "metacritic": null,
      "suggestions_count": 335,
      "updated": "2025-04-12T14:11:44",
      "id": 1873,
      "score": "50.832024",
      "clip": null,
      "tags": [
        {
          "id": 70,
          "name": "War",
          "slug": "war",
          "language": "eng",
          "games_count": 9891,
          "image_background": "https://media.rawg.io/media/games/98c/98cd77a9f61b31a6ddab1670b079c841.jpg"
        },
        {
          "id": 188,
          "name": "Parkour",
          "slug": "parkour",
          "language": "eng",
          "games_count": 3933,
          "image_background": "https://media.rawg.io/media/games/275/2759da6fcaa8f81f21800926168c85f6.jpg"
        },
        {
          "id": 278,
          "name": "Assassin",
          "slug": "assassin",
          "language": "eng",
          "games_count": 932,
          "image_background": "https://media.rawg.io/media/games/193/19390fa5e75e9048b22c9a736cf9992f.jpg"
        },
        {
          "id": 981,
          "name": "battle",
          "slug": "battle",
          "language": "eng",
          "games_count": 10690,
          "image_background": "https://media.rawg.io/media/games/044/044b2ee023930ca138deda151f40c18c.jpg"
        },
        {
          "id": 98,
          "name": "Loot",
          "slug": "loot",
          "language": "eng",
          "games_count": 2688,
          "image_background": "https://media.rawg.io/media/games/cfe/cfe5960b5caca432f3575fc7d8ff736b.jpg"
        },
        {
          "id": 744,
          "name": "friends",
          "slug": "friends",
          "language": "eng",
          "games_count": 15181,
          "image_background": "https://media.rawg.io/media/games/9f1/9f1891779cb20f44de93cef33b067e50.jpg"
        },
        {
          "id": 581,
          "name": "Epic",
          "slug": "epic",
          "language": "eng",
          "games_count": 4130,
          "image_background": "https://media.rawg.io/media/screenshots/4d9/4d9afae02fdf2896569b1c7bfeabb8c1.jpg"
        },
        {
          "id": 1529,
          "name": "fight",
          "slug": "fight",
          "language": "eng",
          "games_count": 7912,
          "image_background": "https://media.rawg.io/media/games/08e/08e8d09cd5aae30959c4486649fda3e6.jpg"
        },
        {
          "id": 255,
          "name": "Pirates",
          "slug": "pirates",
          "language": "eng",
          "games_count": 2293,
          "image_background": "https://media.rawg.io/media/games/41a/41a648b954d9a750b2595995b113e684.jpg"
        },
        {
          "id": 2326,
          "name": "explore",
          "slug": "explore",
          "language": "eng",
          "games_count": 3357,
          "image_background": "https://media.rawg.io/media/games/91d/91ddeef8d5ebee7f21faa89efa0f2201.jpg"
        },
        {
          "id": 1863,
          "name": "challenge",
          "slug": "challenge",
          "language": "eng",
          "games_count": 12765,
          "image_background": "https://media.rawg.io/media/games/9d3/9d3e5f3b9fbe3769e693c93b5b91300a.jpg"
        },
        {
          "id": 3046,
          "name": "destroy",
          "slug": "destroy",
          "language": "eng",
          "games_count": 4618,
          "image_background": "https://media.rawg.io/media/screenshots/c84/c841102a515d24777f91b4861a84fb5b.jpg"
        },
        {
          "id": 1626,
          "name": "collection",
          "slug": "collection",
          "language": "eng",
          "games_count": 3697,
          "image_background": "https://media.rawg.io/media/games/72b/72bfec99eb3127c4e01fd60f79133965.jpg"
        },
        {
          "id": 2184,
          "name": "hunt",
          "slug": "hunt",
          "language": "eng",
          "games_count": 2353,
          "image_background": "https://media.rawg.io/media/games/c36/c366f32194f488b2d04c0ec086c2cc3d.jpg"
        },
        {
          "id": 1505,
          "name": "ship",
          "slug": "ship",
          "language": "eng",
          "games_count": 2795,
          "image_background": "https://media.rawg.io/media/screenshots/a1c/a1cf2a32417641639094126a79e1237f.jpg"
        },
        {
          "id": 1068,
          "name": "sea",
          "slug": "sea",
          "language": "eng",
          "games_count": 2418,
          "image_background": "https://media.rawg.io/media/games/5f6/5f61441e6338e9221f96a8f4c64c7bb8.jpg"
        },
        {
          "id": 3626,
          "name": "treasure",
          "slug": "treasure",
          "language": "eng",
          "games_count": 1880,
          "image_background": "https://media.rawg.io/media/games/9d3/9d335d988b809912a3f7876523916578.jpg"
        },
        {
          "id": 2489,
          "name": "dodge",
          "slug": "dodge",
          "language": "eng",
          "games_count": 2981,
          "image_background": "https://media.rawg.io/media/screenshots/1ae/1aef4421d7f96e4fb8bb8d121cd3e703_SS9Fznj.jpg"
        },
        {
          "id": 982,
          "name": "run",
          "slug": "run",
          "language": "eng",
          "games_count": 3973,
          "image_background": "https://media.rawg.io/media/screenshots/2d3/2d325e729f1fde4cc281cd749763c851.jpg"
        },
        {
          "id": 2546,
          "name": "ships",
          "slug": "ships",
          "language": "eng",
          "games_count": 1570,
          "image_background": "https://media.rawg.io/media/screenshots/4ea/4ead5620bbc512d788e651d0f8dac24d.jpg"
        }
      ],
      "esrb_rating": {
        "id": 3,
        "name": "Teen",
        "slug": "teen",
        "name_en": "Teen",
        "name_ru": "С 13 лет"
      },
      "user_game": null,
      "reviews_count": 30,
      "saturated_color": "0f0f0f",
      "dominant_color": "0f0f0f",
      "short_screenshots": [
        {
          "id": -1,
          "image": "https://media.rawg.io/media/games/9aa/9aab60ca72399232ccedfd767d84deb8.jpg"
        },
        {
          "id": 16853,
          "image": "https://media.rawg.io/media/screenshots/c6c/c6c20d1598bc7d740643f55bdfa04185.jpeg"
        },
        {
          "id": 16854,
          "image": "https://media.rawg.io/media/screenshots/76f/76fb6ae573d56e0a1d7410d31bc22c50.jpeg"
        },
        {
          "id": 16855,
          "image": "https://media.rawg.io/media/screenshots/ed7/ed7753c43ee584e437a267f3f530cb83.jpeg"
        },
        {
          "id": 16856,
          "image": "https://media.rawg.io/media/screenshots/067/0671ccabefe9d968b89e5fa6d507f7b7.jpeg"
        },
        {
          "id": 667628,
          "image": "https://media.rawg.io/media/screenshots/180/1802b9d483828c22dd01880c4f8da2af.jpg"
        },
        {
          "id": 667629,
          "image": "https://media.rawg.io/media/screenshots/b43/b434afa5ee2dca04d3e776bacfc14cf0.jpg"
        }
      ],
      "parent_platforms": [
        {
          "platform": {
            "id": 1,
            "name": "PC",
            "slug": "pc"
          }
        },
        {
          "platform": {
            "id": 4,
            "name": "iOS",
            "slug": "ios"
          }
        },
        {
          "platform": {
            "id": 8,
            "name": "Android",
            "slug": "android"
          }
        }
      ],
      "genres": [
        {
          "id": 3,
          "name": "Adventure",
          "slug": "adventure"
        },
        {
          "id": 4,
          "name": "Action",
          "slug": "action"
        }
      ]
    }
  ],
  "user_platforms": false
};
  }
} 