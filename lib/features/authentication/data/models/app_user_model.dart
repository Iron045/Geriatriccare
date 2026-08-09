import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/app_user.dart';

class AppUserModel {
  const AppUserModel({
    required this.id,
    required this.phoneNumber,
    required this.fullName,
    required this.role,
    required this.createdAt,
    this.gender,
  });

  factory AppUserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return AppUserModel(
      id: document.id,
      phoneNumber: data['phoneNumber'] as String? ?? '',
      fullName: data['fullName'] as String? ?? '',
      // `caregiver` is accepted temporarily so existing accounts keep working
      // after the role was renamed to `child`.
      role: data['role'] == 'child' || data['role'] == 'caregiver'
          ? UserRole.child
          : UserRole.elder,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      gender: _genderFromFirestore(data['gender']),
    );
  }

  factory AppUserModel.fromEntity(AppUser user) => AppUserModel(
    id: user.id,
    phoneNumber: user.phoneNumber,
    fullName: user.fullName,
    role: user.role,
    createdAt: user.createdAt,
    gender: user.gender,
  );

  final String id;
  final String phoneNumber;
  final String fullName;
  final UserRole role;
  final DateTime createdAt;
  final UserGender? gender;

  AppUser toEntity() => AppUser(
    id: id,
    phoneNumber: phoneNumber,
    fullName: fullName,
    role: role,
    createdAt: createdAt,
    gender: gender,
  );

  Map<String, Object?> toFirestore() => {
    'phoneNumber': phoneNumber,
    'fullName': fullName,
    'role': role.name,
    'createdAt': Timestamp.fromDate(createdAt),
    'gender': gender?.name,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  static UserGender? _genderFromFirestore(Object? value) {
    for (final gender in UserGender.values) {
      if (gender.name == value) return gender;
    }
    return null;
  }
}
