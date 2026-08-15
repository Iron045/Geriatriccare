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
        .doc(request.elderPhone)
        .get();
    final target = directory.data();
    if (target == null) {
      throw const ValidationException(
        'Không tìm thấy tài khoản với số điện thoại này. Người nhận cần đăng nhập lại để đồng bộ hồ sơ.',
      );
    }
    if (target['role'] != 'elder') {
      throw const ValidationException(
        'Tài khoản con cái chỉ có thể gửi liên kết cho người cao tuổi.',
      );
    }
    final elderId = target['uid'] as String?;
    if (elderId == null || elderId.isEmpty || elderId == request.childId) {
      throw const ValidationException('Tài khoản liên kết không hợp lệ.');
    }
    final existingLinks = await _links
        .where('childPhone', isEqualTo: request.childPhone)
        .get();
    final duplicate = existingLinks.docs.any((document) {
      final data = document.data();
      return data['elderId'] == elderId &&
          (data['status'] == LinkRequestStatus.pending.name ||
              data['status'] == LinkRequestStatus.accepted.name);
    });
    if (duplicate) {
      throw const ValidationException(
        'Tài khoản này đã liên kết hoặc đang chờ xác nhận.',
      );
    }
    final document = request.id.isEmpty ? _links.doc() : _links.doc(request.id);
    final data = AccountLinkModel.toFirestore(request);
    data['elderId'] = elderId;
    data['elderName'] = target['fullName'] as String? ?? 'Người cao tuổi';
    data['elderGender'] = target['gender'] as String?;
    await document.set(data);
  }

  @override
  Future<void> respondToRequest({
    required String requestId,
    required bool accept,
    required String elderId,
  }) async {
    final linkReference = _links.doc(requestId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(linkReference);
      final data = snapshot.data();
      if (data == null || data['status'] != LinkRequestStatus.pending.name) {
        throw StateError('Yêu cầu liên kết không còn hiệu lực');
      }
      if (data['elderId'] != elderId) {
        throw const ValidationException(
          'Yêu cầu này được gửi cho một tài khoản người cao tuổi khác.',
        );
      }
      final childId = data['childId'] as String?;
      if (childId == null || childId.isEmpty) {
        throw const ValidationException('Tài khoản con cái không hợp lệ.');
      }
      transaction.update(linkReference, {
        'status': accept
            ? LinkRequestStatus.accepted.name
            : LinkRequestStatus.rejected.name,
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
