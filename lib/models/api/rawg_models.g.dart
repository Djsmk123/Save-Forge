// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rawg_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RawgGame _$RawgGameFromJson(Map<String, dynamic> json) => $checkedCreate(
      'RawgGame',
      json,
      ($checkedConvert) {
        final val = RawgGame(
          id: $checkedConvert('id', (v) => (v as num).toInt()),
          slug: $checkedConvert('slug', (v) => v as String?),
          name: $checkedConvert('name', (v) => v as String?),
          playtime: $checkedConvert('playtime', (v) => (v as num?)?.toInt()),
          platforms: $checkedConvert(
              'platforms',
              (v) => (v as List<dynamic>?)
                  ?.map((e) => RawgPlatform.fromJson(e as Map<String, dynamic>))
                  .toList()),
          stores: $checkedConvert(
              'stores',
              (v) => (v as List<dynamic>?)
                  ?.map((e) => RawgStore.fromJson(e as Map<String, dynamic>))
                  .toList()),
          released: $checkedConvert('released', (v) => v as String?),
          tba: $checkedConvert('tba', (v) => v as bool?),
          backgroundImage:
              $checkedConvert('background_image', (v) => v as String?),
          rating: $checkedConvert('rating', (v) => (v as num?)?.toDouble()),
          ratingTop: $checkedConvert('rating_top', (v) => (v as num?)?.toInt()),
          ratings: $checkedConvert(
              'ratings',
              (v) => (v as List<dynamic>?)
                  ?.map((e) => RawgRating.fromJson(e as Map<String, dynamic>))
                  .toList()),
          ratingsCount:
              $checkedConvert('ratings_count', (v) => (v as num?)?.toInt()),
          reviewsTextCount: $checkedConvert(
              'reviews_text_count', (v) => (v as num?)?.toInt()),
          added: $checkedConvert('added', (v) => (v as num?)?.toInt()),
          addedByStatus: $checkedConvert(
              'added_by_status',
              (v) => v == null
                  ? null
                  : RawgAddedByStatus.fromJson(v as Map<String, dynamic>)),
          metacritic:
              $checkedConvert('metacritic', (v) => (v as num?)?.toInt()),
          suggestionsCount:
              $checkedConvert('suggestions_count', (v) => (v as num?)?.toInt()),
          updated: $checkedConvert('updated', (v) => v as String?),
          score: $checkedConvert('score', (v) => v as String?),
          clip: $checkedConvert(
              'clip',
              (v) => v == null
                  ? null
                  : RawgClip.fromJson(v as Map<String, dynamic>)),
          tags: $checkedConvert(
              'tags',
              (v) => (v as List<dynamic>?)
                  ?.map((e) => RawgTag.fromJson(e as Map<String, dynamic>))
                  .toList()),
          esrbRating: $checkedConvert(
              'esrb_rating',
              (v) => v == null
                  ? null
                  : RawgEsrbRating.fromJson(v as Map<String, dynamic>)),
          userGame: $checkedConvert(
              'user_game',
              (v) => v == null
                  ? null
                  : RawgUserGame.fromJson(v as Map<String, dynamic>)),
          reviewsCount:
              $checkedConvert('reviews_count', (v) => (v as num?)?.toInt()),
          saturatedColor:
              $checkedConvert('saturated_color', (v) => v as String?),
          dominantColor: $checkedConvert('dominant_color', (v) => v as String?),
          shortScreenshots: $checkedConvert(
              'short_screenshots',
              (v) => (v as List<dynamic>?)
                  ?.map(
                      (e) => RawgScreenshot.fromJson(e as Map<String, dynamic>))
                  .toList()),
          parentPlatforms: $checkedConvert(
              'parent_platforms',
              (v) => (v as List<dynamic>?)
                  ?.map((e) =>
                      RawgParentPlatform.fromJson(e as Map<String, dynamic>))
                  .toList()),
          genres: $checkedConvert(
              'genres',
              (v) => (v as List<dynamic>?)
                  ?.map((e) => RawgGenre.fromJson(e as Map<String, dynamic>))
                  .toList()),
        );
        return val;
      },
      fieldKeyMap: const {
        'backgroundImage': 'background_image',
        'ratingTop': 'rating_top',
        'ratingsCount': 'ratings_count',
        'reviewsTextCount': 'reviews_text_count',
        'addedByStatus': 'added_by_status',
        'suggestionsCount': 'suggestions_count',
        'esrbRating': 'esrb_rating',
        'userGame': 'user_game',
        'reviewsCount': 'reviews_count',
        'saturatedColor': 'saturated_color',
        'dominantColor': 'dominant_color',
        'shortScreenshots': 'short_screenshots',
        'parentPlatforms': 'parent_platforms'
      },
    );

Map<String, dynamic> _$RawgGameToJson(RawgGame instance) => <String, dynamic>{
      'id': instance.id,
      'slug': instance.slug,
      'name': instance.name,
      'playtime': instance.playtime,
      'platforms': instance.platforms,
      'stores': instance.stores,
      'released': instance.released,
      'tba': instance.tba,
      'background_image': instance.backgroundImage,
      'rating': instance.rating,
      'rating_top': instance.ratingTop,
      'ratings': instance.ratings,
      'ratings_count': instance.ratingsCount,
      'reviews_text_count': instance.reviewsTextCount,
      'added': instance.added,
      'added_by_status': instance.addedByStatus,
      'metacritic': instance.metacritic,
      'suggestions_count': instance.suggestionsCount,
      'updated': instance.updated,
      'score': instance.score,
      'clip': instance.clip,
      'tags': instance.tags,
      'esrb_rating': instance.esrbRating,
      'user_game': instance.userGame,
      'reviews_count': instance.reviewsCount,
      'saturated_color': instance.saturatedColor,
      'dominant_color': instance.dominantColor,
      'short_screenshots': instance.shortScreenshots,
      'parent_platforms': instance.parentPlatforms,
      'genres': instance.genres,
    };

RawgPlatform _$RawgPlatformFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'RawgPlatform',
      json,
      ($checkedConvert) {
        final val = RawgPlatform(
          platform: $checkedConvert(
              'platform',
              (v) => v == null
                  ? null
                  : RawgPlatformInfo.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
    );

Map<String, dynamic> _$RawgPlatformToJson(RawgPlatform instance) =>
    <String, dynamic>{
      'platform': instance.platform,
    };

RawgPlatformInfo _$RawgPlatformInfoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'RawgPlatformInfo',
      json,
      ($checkedConvert) {
        final val = RawgPlatformInfo(
          id: $checkedConvert('id', (v) => (v as num?)?.toInt()),
          name: $checkedConvert('name', (v) => v as String?),
          slug: $checkedConvert('slug', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$RawgPlatformInfoToJson(RawgPlatformInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'slug': instance.slug,
    };

RawgStore _$RawgStoreFromJson(Map<String, dynamic> json) => $checkedCreate(
      'RawgStore',
      json,
      ($checkedConvert) {
        final val = RawgStore(
          store: $checkedConvert(
              'store',
              (v) => v == null
                  ? null
                  : RawgStoreInfo.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
    );

Map<String, dynamic> _$RawgStoreToJson(RawgStore instance) => <String, dynamic>{
      'store': instance.store,
    };

RawgStoreInfo _$RawgStoreInfoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'RawgStoreInfo',
      json,
      ($checkedConvert) {
        final val = RawgStoreInfo(
          id: $checkedConvert('id', (v) => (v as num?)?.toInt()),
          name: $checkedConvert('name', (v) => v as String?),
          slug: $checkedConvert('slug', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$RawgStoreInfoToJson(RawgStoreInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'slug': instance.slug,
    };

RawgRating _$RawgRatingFromJson(Map<String, dynamic> json) => $checkedCreate(
      'RawgRating',
      json,
      ($checkedConvert) {
        final val = RawgRating(
          id: $checkedConvert('id', (v) => (v as num?)?.toInt()),
          title: $checkedConvert('title', (v) => v as String?),
          count: $checkedConvert('count', (v) => (v as num?)?.toInt()),
          percent: $checkedConvert('percent', (v) => (v as num?)?.toDouble()),
        );
        return val;
      },
    );

Map<String, dynamic> _$RawgRatingToJson(RawgRating instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'count': instance.count,
      'percent': instance.percent,
    };

RawgAddedByStatus _$RawgAddedByStatusFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'RawgAddedByStatus',
      json,
      ($checkedConvert) {
        final val = RawgAddedByStatus(
          yet: $checkedConvert('yet', (v) => (v as num?)?.toInt()),
          owned: $checkedConvert('owned', (v) => (v as num?)?.toInt()),
          beaten: $checkedConvert('beaten', (v) => (v as num?)?.toInt()),
          toplay: $checkedConvert('toplay', (v) => (v as num?)?.toInt()),
          dropped: $checkedConvert('dropped', (v) => (v as num?)?.toInt()),
          playing: $checkedConvert('playing', (v) => (v as num?)?.toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$RawgAddedByStatusToJson(RawgAddedByStatus instance) =>
    <String, dynamic>{
      'yet': instance.yet,
      'owned': instance.owned,
      'beaten': instance.beaten,
      'toplay': instance.toplay,
      'dropped': instance.dropped,
      'playing': instance.playing,
    };

RawgClip _$RawgClipFromJson(Map<String, dynamic> json) => $checkedCreate(
      'RawgClip',
      json,
      ($checkedConvert) {
        final val = RawgClip(
          clip: $checkedConvert('clip', (v) => v as String?),
          clips: $checkedConvert(
              'clips',
              (v) => v == null
                  ? null
                  : RawgClipInfo.fromJson(v as Map<String, dynamic>)),
          video: $checkedConvert('video', (v) => v as String?),
          preview: $checkedConvert('preview', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$RawgClipToJson(RawgClip instance) => <String, dynamic>{
      'clip': instance.clip,
      'clips': instance.clips,
      'video': instance.video,
      'preview': instance.preview,
    };

RawgClipInfo _$RawgClipInfoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'RawgClipInfo',
      json,
      ($checkedConvert) {
        final val = RawgClipInfo(
          threeTwenty: $checkedConvert('three_twenty', (v) => v as String?),
          sixForty: $checkedConvert('six_forty', (v) => v as String?),
          full: $checkedConvert('full', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'threeTwenty': 'three_twenty',
        'sixForty': 'six_forty'
      },
    );

Map<String, dynamic> _$RawgClipInfoToJson(RawgClipInfo instance) =>
    <String, dynamic>{
      'three_twenty': instance.threeTwenty,
      'six_forty': instance.sixForty,
      'full': instance.full,
    };

RawgTag _$RawgTagFromJson(Map<String, dynamic> json) => $checkedCreate(
      'RawgTag',
      json,
      ($checkedConvert) {
        final val = RawgTag(
          id: $checkedConvert('id', (v) => (v as num?)?.toInt()),
          name: $checkedConvert('name', (v) => v as String?),
          slug: $checkedConvert('slug', (v) => v as String?),
          language: $checkedConvert('language', (v) => v as String?),
          gamesCount:
              $checkedConvert('games_count', (v) => (v as num?)?.toInt()),
          imageBackground:
              $checkedConvert('image_background', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'gamesCount': 'games_count',
        'imageBackground': 'image_background'
      },
    );

Map<String, dynamic> _$RawgTagToJson(RawgTag instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'slug': instance.slug,
      'language': instance.language,
      'games_count': instance.gamesCount,
      'image_background': instance.imageBackground,
    };

RawgEsrbRating _$RawgEsrbRatingFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'RawgEsrbRating',
      json,
      ($checkedConvert) {
        final val = RawgEsrbRating(
          id: $checkedConvert('id', (v) => (v as num?)?.toInt()),
          name: $checkedConvert('name', (v) => v as String?),
          slug: $checkedConvert('slug', (v) => v as String?),
          nameEn: $checkedConvert('name_en', (v) => v as String?),
          nameRu: $checkedConvert('name_ru', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {'nameEn': 'name_en', 'nameRu': 'name_ru'},
    );

Map<String, dynamic> _$RawgEsrbRatingToJson(RawgEsrbRating instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'slug': instance.slug,
      'name_en': instance.nameEn,
      'name_ru': instance.nameRu,
    };

RawgUserGame _$RawgUserGameFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'RawgUserGame',
      json,
      ($checkedConvert) {
        final val = RawgUserGame(
          status: $checkedConvert('status', (v) => v as String?),
          rating: $checkedConvert('rating', (v) => (v as num?)?.toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$RawgUserGameToJson(RawgUserGame instance) =>
    <String, dynamic>{
      'status': instance.status,
      'rating': instance.rating,
    };

RawgScreenshot _$RawgScreenshotFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'RawgScreenshot',
      json,
      ($checkedConvert) {
        final val = RawgScreenshot(
          id: $checkedConvert('id', (v) => (v as num?)?.toInt()),
          image: $checkedConvert('image', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$RawgScreenshotToJson(RawgScreenshot instance) =>
    <String, dynamic>{
      'id': instance.id,
      'image': instance.image,
    };

RawgParentPlatform _$RawgParentPlatformFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'RawgParentPlatform',
      json,
      ($checkedConvert) {
        final val = RawgParentPlatform(
          platform: $checkedConvert(
              'platform',
              (v) => v == null
                  ? null
                  : RawgPlatformInfo.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
    );

Map<String, dynamic> _$RawgParentPlatformToJson(RawgParentPlatform instance) =>
    <String, dynamic>{
      'platform': instance.platform,
    };

RawgGenre _$RawgGenreFromJson(Map<String, dynamic> json) => $checkedCreate(
      'RawgGenre',
      json,
      ($checkedConvert) {
        final val = RawgGenre(
          id: $checkedConvert('id', (v) => (v as num?)?.toInt()),
          name: $checkedConvert('name', (v) => v as String?),
          slug: $checkedConvert('slug', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$RawgGenreToJson(RawgGenre instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'slug': instance.slug,
    };

RawgSearchParams _$RawgSearchParamsFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'RawgSearchParams',
      json,
      ($checkedConvert) {
        final val = RawgSearchParams(
          search: $checkedConvert('search', (v) => v as String?),
          searchPrecise: $checkedConvert('search_precise', (v) => v as String?),
          searchExact: $checkedConvert('search_exact', (v) => v as String?),
          parentPlatforms:
              $checkedConvert('parent_platforms', (v) => (v as num?)?.toInt()),
          platforms: $checkedConvert('platforms', (v) => (v as num?)?.toInt()),
          stores: $checkedConvert('stores', (v) => (v as num?)?.toInt()),
          developers:
              $checkedConvert('developers', (v) => (v as num?)?.toInt()),
          publishers:
              $checkedConvert('publishers', (v) => (v as num?)?.toInt()),
          genres: $checkedConvert('genres', (v) => (v as num?)?.toInt()),
          tags: $checkedConvert('tags', (v) => (v as num?)?.toInt()),
          creators: $checkedConvert('creators', (v) => (v as num?)?.toInt()),
          dates: $checkedConvert('dates', (v) => (v as num?)?.toInt()),
          updated: $checkedConvert('updated', (v) => (v as num?)?.toInt()),
          metacritic:
              $checkedConvert('metacritic', (v) => (v as num?)?.toInt()),
          excludeCollection: $checkedConvert(
              'exclude_collection', (v) => (v as num?)?.toInt()),
          excludeAdditions:
              $checkedConvert('exclude_additions', (v) => (v as num?)?.toInt()),
          excludeParents:
              $checkedConvert('exclude_parents', (v) => (v as num?)?.toInt()),
          excludeGameSeries: $checkedConvert(
              'exclude_game_series', (v) => (v as num?)?.toInt()),
          excludeStores:
              $checkedConvert('exclude_stores', (v) => (v as num?)?.toInt()),
          ordering: $checkedConvert('ordering', (v) => v as String?),
          page: $checkedConvert('page', (v) => (v as num?)?.toInt()),
          pageSize: $checkedConvert('page_size', (v) => (v as num?)?.toInt()),
          mock: $checkedConvert('mock', (v) => v as bool? ?? false),
        );
        return val;
      },
      fieldKeyMap: const {
        'searchPrecise': 'search_precise',
        'searchExact': 'search_exact',
        'parentPlatforms': 'parent_platforms',
        'excludeCollection': 'exclude_collection',
        'excludeAdditions': 'exclude_additions',
        'excludeParents': 'exclude_parents',
        'excludeGameSeries': 'exclude_game_series',
        'excludeStores': 'exclude_stores',
        'pageSize': 'page_size'
      },
    );

Map<String, dynamic> _$RawgSearchParamsToJson(RawgSearchParams instance) =>
    <String, dynamic>{
      'search': instance.search,
      'search_precise': instance.searchPrecise,
      'search_exact': instance.searchExact,
      'parent_platforms': instance.parentPlatforms,
      'platforms': instance.platforms,
      'stores': instance.stores,
      'developers': instance.developers,
      'publishers': instance.publishers,
      'genres': instance.genres,
      'tags': instance.tags,
      'creators': instance.creators,
      'dates': instance.dates,
      'updated': instance.updated,
      'metacritic': instance.metacritic,
      'exclude_collection': instance.excludeCollection,
      'exclude_additions': instance.excludeAdditions,
      'exclude_parents': instance.excludeParents,
      'exclude_game_series': instance.excludeGameSeries,
      'exclude_stores': instance.excludeStores,
      'ordering': instance.ordering,
      'page': instance.page,
      'page_size': instance.pageSize,
      'mock': instance.mock,
    };
