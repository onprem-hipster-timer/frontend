import 'package:test/test.dart';
import 'package:momeet_api/momeet_api.dart';


/// tests for FriendsApi
void main() {
  final instance = MomeetApi().getFriendsApi();

  group(FriendsApi, () {
    // Accept Friend Request
    //
    // 친구 요청 수락  받은 친구 요청을 수락합니다. 요청 수신자만 수락할 수 있습니다.
    //
    //Future<FriendshipRead> acceptFriendRequestV1FriendsRequestsFriendshipIdAcceptPost(String friendshipId) async
    test('test acceptFriendRequestV1FriendsRequestsFriendshipIdAcceptPost', () async {
      // TODO
    });

    // Block User
    //
    // 사용자 차단  특정 사용자를 차단합니다. 차단된 사용자는 친구 요청을 보낼 수 없고, 공유된 콘텐츠에 접근할 수 없습니다.
    //
    //Future<FriendshipRead> blockUserV1FriendsBlockUserIdPost(String userId) async
    test('test blockUserV1FriendsBlockUserIdPost', () async {
      // TODO
    });

    // Cancel Friend Request
    //
    // 보낸 친구 요청 취소  보낸 친구 요청을 취소합니다. 요청 발신자만 취소할 수 있습니다.
    //
    //Future<JsonObject> cancelFriendRequestV1FriendsRequestsFriendshipIdDelete(String friendshipId) async
    test('test cancelFriendRequestV1FriendsRequestsFriendshipIdDelete', () async {
      // TODO
    });

    // Check Friendship
    //
    // 친구 여부 확인  특정 사용자와 친구인지 확인합니다.
    //
    //Future<bool> checkFriendshipV1FriendsCheckUserIdGet(String userId) async
    test('test checkFriendshipV1FriendsCheckUserIdGet', () async {
      // TODO
    });

    // List Friend Ids
    //
    // 친구 ID 목록만 조회 (효율적인 쿼리)  친구 목록을 빠르게 확인할 때 사용합니다.
    //
    //Future<BuiltList<String>> listFriendIdsV1FriendsIdsGet() async
    test('test listFriendIdsV1FriendsIdsGet', () async {
      // TODO
    });

    // List Friends
    //
    // 친구 목록 조회  현재 사용자의 모든 친구 목록을 반환합니다.
    //
    //Future<BuiltList<FriendRead>> listFriendsV1FriendsGet() async
    test('test listFriendsV1FriendsGet', () async {
      // TODO
    });

    // List Received Requests
    //
    // 받은 친구 요청 목록 조회  대기 중인 친구 요청만 반환합니다.
    //
    //Future<BuiltList<PendingRequestRead>> listReceivedRequestsV1FriendsRequestsReceivedGet() async
    test('test listReceivedRequestsV1FriendsRequestsReceivedGet', () async {
      // TODO
    });

    // List Sent Requests
    //
    // 보낸 친구 요청 목록 조회  대기 중인 친구 요청만 반환합니다.
    //
    //Future<BuiltList<PendingRequestRead>> listSentRequestsV1FriendsRequestsSentGet() async
    test('test listSentRequestsV1FriendsRequestsSentGet', () async {
      // TODO
    });

    // Reject Friend Request
    //
    // 친구 요청 거절  받은 친구 요청을 거절합니다. 거절된 요청은 삭제됩니다.
    //
    //Future<JsonObject> rejectFriendRequestV1FriendsRequestsFriendshipIdRejectPost(String friendshipId) async
    test('test rejectFriendRequestV1FriendsRequestsFriendshipIdRejectPost', () async {
      // TODO
    });

    // Remove Friend
    //
    // 친구 삭제  친구 관계를 끊습니다. 양쪽 모두 삭제할 수 있습니다.
    //
    //Future<JsonObject> removeFriendV1FriendsFriendshipIdDelete(String friendshipId) async
    test('test removeFriendV1FriendsFriendshipIdDelete', () async {
      // TODO
    });

    // Send Friend Request
    //
    // 친구 요청 보내기  대상 사용자에게 친구 요청을 보냅니다. 이미 친구이거나 대기 중인 요청이 있으면 에러가 발생합니다.
    //
    //Future<FriendshipRead> sendFriendRequestV1FriendsRequestsPost(FriendRequest friendRequest) async
    test('test sendFriendRequestV1FriendsRequestsPost', () async {
      // TODO
    });

    // Unblock User
    //
    // 사용자 차단 해제  차단을 해제합니다. 본인이 차단한 경우에만 해제할 수 있습니다.
    //
    //Future<JsonObject> unblockUserV1FriendsBlockUserIdDelete(String userId) async
    test('test unblockUserV1FriendsBlockUserIdDelete', () async {
      // TODO
    });

  });
}
