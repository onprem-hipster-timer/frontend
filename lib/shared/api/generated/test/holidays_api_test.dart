import 'package:test/test.dart';
import 'package:momeet_api/momeet_api.dart';


/// tests for HolidaysApi
void main() {
  final instance = MomeetApi().getHolidaysApi();

  group(HolidaysApi, () {
    // Get Holidays
    //
    // 공휴일 조회  - year만 지정: 해당 연도 조회 - start_year/end_year 지정: 범위 조회 (end_year 없으면 start_year로 대체) - 미지정: 현재 연도 조회 - auto_sync=False (기본값): DB에 있는 데이터만 반환 - auto_sync=True: 데이터가 없으면 자동으로 동기화 수행 후 결과 반환 - 422 에러: 해당 연도의 공휴일 데이터가 준비되지 않은 경우 (2028년 이후 등)
    //
    //Future<BuiltList<HolidayItem>> getHolidaysV1HolidaysGet({ int year, int startYear, int endYear, bool autoSync }) async
    test('test getHolidaysV1HolidaysGet', () async {
      // TODO
    });

  });
}
