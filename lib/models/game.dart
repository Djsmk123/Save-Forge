import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'game.g.dart';

@HiveType(typeId: 0)
@JsonSerializable()
class Game {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String iconPath;
  
  @HiveField(3)
  final String savePath;
  
  @HiveField(4)
  final String? executablePath;
  
  @HiveField(5)
  final DateTime createdAt;
  
  @HiveField(6)
  final DateTime updatedAt;

  //active profile id
  @HiveField(7)
  final String? activeProfileId;

  const Game({
    required this.id,
    required this.name,
    required this.iconPath,
    required this.savePath,
    this.executablePath,
    required this.createdAt,
    required this.updatedAt,
    this.activeProfileId,
  });

  factory Game.fromJson(Map<String, dynamic> json) => _$GameFromJson(json);
  Map<String, dynamic> toJson() => _$GameToJson(this);

  Game copyWith({
    String? id,
    String? name,
    String? iconPath,
    String? savePath,
    String? executablePath,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? activeProfileId,
  }) {
    return Game(
      id: id ?? this.id,
      name: name ?? this.name,
      iconPath: iconPath ?? this.iconPath,
      savePath: savePath ?? this.savePath,
      executablePath: executablePath ?? this.executablePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      activeProfileId: activeProfileId ?? this.activeProfileId,
    );
  }

  @override
  String toString() {
    return 'Game(id: $id, name: $name, iconPath: $iconPath, savePath: $savePath, executablePath: $executablePath, createdAt: $createdAt, updatedAt: $updatedAt, activeProfileId: $activeProfileId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Game &&
        other.id == id &&
        other.name == name &&
        other.iconPath == iconPath &&
        other.savePath == savePath &&
        other.executablePath == executablePath &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.activeProfileId == activeProfileId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        iconPath.hashCode ^
        savePath.hashCode ^
        executablePath.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        activeProfileId.hashCode;
  }
} 

