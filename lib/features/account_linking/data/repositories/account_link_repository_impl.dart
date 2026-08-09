import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/account_link_request.dart';
import '../../domain/repositories/account_link_repository.dart';
import '../models/account_link_model.dart';

final class AccountLinkRepositoryImpl implements AccountLinkRepository {
  AccountLinkRepositoryImpl(this._firestore);
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _links =>
      _firestore.collection('account_links');

  @override
  Stream<List<AccountLinkRequest>> watchElderLinks(String elderId) =>
      _links.where('elderId', isEqualTo: elderId).snapshots().map(_mapAndSort);

  @override
  Stream<List<AccountLinkRequest>> watchChildLinks(String childPhone) => _links
      .where('childPhone', isEqualTo: childPhone)
      .snapshots()
      .map(_mapAndSort);

  List<AccountLinkRequest> _mapAndSort(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final links = snapshot.docs.map(AccountLinkModel.fromFirestore).toList();
    links.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return links;
  }

  @override
  Future<void> createRequest(AccountLinkRequest request) async {
    final directory = await _firestore
        .collection('user_directory')
        .doc(request.childPhone)
        .get();
    final target = directory.data();
    if (target == null) {
      throw const ValidationException(
        'Không tìm thấy tài khoản với số điện thoại này. Người nhận cần đăng nhập lại để đồng bộ hồ sơ.',
      );
    }
    if (target['role'] != 'child') {
      throw const ValidationException(
        'Chỉ có thể liên kết tài khoản Elder với tài khoản Child.',
      );
    }
    final childId = target['uid'] as String?;
    if (childId == null || childId.isEmpty || childId == request.elderId) {
      throw const ValidationException('Tài khoản liên kết không hợp lệ.');
    }
    final document = request.id.isEmpty ? _links.doc() : _links.doc(request.id);
    final data = AccountLinkModel.toFirestore(request);
    data['childId'] = childId;
    await document.set(data);
  }

  @override
  Future<void> respondToRequest({
    required String requestId,
    required bool accept,
    required String childId,
    required String childName,
  }) async {
    final linkReference = _links.doc(requestId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(linkReference);
      final data = snapshot.data();
      if (data == null || data['status'] != LinkRequestStatus.pending.name) {
        throw StateError('Yêu cầu liên kết không còn hiệu lực');
      }
      final invitedChildId = data['childId'] as String?;
      if (invitedChildId != null && invitedChildId != childId) {
        throw const ValidationException(
          'Yêu cầu này được gửi cho một tài khoản Child khác.',
        );
      }
      final elderId = data['elderId'] as String;
      transaction.update(linkReference, {
        'status': accept
            ? LinkRequestStatus.accepted.name
            : LinkRequestStatus.rejected.name,
        'childId': childId,
        'childName': childName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (accept) {
        final relationship = _firestore
            .collection('care_relationships')
            .doc('${elderId}_$childId');
        transaction.set(relationship, {
          'elderId': elderId,
          'childId': childId,
          'invitationId': requestId,
          'status': LinkRequestStatus.accepted.name,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  @override
  Future<void> cancelRequest(String requestId) => _links.doc(requestId).update({
    'status': LinkRequestStatus.cancelled.name,
    'updatedAt': FieldValue.serverTimestamp(),
  });
}
