import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../data/repositories/account_link_repository_impl.dart';
import '../../domain/entities/account_link_request.dart';
import '../../domain/repositories/account_link_repository.dart';

final accountLinkRepositoryProvider = Provider<AccountLinkRepository>(
  (ref) => AccountLinkRepositoryImpl(ref.watch(firestoreProvider)),
);

final elderAccountLinksProvider =
    StreamProvider.family<List<AccountLinkRequest>, String>(
      (ref, elderId) =>
          ref.watch(accountLinkRepositoryProvider).watchElderLinks(elderId),
    );

final childAccountLinksProvider =
    StreamProvider.family<List<AccountLinkRequest>, String>(
      (ref, childPhone) =>
          ref.watch(accountLinkRepositoryProvider).watchChildLinks(childPhone),
    );
