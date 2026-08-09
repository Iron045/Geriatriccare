enum LinkRequestStatus { pending, accepted, rejected, cancelled }

class AccountLinkRequest {
  const AccountLinkRequest({
    required this.id,
    required this.elderId,
    required this.elderName,
    required this.elderPhone,
    required this.childPhone,
    required this.relationship,
    required this.status,
    required this.createdAt,
    this.elderGender,
    this.childId,
    this.childName,
    this.updatedAt,
  });

  final String id;
  final String elderId;
  final String elderName;
  final String elderPhone;
  final String childPhone;
  final String relationship;
  final LinkRequestStatus status;
  final DateTime createdAt;
  final String? elderGender;
  final String? childId;
  final String? childName;
  final DateTime? updatedAt;
}
