import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/account_link_request.dart';

abstract final class AccountLinkModel {
  static AccountLinkRequest fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return AccountLinkRequest(
      id: document.id,
      elderId: data['elderId'] as String? ?? '',
      elderName: data['elderName'] as String? ?? '',
      elderPhone: data['elderPhone'] as String? ?? '',
      elderGender: data['elderGender'] as String?,
      childPhone: data['childPhone'] as String? ?? '',
      childId: data['childId'] as String?,
      childName: data['childName'] as String?,
      relationship: data['relationship'] as String? ?? 'Con cái',
      status: LinkRequestStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => LinkRequestStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  static Map<String, dynamic> toFirestore(AccountLinkRequest request) => {
    'elderId': request.elderId,
    'elderName': request.elderName,
    'elderPhone': request.elderPhone,
    'elderGender': request.elderGender,
    'childPhone': request.childPhone,
    'childId': request.childId,
    'childName': request.childName,
    'relationship': request.relationship,
    'status': request.status.name,
    'createdAt': Timestamp.fromDate(request.createdAt),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
