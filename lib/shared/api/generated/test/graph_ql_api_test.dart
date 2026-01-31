import 'package:test/test.dart';
import 'package:momeet_api/momeet_api.dart';


/// tests for GraphQLApi
void main() {
  final instance = MomeetApi().getGraphQLApi();

  group(GraphQLApi, () {
    // Handle Http Get
    //
    //Future<JsonObject> handleHttpGetV1GraphqlGet() async
    test('test handleHttpGetV1GraphqlGet', () async {
      // TODO
    });

    // Handle Http Post
    //
    //Future<JsonObject> handleHttpPostV1GraphqlPost() async
    test('test handleHttpPostV1GraphqlPost', () async {
      // TODO
    });

  });
}
