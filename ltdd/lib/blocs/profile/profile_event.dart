// File: lib/blocs/profile/profile_event.dart
abstract class ProfileEvent {}

class LoadProfile extends ProfileEvent {
  final String userId;
  LoadProfile(this.userId);
}

class RefreshProfile extends ProfileEvent {
  final String userId;
  RefreshProfile(this.userId);
}