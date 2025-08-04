import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'profile.g.dart';

@HiveType(typeId: 1)
@JsonSerializable()
class Profile {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String gameId;
  
  @HiveField(2)
  final String name;
  
  @HiveField(3)
  final String folderPath;
  
  @HiveField(4)
  final bool isDefault;
  
  @HiveField(5)
  final DateTime createdAt;
  
  @HiveField(6)
  final DateTime updatedAt;

  const Profile({
    required this.id,
    required this.gameId,
    required this.name,
    required this.folderPath,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => _$ProfileFromJson(json);
  Map<String, dynamic> toJson() => _$ProfileToJson(this);

  Profile copyWith({
    String? id,
    String? gameId,
    String? name,
    String? folderPath,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      name: name ?? this.name,
      folderPath: folderPath ?? this.folderPath,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Profile(id: $id, gameId: $gameId, name: $name, folderPath: $folderPath, isDefault: $isDefault, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Profile &&
        other.id == id &&
        other.gameId == gameId &&
        other.name == name &&
        other.folderPath == folderPath &&
        other.isDefault == isDefault &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        gameId.hashCode ^
        name.hashCode ^
        folderPath.hashCode ^
        isDefault.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }

  /// Gets the display name for the profile
  String get displayName {
    if (isDefault) {
      return '$name (Default)';
    }
    return name;
  }

  /// Gets a short description of the profile
  String get description {
    final dateStr = createdAt.toLocal().toString().split(' ')[0];
    return 'Created: $dateStr';
  }
} 