import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maternal_infant_care/presentation/viewmodels/auth_provider.dart';
import 'package:maternal_infant_care/presentation/viewmodels/user_provider.dart';

class UserMeta {
  final UserProfileType? role;
  final DateTime? startDate;
  final String? username;
  final bool tipsEnabled;
  final bool alertsEnabled;
  final bool remindersEnabled;
  final bool consultationMode;

  UserMeta({
    this.role, 
    this.startDate, 
    this.username, 
    this.tipsEnabled = true, 
    this.alertsEnabled = true,
    this.remindersEnabled = true,
    this.consultationMode = false,
  });

  factory UserMeta.fromMetadata(Map<String, dynamic>? metadata) {
    if (metadata == null) return UserMeta();
    
    final roleStr = metadata['role'] as String?;
    final role = roleStr == 'pregnant'
      ? UserProfileType.pregnant
      : (roleStr == 'trying_to_conceive'
        ? UserProfileType.tryingToConceive
        : (roleStr == 'parent' || roleStr == 'toddler_parent'
          ? UserProfileType.toddlerParent
          : null));
    
    final startDateStr = metadata['start_date'] as String?;
    final startDate = startDateStr != null ? DateTime.tryParse(startDateStr) : null;
    final username = metadata['username'] as String?;
    
    // Explicitly check for false, default to true if null or not present
    final tipsEnabled = metadata['tips_enabled'] != false;
    final alertsEnabled = metadata['alerts_enabled'] != false;
    final remindersEnabled = metadata['reminders_enabled'] != false;
    final consultationMode = metadata['consultation_mode'] == true;

    return UserMeta(
      role: role,
      startDate: startDate,
      username: username,
      tipsEnabled: tipsEnabled,
      alertsEnabled: alertsEnabled,
      remindersEnabled: remindersEnabled,
      consultationMode: consultationMode,
    );
  }
}

final consultationModeOverrideProvider = StateProvider<bool?>((ref) => null);

final userMetaProvider = Provider<UserMeta>((ref) {
  final user = ref.watch(currentUserProvider);
  final authService = ref.watch(authServiceProvider);
  final profileType = ref.watch(userProfileProvider);
  
  if (user == null) return UserMeta();
  
  final metadata = authService.userMetadata;
  final userMeta = UserMeta.fromMetadata(metadata);
  final consultationModeOverride = ref.watch(consultationModeOverrideProvider);
  final effectiveConsultationMode = consultationModeOverride ?? userMeta.consultationMode;
  
  // Use profileType if role is not in metadata
  if (userMeta.role == null && profileType != null) {
    return UserMeta(
      role: profileType,
      startDate: userMeta.startDate,
      username: userMeta.username,
      tipsEnabled: userMeta.tipsEnabled,
      alertsEnabled: userMeta.alertsEnabled,
      remindersEnabled: userMeta.remindersEnabled,
      consultationMode: effectiveConsultationMode,
    );
  }

  return UserMeta(
    role: userMeta.role,
    startDate: userMeta.startDate,
    username: userMeta.username,
    tipsEnabled: userMeta.tipsEnabled,
    alertsEnabled: userMeta.alertsEnabled,
    remindersEnabled: userMeta.remindersEnabled,
    consultationMode: effectiveConsultationMode,
  );
});
