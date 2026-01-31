/// Data 계층 템플릿 - 사용 예시

/// 1. 데이터 모델 (Freezed)
/// import 'package:freezed_annotation/freezed_annotation.dart';
///
/// part 'schedule_model.freezed.dart';
/// part 'schedule_model.g.dart';
///
/// @freezed
/// class ScheduleModel with _$ScheduleModel {
///   const factory ScheduleModel({
///     required String id,
///     required String title,
///     required DateTime startTime,
///     required DateTime endTime,
///     String? description,
///   }) = _ScheduleModel;
///
///   factory ScheduleModel.fromJson(Map<String, dynamic> json) =>
///       _$ScheduleModelFromJson(json);
/// }

/// 2. Remote Data Source 예시
/// abstract class ScheduleRemoteDataSource {
///   Future<List<ScheduleModel>> getSchedules();
///   Future<ScheduleModel> getScheduleById(String id);
///   Future<void> createSchedule(ScheduleModel schedule);
/// }
///
/// class ScheduleRemoteDataSourceImpl implements ScheduleRemoteDataSource {
///   final Dio _dio;
///
///   ScheduleRemoteDataSourceImpl(this._dio);
///
///   @override
///   Future<List<ScheduleModel>> getSchedules() async {
///     try {
///       final response = await _dio.get('/schedules');
///       return (response.data as List)
///           .map((e) => ScheduleModel.fromJson(e))
///           .toList();
///     } catch (e) {
///       throw ServerException(message: e.toString());
///     }
///   }
/// }

/// 3. Local Data Source 예시 (Hive or SharedPreferences)
/// abstract class ScheduleLocalDataSource {
///   Future<List<ScheduleModel>> getSchedules();
///   Future<void> saveSchedules(List<ScheduleModel> schedules);
/// }
///
/// class ScheduleLocalDataSourceImpl implements ScheduleLocalDataSource {
///   final Box<ScheduleModel> _box;
///
///   ScheduleLocalDataSourceImpl(this._box);
///
///   @override
///   Future<List<ScheduleModel>> getSchedules() async {
///     return _box.values.toList();
///   }
/// }

/// 4. Repository 구현
/// class ScheduleRepositoryImpl implements ScheduleRepository {
///   final ScheduleRemoteDataSource remoteDataSource;
///   final ScheduleLocalDataSource localDataSource;
///
///   ScheduleRepositoryImpl({
///     required this.remoteDataSource,
///     required this.localDataSource,
///   });
///
///   @override
///   Future<List<ScheduleEntity>> getSchedules() async {
///     try {
///       final models = await remoteDataSource.getSchedules();
///       await localDataSource.saveSchedules(models);
///       return models.map((e) => e.toDomain()).toList();
///     } catch (e) {
///       final cachedModels = await localDataSource.getSchedules();
///       return cachedModels.map((e) => e.toDomain()).toList();
///     }
///   }
/// }

/// 5. Model 확장 메서드 예시
/// extension ScheduleModelX on ScheduleModel {
///   ScheduleEntity toDomain() {
///     return ScheduleEntity(
///       id: id,
///       title: title,
///       startTime: startTime,
///       endTime: endTime,
///       description: description,
///     );
///   }
/// }
