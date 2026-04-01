/// PATCH 요청에서 "미설정"과 "명시적 null"을 구분하기 위한 래퍼.
///
/// Drift의 `Value<T>` 패턴을 차용한 sealed class.
/// Dart에는 JavaScript의 undefined 개념이 없어,
/// json_serializable이 설정하지 않은 필드도 null로 직렬화합니다.
/// 백엔드(FastAPI/Pydantic)는 exclude_unset=True를 사용하여
/// JSON에 존재하는 필드만 "설정됨"으로 판단하므로,
/// 프론트엔드에서 미설정 필드를 JSON에서 제외해야 합니다.
///
/// 사용법:
/// - `PatchValue.absent()` → JSON에서 필드 제외 (변경하지 않음)
/// - `PatchValue.present(null)` → JSON에 null로 포함 (필드 값 제거)
/// - `PatchValue.present(value)` → JSON에 값으로 포함 (필드 업데이트)
sealed class PatchValue<T> {
  const PatchValue();
  const factory PatchValue.present(T? value) = PatchPresent<T>;
  const factory PatchValue.absent() = PatchAbsent<T>;
}

class PatchPresent<T> extends PatchValue<T> {
  final T? value;
  const PatchPresent(this.value);
}

class PatchAbsent<T> extends PatchValue<T> {
  const PatchAbsent();
}

/// PatchValue 맵에서 present 필드만 추출하여 JSON body 생성.
Map<String, dynamic> patchBody(Map<String, PatchValue<dynamic>> fields) {
  return {
    for (final e in fields.entries)
      if (e.value case PatchPresent(:final value)) e.key: value,
  };
}
