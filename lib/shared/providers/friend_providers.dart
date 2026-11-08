import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/api_providers.dart';

/// 내 친구 목록 (`GET /v1/friends`)
final friendsProvider = FutureProvider.autoDispose<List<FriendRead>>(
  (ref) => ref.watch(friendsApiProvider).listFriendsV1FriendsGet(),
);
