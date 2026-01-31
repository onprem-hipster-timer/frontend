# momeet_api.api.FriendsApi

## Load the API package
```dart
import 'package:momeet_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**acceptFriendRequestV1FriendsRequestsFriendshipIdAcceptPost**](FriendsApi.md#acceptfriendrequestv1friendsrequestsfriendshipidacceptpost) | **POST** /v1/friends/requests/{friendship_id}/accept | Accept Friend Request
[**blockUserV1FriendsBlockUserIdPost**](FriendsApi.md#blockuserv1friendsblockuseridpost) | **POST** /v1/friends/block/{user_id} | Block User
[**cancelFriendRequestV1FriendsRequestsFriendshipIdDelete**](FriendsApi.md#cancelfriendrequestv1friendsrequestsfriendshipiddelete) | **DELETE** /v1/friends/requests/{friendship_id} | Cancel Friend Request
[**checkFriendshipV1FriendsCheckUserIdGet**](FriendsApi.md#checkfriendshipv1friendscheckuseridget) | **GET** /v1/friends/check/{user_id} | Check Friendship
[**listFriendIdsV1FriendsIdsGet**](FriendsApi.md#listfriendidsv1friendsidsget) | **GET** /v1/friends/ids | List Friend Ids
[**listFriendsV1FriendsGet**](FriendsApi.md#listfriendsv1friendsget) | **GET** /v1/friends | List Friends
[**listReceivedRequestsV1FriendsRequestsReceivedGet**](FriendsApi.md#listreceivedrequestsv1friendsrequestsreceivedget) | **GET** /v1/friends/requests/received | List Received Requests
[**listSentRequestsV1FriendsRequestsSentGet**](FriendsApi.md#listsentrequestsv1friendsrequestssentget) | **GET** /v1/friends/requests/sent | List Sent Requests
[**rejectFriendRequestV1FriendsRequestsFriendshipIdRejectPost**](FriendsApi.md#rejectfriendrequestv1friendsrequestsfriendshipidrejectpost) | **POST** /v1/friends/requests/{friendship_id}/reject | Reject Friend Request
[**removeFriendV1FriendsFriendshipIdDelete**](FriendsApi.md#removefriendv1friendsfriendshipiddelete) | **DELETE** /v1/friends/{friendship_id} | Remove Friend
[**sendFriendRequestV1FriendsRequestsPost**](FriendsApi.md#sendfriendrequestv1friendsrequestspost) | **POST** /v1/friends/requests | Send Friend Request
[**unblockUserV1FriendsBlockUserIdDelete**](FriendsApi.md#unblockuserv1friendsblockuseriddelete) | **DELETE** /v1/friends/block/{user_id} | Unblock User


# **acceptFriendRequestV1FriendsRequestsFriendshipIdAcceptPost**
> FriendshipRead acceptFriendRequestV1FriendsRequestsFriendshipIdAcceptPost(friendshipId)

Accept Friend Request

친구 요청 수락  받은 친구 요청을 수락합니다. 요청 수신자만 수락할 수 있습니다.

### Example
```dart
import 'package:momeet_api/api.dart';

final api = MomeetApi().getFriendsApi();
final String friendshipId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.acceptFriendRequestV1FriendsRequestsFriendshipIdAcceptPost(friendshipId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling FriendsApi->acceptFriendRequestV1FriendsRequestsFriendshipIdAcceptPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **friendshipId** | **String**|  | 

### Return type

[**FriendshipRead**](FriendshipRead.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **blockUserV1FriendsBlockUserIdPost**
> FriendshipRead blockUserV1FriendsBlockUserIdPost(userId)

Block User

사용자 차단  특정 사용자를 차단합니다. 차단된 사용자는 친구 요청을 보낼 수 없고, 공유된 콘텐츠에 접근할 수 없습니다.

### Example
```dart
import 'package:momeet_api/api.dart';

final api = MomeetApi().getFriendsApi();
final String userId = userId_example; // String | 

try {
    final response = api.blockUserV1FriendsBlockUserIdPost(userId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling FriendsApi->blockUserV1FriendsBlockUserIdPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userId** | **String**|  | 

### Return type

[**FriendshipRead**](FriendshipRead.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cancelFriendRequestV1FriendsRequestsFriendshipIdDelete**
> JsonObject cancelFriendRequestV1FriendsRequestsFriendshipIdDelete(friendshipId)

Cancel Friend Request

보낸 친구 요청 취소  보낸 친구 요청을 취소합니다. 요청 발신자만 취소할 수 있습니다.

### Example
```dart
import 'package:momeet_api/api.dart';

final api = MomeetApi().getFriendsApi();
final String friendshipId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.cancelFriendRequestV1FriendsRequestsFriendshipIdDelete(friendshipId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling FriendsApi->cancelFriendRequestV1FriendsRequestsFriendshipIdDelete: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **friendshipId** | **String**|  | 

### Return type

[**JsonObject**](JsonObject.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **checkFriendshipV1FriendsCheckUserIdGet**
> bool checkFriendshipV1FriendsCheckUserIdGet(userId)

Check Friendship

친구 여부 확인  특정 사용자와 친구인지 확인합니다.

### Example
```dart
import 'package:momeet_api/api.dart';

final api = MomeetApi().getFriendsApi();
final String userId = userId_example; // String | 

try {
    final response = api.checkFriendshipV1FriendsCheckUserIdGet(userId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling FriendsApi->checkFriendshipV1FriendsCheckUserIdGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userId** | **String**|  | 

### Return type

**bool**

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listFriendIdsV1FriendsIdsGet**
> BuiltList<String> listFriendIdsV1FriendsIdsGet()

List Friend Ids

친구 ID 목록만 조회 (효율적인 쿼리)  친구 목록을 빠르게 확인할 때 사용합니다.

### Example
```dart
import 'package:momeet_api/api.dart';

final api = MomeetApi().getFriendsApi();

try {
    final response = api.listFriendIdsV1FriendsIdsGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling FriendsApi->listFriendIdsV1FriendsIdsGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

**BuiltList&lt;String&gt;**

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listFriendsV1FriendsGet**
> BuiltList<FriendRead> listFriendsV1FriendsGet()

List Friends

친구 목록 조회  현재 사용자의 모든 친구 목록을 반환합니다.

### Example
```dart
import 'package:momeet_api/api.dart';

final api = MomeetApi().getFriendsApi();

try {
    final response = api.listFriendsV1FriendsGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling FriendsApi->listFriendsV1FriendsGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**BuiltList&lt;FriendRead&gt;**](FriendRead.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listReceivedRequestsV1FriendsRequestsReceivedGet**
> BuiltList<PendingRequestRead> listReceivedRequestsV1FriendsRequestsReceivedGet()

List Received Requests

받은 친구 요청 목록 조회  대기 중인 친구 요청만 반환합니다.

### Example
```dart
import 'package:momeet_api/api.dart';

final api = MomeetApi().getFriendsApi();

try {
    final response = api.listReceivedRequestsV1FriendsRequestsReceivedGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling FriendsApi->listReceivedRequestsV1FriendsRequestsReceivedGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**BuiltList&lt;PendingRequestRead&gt;**](PendingRequestRead.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listSentRequestsV1FriendsRequestsSentGet**
> BuiltList<PendingRequestRead> listSentRequestsV1FriendsRequestsSentGet()

List Sent Requests

보낸 친구 요청 목록 조회  대기 중인 친구 요청만 반환합니다.

### Example
```dart
import 'package:momeet_api/api.dart';

final api = MomeetApi().getFriendsApi();

try {
    final response = api.listSentRequestsV1FriendsRequestsSentGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling FriendsApi->listSentRequestsV1FriendsRequestsSentGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**BuiltList&lt;PendingRequestRead&gt;**](PendingRequestRead.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **rejectFriendRequestV1FriendsRequestsFriendshipIdRejectPost**
> JsonObject rejectFriendRequestV1FriendsRequestsFriendshipIdRejectPost(friendshipId)

Reject Friend Request

친구 요청 거절  받은 친구 요청을 거절합니다. 거절된 요청은 삭제됩니다.

### Example
```dart
import 'package:momeet_api/api.dart';

final api = MomeetApi().getFriendsApi();
final String friendshipId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.rejectFriendRequestV1FriendsRequestsFriendshipIdRejectPost(friendshipId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling FriendsApi->rejectFriendRequestV1FriendsRequestsFriendshipIdRejectPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **friendshipId** | **String**|  | 

### Return type

[**JsonObject**](JsonObject.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **removeFriendV1FriendsFriendshipIdDelete**
> JsonObject removeFriendV1FriendsFriendshipIdDelete(friendshipId)

Remove Friend

친구 삭제  친구 관계를 끊습니다. 양쪽 모두 삭제할 수 있습니다.

### Example
```dart
import 'package:momeet_api/api.dart';

final api = MomeetApi().getFriendsApi();
final String friendshipId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.removeFriendV1FriendsFriendshipIdDelete(friendshipId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling FriendsApi->removeFriendV1FriendsFriendshipIdDelete: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **friendshipId** | **String**|  | 

### Return type

[**JsonObject**](JsonObject.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **sendFriendRequestV1FriendsRequestsPost**
> FriendshipRead sendFriendRequestV1FriendsRequestsPost(friendRequest)

Send Friend Request

친구 요청 보내기  대상 사용자에게 친구 요청을 보냅니다. 이미 친구이거나 대기 중인 요청이 있으면 에러가 발생합니다.

### Example
```dart
import 'package:momeet_api/api.dart';

final api = MomeetApi().getFriendsApi();
final FriendRequest friendRequest = ; // FriendRequest | 

try {
    final response = api.sendFriendRequestV1FriendsRequestsPost(friendRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling FriendsApi->sendFriendRequestV1FriendsRequestsPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **friendRequest** | [**FriendRequest**](FriendRequest.md)|  | 

### Return type

[**FriendshipRead**](FriendshipRead.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **unblockUserV1FriendsBlockUserIdDelete**
> JsonObject unblockUserV1FriendsBlockUserIdDelete(userId)

Unblock User

사용자 차단 해제  차단을 해제합니다. 본인이 차단한 경우에만 해제할 수 있습니다.

### Example
```dart
import 'package:momeet_api/api.dart';

final api = MomeetApi().getFriendsApi();
final String userId = userId_example; // String | 

try {
    final response = api.unblockUserV1FriendsBlockUserIdDelete(userId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling FriendsApi->unblockUserV1FriendsBlockUserIdDelete: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userId** | **String**|  | 

### Return type

[**JsonObject**](JsonObject.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

