// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/friend_read.dart';
import '../models/friend_request.dart';
import '../models/friendship_read.dart';
import '../models/pending_request_read.dart';

part 'friends_client.g.dart';

@RestApi()
abstract class FriendsClient {
  factory FriendsClient(Dio dio, {String? baseUrl}) = _FriendsClient;

  /// List Friends.
  ///
  /// 친구 목록 조회.
  ///
  /// 현재 사용자의 모든 친구 목록을 반환합니다.
  @GET('/v1/friends')
  Future<List<FriendRead>> listFriendsV1FriendsGet({
    @DioOptions() RequestOptions? options,
  });

  /// List Friend Ids.
  ///
  /// 친구 ID 목록만 조회 (효율적인 쿼리).
  ///
  /// 친구 목록을 빠르게 확인할 때 사용합니다.
  @GET('/v1/friends/ids')
  Future<List<String>> listFriendIdsV1FriendsIdsGet({
    @DioOptions() RequestOptions? options,
  });

  /// List Received Requests.
  ///
  /// 받은 친구 요청 목록 조회.
  ///
  /// 대기 중인 친구 요청만 반환합니다.
  @GET('/v1/friends/requests/received')
  Future<List<PendingRequestRead>> listReceivedRequestsV1FriendsRequestsReceivedGet({
    @DioOptions() RequestOptions? options,
  });

  /// List Sent Requests.
  ///
  /// 보낸 친구 요청 목록 조회.
  ///
  /// 대기 중인 친구 요청만 반환합니다.
  @GET('/v1/friends/requests/sent')
  Future<List<PendingRequestRead>> listSentRequestsV1FriendsRequestsSentGet({
    @DioOptions() RequestOptions? options,
  });

  /// Send Friend Request.
  ///
  /// 친구 요청 보내기.
  ///
  /// 대상 사용자에게 친구 요청을 보냅니다.
  /// 이미 친구이거나 대기 중인 요청이 있으면 에러가 발생합니다.
  @POST('/v1/friends/requests')
  Future<FriendshipRead> sendFriendRequestV1FriendsRequestsPost({
    @Body() required FriendRequest body,
    @DioOptions() RequestOptions? options,
  });

  /// Accept Friend Request.
  ///
  /// 친구 요청 수락.
  ///
  /// 받은 친구 요청을 수락합니다.
  /// 요청 수신자만 수락할 수 있습니다.
  @POST('/v1/friends/requests/{friendship_id}/accept')
  Future<FriendshipRead> acceptFriendRequestV1FriendsRequestsFriendshipIdAcceptPost({
    @Path('friendship_id') required String friendshipId,
    @DioOptions() RequestOptions? options,
  });

  /// Reject Friend Request.
  ///
  /// 친구 요청 거절.
  ///
  /// 받은 친구 요청을 거절합니다.
  /// 거절된 요청은 삭제됩니다.
  @POST('/v1/friends/requests/{friendship_id}/reject')
  Future<void> rejectFriendRequestV1FriendsRequestsFriendshipIdRejectPost({
    @Path('friendship_id') required String friendshipId,
    @DioOptions() RequestOptions? options,
  });

  /// Cancel Friend Request.
  ///
  /// 보낸 친구 요청 취소.
  ///
  /// 보낸 친구 요청을 취소합니다.
  /// 요청 발신자만 취소할 수 있습니다.
  @DELETE('/v1/friends/requests/{friendship_id}')
  Future<void> cancelFriendRequestV1FriendsRequestsFriendshipIdDelete({
    @Path('friendship_id') required String friendshipId,
    @DioOptions() RequestOptions? options,
  });

  /// Remove Friend.
  ///
  /// 친구 삭제.
  ///
  /// 친구 관계를 끊습니다.
  /// 양쪽 모두 삭제할 수 있습니다.
  @DELETE('/v1/friends/{friendship_id}')
  Future<void> removeFriendV1FriendsFriendshipIdDelete({
    @Path('friendship_id') required String friendshipId,
    @DioOptions() RequestOptions? options,
  });

  /// Check Friendship.
  ///
  /// 친구 여부 확인.
  ///
  /// 특정 사용자와 친구인지 확인합니다.
  @GET('/v1/friends/check/{user_id}')
  Future<bool> checkFriendshipV1FriendsCheckUserIdGet({
    @Path('user_id') required String userId,
    @DioOptions() RequestOptions? options,
  });

  /// Block User.
  ///
  /// 사용자 차단.
  ///
  /// 특정 사용자를 차단합니다.
  /// 차단된 사용자는 친구 요청을 보낼 수 없고, 공유된 콘텐츠에 접근할 수 없습니다.
  @POST('/v1/friends/block/{user_id}')
  Future<FriendshipRead> blockUserV1FriendsBlockUserIdPost({
    @Path('user_id') required String userId,
    @DioOptions() RequestOptions? options,
  });

  /// Unblock User.
  ///
  /// 사용자 차단 해제.
  ///
  /// 차단을 해제합니다.
  /// 본인이 차단한 경우에만 해제할 수 있습니다.
  @DELETE('/v1/friends/block/{user_id}')
  Future<void> unblockUserV1FriendsBlockUserIdDelete({
    @Path('user_id') required String userId,
    @DioOptions() RequestOptions? options,
  });
}
