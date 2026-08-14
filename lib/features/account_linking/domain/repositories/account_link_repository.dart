import '../entities/account_link_request.dart';

abstract interface class AccountLinkRepository {
  Stream<List<AccountLinkRequest>> watchElderLinks(String elderId);
  Stream<List<AccountLinkRequest>> watchChildLinks(String childPhone);
  Future<void> createRequest(AccountLinkRequest request);
  Future<void> respondToRequest({
    required String requestId,
    required bool accept,
    required String elderId,
  });
  Future<void> cancelRequest(String requestId);
}
