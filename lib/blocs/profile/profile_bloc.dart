import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:game_save_manager/models/profile.dart';
import 'package:game_save_manager/models/game.dart';
import 'package:game_save_manager/services/data_service.dart';
import 'package:game_save_manager/services/save_manager.dart';
import 'package:game_save_manager/core/logging/app_logger.dart';

// Events
abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadProfiles extends ProfileEvent {
  final String gameId;

  const LoadProfiles(this.gameId);

  @override
  List<Object?> get props => [gameId];
}

class ProfileAdded extends ProfileEvent {
  final Game game;
  final String name;
  final bool isDefault;

  const ProfileAdded({
    required this.game,
    required this.name,
    this.isDefault = false,
  });

  @override
  List<Object?> get props => [game, name, isDefault];
}

class ProfileUpdated extends ProfileEvent {
  final Profile profile;

  const ProfileUpdated(this.profile);

  @override
  List<Object?> get props => [profile];
}

class ProfileDeleted extends ProfileEvent {
  final Game game;
  final Profile profile;

  const ProfileDeleted({
    required this.game,
    required this.profile,
  });

  @override
  List<Object?> get props => [game, profile];
}

class ProfileSwitched extends ProfileEvent {
  final Game game;
  final Profile profile;

  const ProfileSwitched({
    required this.game,
    required this.profile,
  });

  @override
  List<Object?> get props => [game, profile];
}

class ProfileSynced extends ProfileEvent {
  final Game game;
  final Profile profile;

  const ProfileSynced({
    required this.game,
    required this.profile,
  });

  @override
  List<Object?> get props => [game, profile];
}

class UnselectProfile extends ProfileEvent {
  const UnselectProfile();
  @override
  List<Object?> get props => [];
}

class ProfileSelected extends ProfileEvent {
  final Profile profile;

  const ProfileSelected(this.profile);

  @override
  List<Object?> get props => [profile];
}

// States
abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfilesLoaded extends ProfileState {
  final List<Profile> profiles;
  final Profile? selectedProfile;
  final String gameId;

  const ProfilesLoaded({
    required this.profiles,
    this.selectedProfile,
    required this.gameId,
  });

  @override
  List<Object?> get props => [profiles, selectedProfile, gameId];

  ProfilesLoaded copyWith({
    List<Profile>? profiles,
    Profile? selectedProfile,
    String? gameId,
  }) {
    return ProfilesLoaded(
      profiles: profiles ?? this.profiles,
      selectedProfile: selectedProfile ?? this.selectedProfile,
      gameId: gameId ?? this.gameId,
    );
  }
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final DataService _dataService;
  final SaveManager _saveManager;
  final profileLogger = CategoryLogger(LoggerCategory.profile);

  ProfileBloc(this._dataService, this._saveManager) : super(ProfileInitial()) {
    on<LoadProfiles>(_onLoadProfiles);
    on<ProfileAdded>(_onProfileAdded);
    on<ProfileUpdated>(_onProfileUpdated);
    on<ProfileDeleted>(_onProfileDeleted);
    on<ProfileSelected>(_onProfileSelected);
    on<UnselectProfile>(_onUnselectProfile);
    on<ProfileSwitched>(_onProfileSwitched);
    on<ProfileSynced>(_onProfileSynced);
  }

  Future<void> _onLoadProfiles(
    LoadProfiles event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      profileLogger.info('Loading profiles for game: ${event.gameId}');
      emit(ProfileLoading());

      final profiles = _dataService.getProfilesForGame(event.gameId);
      Profile? selectedProfile;
      
      if (profiles.isNotEmpty) {
        selectedProfile = profiles.first;
      }

      profileLogger.info('Profiles loaded successfully: ${profiles.length} profiles');
      emit(ProfilesLoaded(
        profiles: profiles,
        selectedProfile: selectedProfile,
        gameId: event.gameId,
      ));
    } catch (e) {
      profileLogger.error('Failed to load profiles for game: ${event.gameId}', e);
      emit(ProfileError('Failed to load profiles: $e'));
    }
  }

  Future<void> _onProfileAdded(
    ProfileAdded event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      final previousState = state;
      profileLogger.info('Adding profile: ${event.name} for game: ${event.game.id}');
      emit(ProfileLoading());

      final profile = await _saveManager.createProfile(
        event.game,
        event.name,
        isDefault: event.isDefault,
      );

      final currentState = previousState;
      if (currentState is ProfilesLoaded) {
        final updatedProfiles = List<Profile>.from(currentState.profiles)..add(profile);
        
        profileLogger.info('Profile added successfully: ${profile.name}');
        emit(currentState.copyWith(
          profiles: updatedProfiles,
          selectedProfile: profile,
        ));
      }
    } catch (e) {
      profileLogger.error('Failed to add profile: ${event.name}', e);
      emit(ProfileError('Failed to add profile: $e'));
    }
  }

  Future<void> _onProfileUpdated(
    ProfileUpdated event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      final previousState = state;
      profileLogger.info('Updating profile: ${event.profile.name}');
      emit(ProfileLoading());

      await _dataService.updateProfile(event.profile);

      final currentState = previousState;
      if (currentState is ProfilesLoaded) {
        final updatedProfiles = currentState.profiles.map((profile) {
          return profile.id == event.profile.id ? event.profile : profile;
        }).toList();

        final updatedSelectedProfile = currentState.selectedProfile?.id == event.profile.id
            ? event.profile
            : currentState.selectedProfile;

        profileLogger.info('Profile updated successfully: ${event.profile.name}');
        emit(currentState.copyWith(
          profiles: updatedProfiles,
          selectedProfile: updatedSelectedProfile,
        ));
      }
    } catch (e) {
      profileLogger.error('Failed to update profile: ${event.profile.name}', e);
      emit(ProfileError('Failed to update profile: $e'));
    }
  }

  Future<void> _onProfileDeleted(
    ProfileDeleted event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      final previousState = state;
      profileLogger.info('Deleting profile: ${event.profile.id} for game: ${event.game.id}');
      emit(ProfileLoading());

      await _saveManager.deleteProfile(event.game, event.profile);

      final currentState = previousState;
      if (currentState is ProfilesLoaded) {
        final updatedProfiles = currentState.profiles
            .where((profile) => profile.id != event.profile.id)
            .toList();

        Profile? updatedSelectedProfile;
        if (currentState.selectedProfile?.id == event.profile.id) {
          updatedSelectedProfile = updatedProfiles.isNotEmpty ? updatedProfiles.first : null;
        } else {
          updatedSelectedProfile = currentState.selectedProfile;
        }

        profileLogger.info('Profile deleted successfully: ${event.profile.id}');
        emit(currentState.copyWith(
          profiles: updatedProfiles,
          selectedProfile: updatedSelectedProfile,
        ));
      }
    } catch (e) {
      profileLogger.error('Failed to delete profile: ${event.profile.id}', e);
      emit(ProfileError('Failed to delete profile: $e'));
    }
  }

  Future<void> _onProfileSwitched(
    ProfileSwitched event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      profileLogger.info('Switching to profile: ${event.profile.name} for game: ${event.game.name}');
      
      await _saveManager.switchToProfile(event.game, event.profile);
      
      final currentState = state;
      if (currentState is ProfilesLoaded) {
        profileLogger.info('Profile switched successfully: ${event.profile.name}');
        emit(currentState.copyWith(selectedProfile: event.profile));
      }
    } catch (e) {
      profileLogger.error('Failed to switch profile: ${event.profile.name}', e);
      emit(ProfileError('Failed to switch profile: $e'));
    }
  }

  Future<void> _onProfileSynced(
    ProfileSynced event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      profileLogger.info('Syncing profile: ${event.profile.name} for game: ${event.game.name}');
      
      await _saveManager.syncActiveToProfile(event.game, event.profile);
      
      profileLogger.info('Profile synced successfully: ${event.profile.name}');
    } catch (e) {
      profileLogger.error('Failed to sync profile: ${event.profile.name}', e);
      emit(ProfileError('Failed to sync profile: $e'));
    }
  }

  Future<void> _onProfileSelected(
    ProfileSelected event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      profileLogger.info('Selecting profile: ${event.profile.name}');
      
      final currentState = state;
      if (currentState is ProfilesLoaded) {
        profileLogger.info('Profile selected successfully: ${event.profile.name}');
        emit(currentState.copyWith(selectedProfile: event.profile));
      }
    } catch (e) {
      profileLogger.error('Failed to select profile: ${event.profile.name}', e);
      emit(ProfileError('Failed to select profile: $e'));
    }
  }

  // Helper methods
  List<Profile> get profiles {
    if (state is ProfilesLoaded) {
      return (state as ProfilesLoaded).profiles;
    }
    return [];
  }

  Profile? get selectedProfile {
    if (state is ProfilesLoaded) {
      return (state as ProfilesLoaded).selectedProfile;
    }
    return null;
  }

  String? get currentGameId {
    if (state is ProfilesLoaded) {
      return (state as ProfilesLoaded).gameId;
    }
    return null;
  }

  bool get isLoading => state is ProfileLoading;
  bool get hasError => state is ProfileError;
  String? get errorMessage {
    if (state is ProfileError) {
      return (state as ProfileError).message;
    }
    return null;
  }

  Future<void> _onUnselectProfile(
    UnselectProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileInitial());
  }
} 