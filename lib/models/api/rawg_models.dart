import 'package:json_annotation/json_annotation.dart';

part 'rawg_models.g.dart';

// Base API Response
@JsonSerializable(genericArgumentFactories: true,fieldRename:FieldRename.snake)
class RawgApiResponse<T> {
  final int count;
  final String? next;
  final String? previous;
  final List<T> results;

  const RawgApiResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory RawgApiResponse.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJsonT) {
    return RawgApiResponse<T>(
      count: json['count'] as int,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List<dynamic>)
          .map((item) => fromJsonT(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson(Object? Function(T) toJsonT) {
    return {
      'count': count,
      'next': next,
      'previous': previous,
      'results': results.map(toJsonT).toList(),
    };
  }
}

// Game Models
@JsonSerializable(fieldRename:FieldRename.snake)

class RawgGame {
  final int id;
  final String? slug;
  final String? name;
  final int? playtime;
  final List<RawgPlatform>? platforms;
  final List<RawgStore>? stores;
  final String? released;
  final bool? tba;
  final String? backgroundImage;
  final double? rating;
  final int? ratingTop;
  final List<RawgRating>? ratings;
  final int? ratingsCount;
  final int? reviewsTextCount;
  final int? added;
  final RawgAddedByStatus? addedByStatus;
  final int? metacritic;
  final int? suggestionsCount;
  final String? updated;
  final String? score;
  final RawgClip? clip;
  final List<RawgTag>? tags;
  final RawgEsrbRating? esrbRating;
  final RawgUserGame? userGame;
  final int? reviewsCount;
  final String? saturatedColor;
  final String? dominantColor;
  final List<RawgScreenshot>? shortScreenshots;
  final List<RawgParentPlatform>? parentPlatforms;
  final List<RawgGenre>? genres;

  const RawgGame({
    required this.id,
    this.slug,
    this.name,
    this.playtime,
    this.platforms,
    this.stores,
    this.released,
    this.tba,
    this.backgroundImage,
    this.rating,
    this.ratingTop,
    this.ratings,
    this.ratingsCount,
    this.reviewsTextCount,
    this.added,
    this.addedByStatus,
    this.metacritic,
    this.suggestionsCount,
    this.updated,
    this.score,
    this.clip,
    this.tags,
    this.esrbRating,
    this.userGame,
    this.reviewsCount,
    this.saturatedColor,
    this.dominantColor,
    this.shortScreenshots,
    this.parentPlatforms,
    this.genres
  });

  factory RawgGame.fromJson(Map<String, dynamic> json) => _$RawgGameFromJson(json);
  Map<String, dynamic> toJson() => _$RawgGameToJson(this);
}

@JsonSerializable(fieldRename:FieldRename.snake)
class RawgPlatform {
  final RawgPlatformInfo? platform;

  const RawgPlatform({this.platform});

  factory RawgPlatform.fromJson(Map<String, dynamic> json) => _$RawgPlatformFromJson(json);
  Map<String, dynamic> toJson() => _$RawgPlatformToJson(this);
}

@JsonSerializable(fieldRename:FieldRename.snake)
class RawgPlatformInfo {
  final int? id;
  final String? name;
  final String? slug;

  const RawgPlatformInfo({
    this.id,
    this.name,
    this.slug,
  });

  factory RawgPlatformInfo.fromJson(Map<String, dynamic> json) => _$RawgPlatformInfoFromJson(json);
  Map<String, dynamic> toJson() => _$RawgPlatformInfoToJson(this);
}

@JsonSerializable(fieldRename:FieldRename.snake)
class RawgStore {
  final RawgStoreInfo? store;

  const RawgStore({this.store});

  factory RawgStore.fromJson(Map<String, dynamic> json) => _$RawgStoreFromJson(json);
  Map<String, dynamic> toJson() => _$RawgStoreToJson(this);
}

@JsonSerializable(fieldRename:FieldRename.snake)
class RawgStoreInfo {
  final int? id;
  final String? name;
  final String? slug;

  const RawgStoreInfo({
    this.id,
    this.name,
    this.slug,
  });

  factory RawgStoreInfo.fromJson(Map<String, dynamic> json) => _$RawgStoreInfoFromJson(json);
  Map<String, dynamic> toJson() => _$RawgStoreInfoToJson(this);
}

@JsonSerializable(fieldRename:FieldRename.snake)
class RawgRating {
  final int? id;
  final String? title;
  final int? count;
  final double? percent;

  const RawgRating({
    this.id,
    this.title,
    this.count,
    this.percent,
  });

  factory RawgRating.fromJson(Map<String, dynamic> json) => _$RawgRatingFromJson(json);
  Map<String, dynamic> toJson() => _$RawgRatingToJson(this);
}

@JsonSerializable(fieldRename:FieldRename.snake)
class RawgAddedByStatus {
  final int? yet;
  final int? owned;
  final int? beaten;
  final int? toplay;
  final int? dropped;
  final int? playing;

  const RawgAddedByStatus({
    this.yet,
    this.owned,
    this.beaten,
    this.toplay,
    this.dropped,
    this.playing,
  });

  factory RawgAddedByStatus.fromJson(Map<String, dynamic> json) => _$RawgAddedByStatusFromJson(json);
  Map<String, dynamic> toJson() => _$RawgAddedByStatusToJson(this);
}

@JsonSerializable(fieldRename:FieldRename.snake)
class RawgClip {
  final String? clip;
  final RawgClipInfo? clips;
  final String? video;
  final String? preview;

  const RawgClip({
    this.clip,
    this.clips,
    this.video,
    this.preview,
  });

  factory RawgClip.fromJson(Map<String, dynamic> json) => _$RawgClipFromJson(json);
  Map<String, dynamic> toJson() => _$RawgClipToJson(this);
}

@JsonSerializable(fieldRename:FieldRename.snake)
class RawgClipInfo {
  final String? threeTwenty;
  final String? sixForty;
  final String? full;

  const RawgClipInfo({
    this.threeTwenty,
    this.sixForty,
    this.full,
  });

  factory RawgClipInfo.fromJson(Map<String, dynamic> json) => _$RawgClipInfoFromJson(json);
  Map<String, dynamic> toJson() => _$RawgClipInfoToJson(this);
}

@JsonSerializable(fieldRename:FieldRename.snake)
class RawgTag {
  final int? id;
  final String? name;
  final String? slug;
  final String? language;
  final int? gamesCount;
  final String? imageBackground;

  const RawgTag({
    this.id,
    this.name,
    this.slug,
    this.language,
    this.gamesCount,
    this.imageBackground,
  });

  factory RawgTag.fromJson(Map<String, dynamic> json) => _$RawgTagFromJson(json);
  Map<String, dynamic> toJson() => _$RawgTagToJson(this);
}

@JsonSerializable(fieldRename:FieldRename.snake)
class RawgEsrbRating {
  final int? id;
  final String? name;
  final String? slug;
  final String? nameEn;
  final String? nameRu;

  const RawgEsrbRating({
    this.id,
    this.name,
    this.slug,
    this.nameEn,
    this.nameRu,
  });

  factory RawgEsrbRating.fromJson(Map<String, dynamic> json) => _$RawgEsrbRatingFromJson(json);
  Map<String, dynamic> toJson() => _$RawgEsrbRatingToJson(this);
}

@JsonSerializable(fieldRename:FieldRename.snake)
class RawgUserGame {
  final String? status;
  final int? rating;

  const RawgUserGame({
    this.status,
    this.rating,
  });

  factory RawgUserGame.fromJson(Map<String, dynamic> json) => _$RawgUserGameFromJson(json);
  Map<String, dynamic> toJson() => _$RawgUserGameToJson(this);
}

@JsonSerializable(fieldRename:FieldRename.snake)
class RawgScreenshot {
  final int? id;
  final String? image;

  const RawgScreenshot({
    this.id,
    this.image,
  });

  factory RawgScreenshot.fromJson(Map<String, dynamic> json) => _$RawgScreenshotFromJson(json);
  Map<String, dynamic> toJson() => _$RawgScreenshotToJson(this);
}

@JsonSerializable(fieldRename:FieldRename.snake)
class RawgParentPlatform {
  final RawgPlatformInfo? platform;

  const RawgParentPlatform({this.platform});

  factory RawgParentPlatform.fromJson(Map<String, dynamic> json) => _$RawgParentPlatformFromJson(json);
  Map<String, dynamic> toJson() => _$RawgParentPlatformToJson(this);
}

@JsonSerializable(fieldRename:FieldRename.snake)
class RawgGenre {
  final int? id;
  final String? name;
  final String? slug;

  const RawgGenre({
    this.id,
    this.name,
    this.slug,
  });

  factory RawgGenre.fromJson(Map<String, dynamic> json) => _$RawgGenreFromJson(json);
  Map<String, dynamic> toJson() => _$RawgGenreToJson(this);
}

// Search Parameters
@JsonSerializable(fieldRename:FieldRename.snake)
class RawgSearchParams {
  final String? search;
  final String? searchPrecise;
  final String? searchExact;
  final int? parentPlatforms;
  final int? platforms;
  final int? stores;
  final int? developers;
  final int? publishers;
  final int? genres;
  final int? tags;
  final int? creators;
  final int? dates;
  final int? updated;
  final int? metacritic;
  final int? excludeCollection;
  final int? excludeAdditions;
  final int? excludeParents;
  final int? excludeGameSeries;
  final int? excludeStores;
  final String? ordering;
  final int? page;
  final int? pageSize;
  final bool mock;

  const RawgSearchParams({
    this.search,
    this.searchPrecise,
    this.searchExact,
    this.parentPlatforms,
    this.platforms,
    this.stores,
    this.developers,
    this.publishers,
    this.genres,
    this.tags,
    this.creators,
    this.dates,
    this.updated,
    this.metacritic,
    this.excludeCollection,
    this.excludeAdditions,
    this.excludeParents,
    this.excludeGameSeries,
    this.excludeStores,
    this.ordering,
    this.page,
    this.pageSize,
    this.mock = false,
  });

  factory RawgSearchParams.fromJson(Map<String, dynamic> json) => _$RawgSearchParamsFromJson(json);
  Map<String, dynamic> toJson() => _$RawgSearchParamsToJson(this);

  Map<String, String> toQueryParameters() {
    final params = <String, String>{};
    
    if (search != null) params['search'] = search!;
    if (searchPrecise != null) params['search_precise'] = searchPrecise!;
    if (searchExact != null) params['search_exact'] = searchExact!;
    if (parentPlatforms != null) params['parent_platforms'] = parentPlatforms.toString();
    if (platforms != null) params['platforms'] = platforms.toString();
    if (stores != null) params['stores'] = stores.toString();
    if (developers != null) params['developers'] = developers.toString();
    if (publishers != null) params['publishers'] = publishers.toString();
    if (genres != null) params['genres'] = genres.toString();
    if (tags != null) params['tags'] = tags.toString();
    if (creators != null) params['creators'] = creators.toString();
    if (dates != null) params['dates'] = dates.toString();
    if (updated != null) params['updated'] = updated.toString();
    if (metacritic != null) params['metacritic'] = metacritic.toString();
    if (excludeCollection != null) params['exclude_collection'] = excludeCollection.toString();
    if (excludeAdditions != null) params['exclude_additions'] = excludeAdditions.toString();
    if (excludeParents != null) params['exclude_parents'] = excludeParents.toString();
    if (excludeGameSeries != null) params['exclude_game_series'] = excludeGameSeries.toString();
    if (excludeStores != null) params['exclude_stores'] = excludeStores.toString();
    if (ordering != null) params['ordering'] = ordering!;
    if (page != null) params['page'] = page.toString();
    if (pageSize != null) params['page_size'] = pageSize.toString();
    if (mock) params['mock'] = 'true';
    return params;
  }
} 