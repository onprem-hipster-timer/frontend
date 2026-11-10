# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

#### Calendar
- 달력 위쪽을 화면 이름 줄(왼쪽 '달력', 오른쪽 필터)과 도구 줄(왼쪽 ‹ 오늘 › 와 보는 기간, 오른쪽 보기 고르기)로 나눈다. 보는 기간(월·주·일)은 화살표·넘기기·날짜 고르기에 따라 바로 바뀌고, 누르면 날짜를 골라 그날로 간다. 달력 위의 빈 머리글 자리를 없앤다
- 화살표·넘기기는 보는 기간만 옮기고 고른 날은 둔다. 일·주 보기로 바꾸면 고른 날이 든 기간을 보인다
- '오늘' 버튼은 이전·다음 사이에 두고, 보는 기간에 오늘이 없으면 채워 그린다. 폭 600 미만에서는 주·일 기간을 줄여 쓴다(예: '11.29 – 12.5', '11월 9일 (월)')
- 폭 600 미만에서는 보기(일간·주간·월간·목록)를 지금 보기 아이콘의 메뉴로 고른다. 360 폭에서 달력 앱바가 넘치지 않는다
- 달력 보기 설정(공휴일 표시, 주말 강조, 24시간제, 주 시작 요일, 월 보기 칸의 일정 수)을 기기에 저장한다. 공휴일 표시를 끄면 공휴일 이름·색을 보이지 않는다
- 월 보기 칸의 일정 수는 기본이 '자동'이다. 칸 높이와 글자 배율로 11pt 일정 줄(18 × 배율)이 들어가는 만큼 1~6개를 보이고 나머지는 '+N'으로 보인다
- 달력 앱바의 메뉴 버튼이 달력 보기 설정 서랍을 연다

#### Network
- 불러오기가 실패하면 연결 실패·시간 초과·502·503·504일 때만 0.5·1·1.5초 뒤 세 번(합 3초) 다시 받고, 그 밖의 실패는 바로 오류와 '다시 시도'를 보인다. 이전에는 모든 실패를 1~2분 동안 다시 받는 사이 불러오는 중만 보였다
- 태그 그룹·타이머 목록·타이머 기록 조회가 실패를 감싸지 않고 그대로 넘긴다

#### Timer
- 타이머 시작·일시정지·재개·정지를 REST(`POST /v1/timers`, `PATCH /v1/timers/{id}/pause`·`resume`, `POST /v1/timers/{id}/stop`)로 보낸다
- 타이머 REST 요청에 `timezone=UTC`를 붙인다
- 경과 시간 표시를 `displayElapsed` 하나로 통일 (RUNNING: `elapsed_time + (now - started_at)`, 그 외: `elapsed_time`)
  - 타이머 화면, 일정 상세의 타이머 목록, Todo 목록이 같은 계산을 쓴다
  - `now`는 타이머 REST 응답의 `Date` 헤더로 보정한 서버 기준 시각이다
- 타이머 화면은 남은 시간(`allocated_duration - displayElapsed`, 0 아래로 내려가지 않음)을 센다
  - 0이 되면 `00:00:00`과 '시간 종료'로 표시한다
  - 타이머 목록의 진행 중·일시정지 항목도 남은 시간, 끝난 항목은 경과 시간을 보여 준다
- 새 타이머의 기본 집중 시간(`allocated_duration`)을 25분으로. 새 작업 시작에서 1~600분을 입력하거나 15·25·45·60분 칩으로 채운다
- 타이머 화면의 정지를 '완료'로 표시 (버튼, 확인 다이얼로그, 알림). 일시정지·재개는 확인 없이 바로 보낸다
- 일시정지·재개는 누르는 즉시 대시보드와 타이머 목록에 반영하고 REST는 뒤에서 보낸다
  - 일시정지는 서버 기준 시각의 경과 시간으로 멈추고, 재개는 지금부터 다시 센다. 응답이 오면 응답 값으로 바꾸고, 실패하면 되돌린 뒤 알린다
  - 명령 중에 대시보드·목록 버튼을 스피너로 바꾸지 않는다. 새 타이머 시작만 응답을 기다리며 시작 버튼 안에 진행 표시를 둔다
  - 응답을 기다리는 타이머에 겹친 일시정지·재개·연장은 보내지 않는다. 완료는 그 응답(실패도)을 받은 뒤에 보내고, 같은 타이머의 완료를 연달아 눌러도 한 번만 보낸다
- 타이머 화면 대시보드에 60분 다이얼을 두고 남은 시간을 12시부터 시계 방향으로 채운 원판으로 보여 준다
  - 활성 타이머가 없으면 다이얼을 끌어 새 작업의 집중 시간을 고르고, 새 작업 시작의 분 칸이 그 값으로 열린다
  - 다이얼을 끄는 동안 원판은 10초 단위로 따라가고 시계는 놓으면 고를 30초 단위 값을 보인다. 놓으면 가장 가까운 30초(최소 30초)로 맞춰 원판이 짧게 움직인다. 끄는 동안 30초 경계를 넘을 때마다 선택 햅틱을 낸다
  - 시간 정하기의 시·분·초 바퀴는 웹·데스크톱에서도 마우스로 끌어 돌린다
  - 고르는 다이얼은 스크린 리더에 '집중 시간'·'휴식 시간' 슬라이더로 보이고 늘리기·줄이기로 30초씩 바꾼다. 키보드로 초점을 옮기면 방향키와 +·-로 30초씩 바꾼다
  - 대기 상태의 시계를 누르면 '시간 정하기' 시트의 시·분·초 바퀴로 작업·휴식 시간을 1초~600분 사이에서 초 단위로 고른다. 0초는 확인할 수 없다
  - 고른 시간은 초까지 그대로 시계에 보이고 새 작업·휴식을 그 시간으로 시작한다. 초가 있으면 새 작업 시작은 분 칸 대신 그 시간과 '변경'을 보이고, 집중 시간 칩을 누르면 분 칸으로 돌아간다
  - 집중 시간이 60분을 넘으면 다이얼 한 바퀴를 60분 단위로 늘린다. 진행 중인 타이머의 다이얼은 끌어도 바뀌지 않는다
  - 위에서부터 작업 제목(Todo 상태·제목·공유 버튼), 다이얼(갤러리와 쪽 표시), 디지털 시계와 일시정지·시간 종료 캡션, 제어 버튼을 두고 다이얼이 남는 높이를 쓴다. 휴식은 '휴식', 대기 상태는 '진행 중인 작업이 없습니다'를 맨 위에 두고 작업·휴식 선택은 제어 버튼 바로 위에 둔다. 상태 표시 칩과 시작 시각은 없앤다
  - 폭 600 미만은 다이얼만 두고 앱 바의 타이머 목록 버튼으로 목록을 바텀 시트로 연다. 600 이상은 다이얼 오른쪽에 타이머 목록을 둔다
  - 높이 400 미만에 폭이 높이의 1.5배 이상인 대시보드(가로 휴대폰)는 다이얼을 왼쪽에, 작업 제목·시계·버튼을 오른쪽에 두고 오른쪽이 칸보다 길면 굴린다
- 시간이 끝난 타이머는 서버가 일시정지 상태로 돌려주며, 대시보드와 타이머 목록은 일시정지·재개 대신 완료와 5분 연장을 보여 준다
  - 연장은 `PATCH /v1/timers/{id}`로 `allocated_duration`을 늘린 뒤 재개한다. 늘리기에 실패하면 재개하지 않는다
  - PATCH 응답이 PAUSED가 아니면(서버가 아직 실행 중으로 둔 타이머) 재개를 보내지 않는다
  - 늘리는 사이 완료하면 늘린 뒤 재개하지 않고 완료한다. '작업을 완료했습니다'는 정지 응답을 받은 뒤에 띄운다
- `displayElapsed`는 RUNNING일 때만 `allocated_duration`을 넘지 않게 자른다. 끝난 타이머와 일시정지 타이머는 저장된 `elapsed_time`을 그대로 보여 준다
- 친구 알림은 타이머 시간 종료(`expire`) 이벤트를 띄우지 않는다. 시간이 끝난 타이머를 친구가 완료하면 정지 알림 하나만 뜬다

#### Timer WebSocket
- 소켓을 수신 전용으로 바꿈. 클라이언트는 45초마다 `ping`만 보낸다
- 소켓 주소를 `REALTIME_BACKEND`(`inprocess`: `/v1/ws/timers`, `cloudflare`: `/realtime/ws`)로 고른다
- 서버 메시지를 이벤트 봉투(`id`·`type`·`from_user`·`timestamp`·`payload`)로 받는다
  - 같은 `id`는 한 번만 반영하고, `updated_at`이 가진 값보다 이전인 타이머는 버린다 (REST 응답에도 같은 규칙)
  - `timer.deleted`를 받은 타이머는 이후 이벤트로 되살리지 않는다
  - 이벤트는 타이머 자체 필드만 갱신하고, 관계 필드(일정·Todo 등)는 REST로 채운다
    (처음 보는 타이머, 연결이 바뀐 타이머, `update` 이벤트는 `GET /v1/timers/{id}`로 다시 받는다)
  - (재)연결마다 REST로 활성 타이머를 다시 맞춘다
- 닫힘 코드별 재연결: `1008`은 JWT를 한 번 새로 받아 다시 연결하고 또 거부되면 멈춘다, `4000`은 바로,
  그 외는 지수 백오프(1s부터 두 배, 상한 30s)와 지터로 횟수 제한 없이 다시 연결한다
- 앱이 포그라운드로 돌아오면 끊긴 소켓을 바로 다시 연결한다
- 친구 알림은 `from_user`가 내가 아닌 이벤트의 `actor_name`·`action`으로 띄운다

#### Todo
- Todo 목록의 누적 집중 시간·태그·하위 Todo 개수를 제목 아래 줄로 옮긴다. 자리가 모자라면 줄을 바꿔 좁은 화면에서도 넘치지 않는다

#### API
- OpenAPI 스펙 v2026.11.09-76cce36 반영 및 API 클라이언트 재생성

#### UI
- 할 일·태그·태그 그룹·일정 폼 시트도 `AppFormSheet` 틀(제목, 칸 사이 20, 버튼 줄)을 쓴다
- 스크린리더가 할 일 줄·타임존의 선택 상태, 활동 요약의 수와 이름을 함께, 태그 관리 버튼의 대상(예: '업무 그룹에 태그 추가')을 읽는다
- 새 작업 시작을 다이얼로그에서 하단 시트(`AppFormSheet`)로 바꾼다. 칸은 '작업 제목', '할 일', '집중 시간'(칩 + '직접 입력' 또는 '정한 시간')이고, 할 일은 할 일 고르기 화면에서 고른다
- 할 일 트리 한 줄을 표시만 하는 `TodoTreeTileView`와 고칠 수 있는 `EditableTodoTreeTile`(끌어 옮기기·선택·펼침·상태·수정·삭제·타이머)로 나눈다
- 모서리 반지름은 `AppRadius` 토큰으로, 상태·공휴일·토요일·경고·차트 색은 `ColorScheme` 역할과 `AppColors`로 그린다. 어두운 테마에서도 같은 역할 색을 쓴다
- 카드 모서리·높이를 테마로 맞춘다(마이페이지 카드도 모서리 12). 할 일 대시보드와 그룹 고르기는 같은 `TodoGroupCard`를, 화면 위 안내는 `AppHintCard`를 쓴다
- 알림을 `showAppSnackBar`로 띄운다. 이전 알림은 닫고, 오류는 error 색·성공은 success 색으로 칠한다. 시트가 열린 채 실패하면 알림을 시트 위에 띄워 가려지지 않는다
- 빈 화면·오류·불러오는 중 표시를 `AppEmptyState`·`AppErrorState`·`AppLoading`으로 맞춘다. 오류에는 화면마다 '다시 시도'와 다른 길(돌아가기 등)을 같은 자리에 두고, 낮은 칸에서는 안내를 굴려 본다
- 확인·선택 다이얼로그를 `lib/shared/ui`로 옮기고 `showAppConfirmDialog`·`showAppChoiceDialog`로 부른다
- 누르면 날짜·시간 선택 창을 여는 줄(할 일 마감일, 일정 시작·종료)을 입력 칸 모양의 `AppPickerField`로 그린다. 이름표는 칸 안에 두고, 일정 시간 오류는 종료 칸 아래에 보인다
- 폼 아래 버튼 줄을 `AppFormActionBar`(취소 + 넓은 저장)로 맞춘다. 공유 설정과 시간 정하기에도 취소가 생기고, 저장 중 진행 표시는 막힌 버튼 위에서도 보이는 색으로 그린다
- 폼의 소제목을 `AppSectionHeader`로 그린다. 일정 폼의 '시작'·'종료'도 다른 폼과 같은 크기로 맞춘다
- 입력 칸은 화면마다 테두리를 정하지 않고 테마의 외곽선(모서리 12)을 따른다. 로그인·가입 입력 칸도 같은 모서리로 맞춘다
- 하단 시트를 `showAppSheet`·`showAppScrollableSheet`로 연다. 모든 시트가 하단 내비게이션까지 덮고, 손잡이·배경·모서리·키보드 여백을 한 곳에서 정한다
- 앱 테마를 `lib/shared/ui/theme`(`AppTheme`, `AppColors`, `AppRadius`)로 모은다. 입력 칸은 모서리 12의 외곽선, 하단 시트는 표면색과 윗모서리 20, SnackBar는 떠 있는 모양이 기본이다

#### Tooling
- Material·Cupertino 위젯을 `material_ui`·`cupertino_ui` 패키지에서 가져온다
- 아키텍처 린트(`packages/momeet_lints`)를 새 analyzer 플러그인(`analysis_server_plugin`)으로 옮긴다. `dart analyze`와 IDE에서 함께 돌고, CI 분석 단계는 `dart analyze --fatal-infos`가 맡는다. `dart run custom_lint` 단계는 없앤다
- 위젯 크기·구조 린트: 위젯·State 클래스 200줄, `build` 80줄, `lib/` 파일 400줄 상한, Widget을 돌려주는 helper 금지, `lib/shared/ui/`의 기능·Riverpod·go_router import 금지. 기존 코드도 모두 이 규칙을 지킨다

### Added

#### Todo
- 할 일 고르기 화면(`showTodoPicker`): 그룹별 트리로 보이고 제목으로 찾으며, 한 줄을 눌러 하나를 고르거나 체크해 여럿을 고른다

#### Timer
- 타이머 화면의 작업 제목 옆에 연결된 Todo의 상태 아이콘. 일시정지 중에는 그 자리에서 상태를 바꾼다
  - `PATCH /v1/todos/{id}`만 보낸다. Todo가 완료·취소되면 서버가 타이머를 끝내고 `timer.updated`로 알린다
  - 바꾼 상태는 PATCH 응답으로 바로 보여 준다. 다른 기기에서 바뀐 Todo는 타이머를 다시 읽을 때 반영하고 Todo 목록도 다시 읽게 한다
- 타이머 화면의 휴식 카운트다운. 기기 안에서만 세고 서버에 보내지 않으므로 타이머 목록에 나오지 않고 친구에게도 알리지 않는다
  - 활성 타이머가 없으면 시작 버튼 위에서 작업·휴식을 고른다. 다이얼로 고른 시간은 작업(기본 25분)과 휴식(기본 5분)이 따로 기억한다
  - 휴식은 다이얼로그 없이 바로 시작한다. 세는 동안은 '휴식 끝내기', 0이 되면 '휴식 종료'와 '확인'으로 닫는다
  - 시간이 남은 일시정지 타이머에서도 휴식을 시작한다. 휴식을 닫으면 그 타이머를 다시 보여 준다
  - 시간이 끝난 타이머에서도 완료·5분 연장 옆의 휴식 버튼으로 휴식을 시작한다. 타이머는 시간 종료 그대로 두고, 휴식을 끝내거나 확인하면 그 타이머를 완료·5분 연장과 함께 다시 보여 준다
  - 내 활성 타이머 중 하나라도 시간이 남은 채 실행 중이면 휴식을 시작하지 않고 휴식 버튼도 두지 않는다. 대시보드에 보이는 타이머가 일시정지여도 같다
  - 내 활성 타이머 중 하나라도 실행되면(재개, 다른 기기, Todo 등) 타이머 화면이 보이지 않아도 휴식을 바로 끝낸다. 시간이 끝난 실행 중 타이머는 휴식을 막지 않는다
  - 로그아웃하거나 다른 계정으로 바뀌면 진행 중인 휴식을 버린다. 다음 계정은 이전 계정의 활성 타이머 없이 시작한다
- 타이머 화면에서 여러 타이머를 함께 다룬다. 활성 타이머가 둘 이상이면 다이얼 자리에 타이머마다 한 쪽씩 다이얼을 둔 갤러리를 옆으로 넘긴다
  - 쪽은 타이머를 만든 순(오래된 것부터)이라 재개·일시정지로 순서가 바뀌지 않고, 새 타이머는 끝 쪽에 붙는다. 보이는 쪽의 타이머를 대시보드가 다룬다. 제목·시계·캡션·제어 버튼·공유 버튼이 그 타이머를 대상으로 한다
  - 갤러리 아래에 쪽 표시를 둔다. 넓은 화면과 웹·데스크톱은 그 양옆에 '이전 타이머'·'다음 타이머' 버튼을 두고, 갤러리에 초점이 있으면 왼쪽·오른쪽 방향키로 넘긴다
  - 활성 타이머가 하나면 갤러리·쪽 표시 없이 그 다이얼만 둔다
  - 기본으로 보이는 타이머는 가장 최근에 시작한 실행 중 타이머, 없으면 가장 최근에 시작한 타이머다. 고른 타이머가 끝나면 기본 타이머의 쪽으로, 새 타이머를 시작하거나 타이머 목록에서 재개·연장하면 그 타이머의 쪽으로 넘어간다
  - 타이머가 늘거나 줄어도 보이던 타이머의 쪽에 머문다. 대시보드에서 일시정지·재개·연장한 타이머는 기본 타이머가 바뀌어도 계속 보인다. 좁은 화면과 넓은 화면이 같은 타이머를 보인다
  - 활성 타이머가 있으면 '새 타이머' 칩을 굴리지 않는 자리에 두고, 다른 타이머가 도는 중에도 새 작업 시작을 연다
  - 휴식 중에는 갤러리와 '새 타이머' 칩을 두지 않는다
- 새 작업 시작에서 할 일을 연결한다 (`POST /v1/timers`의 `todo_id`)
  - 완료·취소한 할 일과 공유받은 할 일을 뺀 내 할 일을 제목으로 찾아 고른다. '연결 안 함'으로 연결을 푼다
  - 작업명이 비었거나 앞서 고른 할 일의 제목 그대로면 고른 할 일의 제목으로 채운다. 작업명 없이 시작하면 할 일 제목, 할 일도 없으면 '새 작업'
  - 할 일 목록을 읽는 동안과 읽지 못했을 때는 할 일 칸을 막는다. 미리 고른 할 일이 있으면 그대로 연결하고, 없으면 연결 없이 시작한다
  - 연결된 타이머를 완료하면 서버가 그 할 일을 완료로 바꾸므로 Todo 목록을 다시 읽는다
  - 체크 상자로 할 일을 여럿 고른다. 할 일을 누르면 그 할 일 하나만 고르고, 둘 이상 체크하면 나오는 'N개 선택 완료'로 고른다. Todo 목록에서 열면 그 Todo를 체크한 채 연다
  - 둘 이상 고르면 작업명 칸을 막고, 할 일마다 같은 집중 시간과 그 할 일의 제목으로 타이머를 하나씩 시작한다. 시작하지 못한 할 일이 있으면 그 제목을 알리고, 시작한 타이머는 그대로 둔다
- 내 타이머의 공유 범위를 고른다. 대시보드의 작업 제목 옆과 타이머 목록 항목에 지금 범위의 아이콘 버튼을 두고, 누르면 공유 설정 시트를 연다
  - 비공개(나만 봄)·친구 공개(모든 친구)·선택한 친구 중 고른다. 설정이 없으면 비공개다. 타이머의 실시간 변경은 주인의 친구에게만 전달된다
  - 선택한 친구는 친구를 하나 이상 골라야 저장하고, 지금 친구인 사람만 보낸다
  - 비공개는 `DELETE /v1/visibility/timer/{id}`, 그 외는 그 범위가 쓰는 목록만 `PUT /v1/visibility/timer/{id}`로 보낸다
  - 저장하면 시트를 닫고 그 타이머를 다시 읽어 대시보드와 목록의 아이콘을 바꾼다. 실패하면 알리고 고른 값을 둔 채 머문다
  - 타이머 목록 항목은 버튼까지 한 줄에 두면 제목 자리가 모자란 폭(휴대폰의 목록 시트, 좁은 창의 목록 칸)에서 버튼을 아래 줄로 내린다
  - 타이머 목록 항목의 일시정지·재개·완료·5분 연장·공유 버튼은 화면 기본 밀도의 탭 영역(휴대폰 48)을 쓴다. 버튼 하나를 48로 잡아 아래 줄로 내릴 폭을 정한다
- 타이머 목록의 머리말 아래에서 '내 타이머'와 '친구 타이머'를 고른다. 친구 타이머는 다른 사용자가 나에게 공유한 타이머(`GET /v1/timers?scope=shared`)를 최근에 시작한 순으로 보기만 한다
  - 주인 이름(친구 목록의 이름, 친구가 아니면 '다른 사용자'), 작업 제목, 상태를 보이고, 진행 중·일시정지면 남은 시간(실행 중이면 서버 기준 시각으로 1초마다), 끝났으면 경과 시간을 보인다
  - 친구 타이머를 고를 때 다시 읽고, 친구의 타이머 이벤트가 오면 마지막 이벤트 뒤 0.5초를 기다려 한 번 다시 읽는다
  - 내 타이머·친구 타이머가 없다는 안내는 칸이 낮으면(가로 휴대폰, 좁은 화면의 목록 시트) 넘치지 않고 굴려 본다

#### Todo
- Todo 목록에 하위 Todo를 포함한 누적 집중 시간
  - 끝난(COMPLETED) 타이머의 경과 시간에 진행 중·일시정지 타이머의 `displayElapsed`를 더해 1초마다 갱신한다
  - 취소한 타이머는 더하지 않는다. 활성 타이머가 끝나면 타이머 목록을 다시 읽는다
- Todo·일정 삭제 시 서버가 연결 타이머 처리(`linked_timer_policy`)를 요구하면 '연결만 해제'·'타이머 삭제' 중 골라 다시 삭제한다
- Todo 목록에서 바로 타이머를 시작한다. 완료·취소하지 않은 내 Todo에 타이머 시작 버튼을 두고, 그 Todo를 고른 새 작업 시작 다이얼로그를 연다
  - 시작해도 할 일 화면에 머문다. '타이머를 시작했습니다' 알림의 '타이머 보기'로 타이머 화면에 간다. 실패하면 알린다
  - 연달아 시작하면 떠 있던 알림을 닫고 새 알림을 띄워 알림이 쌓이지 않는다
  - 진행 중·일시정지 타이머가 있으면 버튼 대신 남은 시간(mm:ss, 한 시간 이상은 h:mm:ss, 0이면 에러 색)을 1초마다 보여 주고, 누르면 타이머 화면으로 간다

#### Config
- `REALTIME_BACKEND` 환경변수 (배포 시 GitHub vars에서 `.env`로 전달)

#### Tests
- 레이아웃 점검 테스트 라이브러리(`packages/layout_audit`): 모든 위젯 테스트 끝에 화면에 남은 글자·이미지의 겹침(가린 비율·가리는 위젯 포함), RenderFlex 넘침, 잘라냄, 화면 이탈, 말줄임을 찾아 보고한다
  - 기본은 경고만 남기고 통과한다. `--dart-define=LAYOUT_AUDIT_STRICT=true`면 warning이 있을 때 실패한다
  - 결과는 `build/layout_audit/*.md`에 남고, GitHub Actions에서는 해당 소스 줄 어노테이션과 잡 요약 표로 표시된다
  - `LAYOUT_AUDIT=off`로 끄고, `LAYOUT_AUDIT_VIEWPORT`·`LAYOUT_AUDIT_TEXT_SCALE`로 스위트 전체를 다른 화면·배율로 돌린다
- Todo 트리 타일, 타이머 목록 항목, 마이페이지 태그 통계, 달력 일정 블록에 화면 크기 16종 × 글자 배율 × 긴 텍스트 조합 레이아웃 점검 테스트
- 렌더링 테스트 뷰포트 프리셋을 `packages/layout_audit`로 옮기고 iPhone SE·mini, Z Flip, Surface Duo, 폴드 내부, 가로 폰 추가

### Removed

#### UI
- 화면에 연결되지 않은 위젯을 지운다: `TodoTreeTileWithTimer`·`TimerControlButtons`·`TodoTreeWithTimerListView`, `TodoListPage`, `ScheduleCreateDialog`

#### Timer WebSocket
- WebSocket 명령(`timer.create`·`pause`·`resume`·`stop`·`sync`)과 `timer.sync_result`·`timer.friend_activity` 처리
- 소켓 연결의 `timezone` 쿼리

### Fixed

#### Timer
- 일시정지·재개가 실패하면 응답을 기다리는 사이 연결된 할 일이 바뀌었어도 이전 상태로 되돌린다. 바뀐 할 일은 둔다
- 로그인한 사용자가 바뀌면 이전 사용자의 활성 타이머를 버린다. 새 사용자의 첫 조회가 실패하거나 이전 사용자의 목록이 늦게 와도 보이지 않는다
- 같은 타이머의 응답·이벤트가 같은 `updated_at`(초 단위)으로 오면 `pause_history`가 더 긴 값을 반영한다. 기록 길이도 같으면 가진 값을 둔다. 늦게 도착한 이전 상태를 잠깐 보이지 않는다
- 이 클라이언트가 보낸 명령의 응답은 `updated_at`과 `pause_history` 길이가 가진 값과 같아도 반영한다. 같은 초에 재개한 뒤 연장해도 늘린 시간이 보인다. 실시간 이벤트와 다시 읽은 목록은 같으면 가진 값을 두고, 끝난 타이머는 명령 응답으로도 다시 활성이 되지 않는다
- 끝난(완료·취소) 타이머는 그 뒤에 오는 응답·이벤트·목록의 끝나지 않은 값으로 다시 활성이 되지 않는다. 끝난 값은 `updated_at`이 더 이전이어도 반영한다
  - 가진 활성 타이머가 다시 맞춘 활성 목록에 없으면 끝난 것으로 보고, 그 뒤 늦게 온 명령 응답·이벤트로 되살리지 않는다. 목록을 받은 뒤 만들어진 타이머는 이벤트로 넣는다
  - 끝난 타이머에는 일시정지·재개를 응답 전에 먼저 보이지 않는다
- 휴식은 타이머와 같은 서버 기준 시각으로 끝나는 시각과 남은 시간을 센다. 기기 시계가 서버와 어긋나도 휴식이 길어지거나 짧아지지 않는다

#### Timer WebSocket
- 소켓이 다시 연결되면 연결 오류 배너를 지운다
- 관계 필드를 채우는 `GET /v1/timers/{id}`가 실패하면 2·4·8초 뒤 다시 받는다. 그 사이 다른 REST 응답으로 채워졌거나 지워진 타이머는 다시 받지 않는다

#### Todo
- 할 일 대시보드가 그룹을 불러오지 못했을 때 '다시 시도'를 누르면 그룹을 다시 받는다
- 할 일 그룹 화면이 할 일을 불러오지 못했을 때 '다시 시도'를 누르면 그 그룹의 할 일을 다시 받는다
- 누적 집중 시간의 타이머 목록 조회(`GET /v1/timers`)도 타이머 REST 요청으로 보내 `timezone=UTC`를 붙이고 응답의 `Date` 헤더로 서버 시각을 맞춘다

#### Calendar
- 00:00에 시작해 23:59에 끝나는 일정(일정 폼의 종일)을 종일로 본다. 폼에서 종일로 만든 일정을 수정하려고 열면 종일이 켜져 있다
- 달력이 일정을 불러오지 못했을 때 '다시 시도'를 누르면 일정을 다시 받는다
- 일정 만들기·수정 시트가 디버그 빌드에서 종일 스위치 때문에 오류로 그려지지 않던 문제를 고친다. 시트 배경을 시트 자체에 칠한다

#### MyPage
- 활동 요약이 통계를 불러오지 못했을 때 '다시 시도'를 누르면 할 일 목록을 다시 받는다

#### Settings
- 타임존 선택 시트가 디버그 빌드에서 목록 항목 때문에 오류로 그려지지 않던 문제를 고친다. 시트 배경을 시트 자체에 칠한다

#### Tag
- 태그 관리 화면이 태그를 불러오지 못했을 때 '다시 시도'를 누르면 태그 그룹을 다시 받는다

#### Auth
- 기존 계정에 Google을 연결하는 로그인(`/login?flow=`)도 계정이 이메일 인증 전이면 서버가 다시 보낸 코드로 인증 화면을 연다. 인증 화면에는 연결할 계정 이메일을 넘긴다

---

## [v2026.06.24-079c3c0] - 2026-06-24

### Changed

#### Auth
- 인증을 Supabase에서 Ory Kratos로 이전 (backend `/auth` 프록시를 거친 API 플로우, 쿠키 없음)
  - Kratos 세션 토큰은 SharedPreferences(웹은 localStorage)에 두고, 앱 상태에는 백엔드용 JWT(10분)만 둔다
  - JWT는 요청 직전에 만료가 가까우면 새로 받고, 401이면 한 번 새로 받아 재시도한다
  - WebSocket은 (재)연결할 때마다 최신 JWT를 쓰고, JWT 갱신만으로는 다시 연결하지 않는다
  - 비밀번호 변경도 메일로 받은 코드로 한다(비밀번호 재설정 화면). 현재 비밀번호만으로는 바꿀 수 없어서,
    비밀번호가 새도 메일 확인 없이 비밀번호를 바꿔 계정을 차지하지 못한다
  - 이메일 인증 전에는 로그인할 수 없다. 가입하면 인증 화면으로, 인증을 마치면 로그인 화면으로 간다.
    인증 전 로그인 시도는 서버가 다시 보낸 코드로 인증 화면을 연다
  - 가입 비밀번호 최소 길이를 Kratos 정책인 8자로 맞춤

#### Todo & Schedule Mutations
- Todo·Schedule CUD 흐름을 Riverpod `Mutation` API 기반 command 패턴으로 전환
  - 기존 mutation notifier의 `AsyncValue` 로딩/성공/실패 상태 관리를 제거하고, REST 호출 및 관련 provider invalidation 책임만 유지
  - `mutation.run(..., (tsx) => tsx.get(...notifier).xxx())` 호출 패턴으로 통일해 작업 중 provider 생존과 완료 후 캐시 갱신을 보장
  - Todo 생성/수정/삭제/상태변경/부모변경, Schedule 생성/수정/삭제/이동/리사이즈/TODO 변환 호출부를 새 패턴으로 전환
- Todo 삭제 실패 처리를 bool 반환 대신 원래 예외를 전파하는 방식으로 통일

### Added

#### Auth
- 이메일 인증 화면(`/verification`)과 인증 오류 화면(`/auth-error`)
- 코드 기반 비밀번호 재설정 (이메일 → 6자리 코드 → 새 비밀번호)
- 웹 Google 로그인 ("Google로 계속하기", 로그인·회원가입 화면)
  - 서버(Kratos)가 Google을 켰을 때만 버튼이 보인다
  - Google을 다녀온 브라우저는 로그인 화면(`/login?code=`)으로 돌아오고, 로그인 화면이 세션 토큰 교환으로 로그인을 마친다
  - 로그인 뒤 원래 화면으로 가는 처리는 비밀번호 로그인과 같은 `redirect` 검사를 탄다
  - 이 브라우저에서 시작하지 않은 복귀 링크는 교환하지 않고 보안 경고 화면으로 보낸다
  - Google 이메일로 이미 가입된 계정이 있으면 로그인 화면(`/login?flow=`)이 그 계정 이메일을 고정해 비밀번호를 받고, 로그인하면서 Google을 계정에 연결한다
    (같은 이메일의 Google만 연결되므로 비밀번호가 새도 남의 Google을 붙일 수 없다)

#### Security
- 메일 인증 링크(`/verification?flow=`)와 Google 복귀 링크(`/login?code=`)의 값이 올바른 모양이 아니면 보안 경고 화면으로 보낸다

#### Tests
- Todo·Schedule mutation 도메인별 테스트 추가
  - CUD REST API 호출 검증
  - provider invalidation 후 재조회 검증
  - `Mutation` 성공/실패 상태 및 원래 예외 전파 검증

### Removed

#### Auth
- `supabase`, `supabase_flutter` 의존성과 `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY` 설정

#### Tests
- ref.mounted 가드 기반 공용 dispose 안전성 테스트 제거
  - Mutation 기반 도메인 테스트로 검증 범위 대체

---

## [v2026.06.16-ad57845] - 2026-06-16

### Changed

#### Timer WebSocket
- 백엔드 Timer WebSocket 스펙 재검토 반영
  - `timer.friend_activity` payload에 `display_name`(nullable) 필드 추가
  - `timer.updated` payload의 `timer`를 nullable로 변경 — `timer.sync` 단건 조회 대상이 없으면 `null`이 올 수 있어, 수신 처리에 null guard 추가(활성 타이머 없음으로 처리)
  - 백엔드 공식 메시지 타입이 아닌 `timer.completed` / `timer.synced` fallback 처리 제거

---

## [v2026.04.04-bedf04d] - 2026-04-04

### Fixed

#### Core Infrastructure
- PATCH 요청에서 null 필드가 직렬화되어 백엔드가 의도치 않게 필드를 초기화하는 버그 수정 (#29, #32, #33, #34)
  - `build.yaml`에 `include_if_null: false` 설정 추가
  - `ExplicitNullInterceptor` 도입으로 명시적 null 전송 지원
  - `explicitNulls()` 헬퍼 함수로 호출부 간소화
- Todo 수정 시 `parent_id` 보존하여 트리 관계 유지
- Todo, Schedule, TagGroup 수정 폼에서 description 비우기 반영

#### Landing & Loading
- landing → 앱 전환 시 로딩 화면 탈출 불가 버그 수정
- 랜딩 페이지 앵커 클릭 시 경로 전환 버그 수정
- 모바일 가로 스크롤 및 배경 blob 잘림 수정
- Flutter 부트스트랩 `hostElement` 무시 및 아이콘 폰트 깨짐 수정
- 인증 유저 루트 진입 시 랜딩 대신 앱으로 직행하도록 수정

#### API
- API 모델에서 제거된 `isTodoGroup` 필드 참조 제거

### Added

#### Landing & Loading
- Flutter 로딩 중 표시할 정적 랜딩 페이지 추가 (`web/landing/`)
- 랜딩/로딩 페이지 분리 및 Flutter 부트스트랩 개선
- 생산성 아이콘 SVG 순환 애니메이션 로딩 화면
- 시뮬레이션 프로그레스 바 추가
- 앱 아이콘/프리뷰 이미지 및 noscript 대응
- 미인증 루트 접근 시 `/landing` 리다이렉트

#### API
- `openapi.json` 기반 REST 클라이언트 재생성
- `VisibilityLevel`, `VisibilityRead`, `VisibilityUpdate`, `ResourceType` 등 신규 모델 추가
- `MeetingCreate`, `MeetingUpdate` 등 미팅 관련 모델 추가

#### Core Infrastructure
- Flutter project setup with FVM (stable channel)
- Feature-first + Shared layer architecture
- GoRouter routing configuration
- Riverpod 3.x state management with code generation
- Dio + Retrofit HTTP client layer
- Supabase authentication integration
- Hive + SharedPreferences local storage

#### API Layer
- Retrofit API clients for all backend endpoints
  - Schedules, Todos, Timers, Tags, Friends, Holidays, Health, GraphQL
- Freezed data models with JSON serialization
  - ScheduleRead/Create/Update, TodoRead/Create/Update, TimerRead/Update
  - TagRead/Create/Update, TagGroupRead/Create/Update
  - FriendRead, FriendshipRead, PendingRequestRead
  - VisibilitySettings, HolidayItem, ValidationError

#### Features
- **Auth**: Supabase login/signup flow
- **Calendar**: Syncfusion-based calendar with schedule management
  - Calendar state management (Freezed)
  - Schedule mutations provider
  - Holiday provider integration
- **Todo**: Todo list with tag integration
  - Timer providers for todo-linked timers
  - Tag providers for todo tagging
- **Timer**: Timer management with schedule/todo linking
- **Tag**: Tag and tag group management
- **Home**: Home screen

#### Shared Components
- `AppScaffold` — common scaffold widget
- `ScaffoldWithNav` — navigation scaffold
- Shared API providers
- App configuration (`app_config.dart`)

---

## Version History Format

### Types of Changes

- **Added**: New features
- **Changed**: Changes in existing functionality
- **Deprecated**: Soon-to-be removed features
- **Removed**: Removed features
- **Fixed**: Bug fixes
- **Security**: Security vulnerability fixes

---

[Unreleased]: https://github.com/onprem-hipster-timer/frontend/compare/v2026.06.24-079c3c0...HEAD
[v2026.06.24-079c3c0]: https://github.com/onprem-hipster-timer/frontend/compare/v2026.06.16-ad57845...v2026.06.24-079c3c0
[v2026.06.16-ad57845]: https://github.com/onprem-hipster-timer/frontend/compare/v2026.04.04-bedf04d...v2026.06.16-ad57845
[v2026.04.04-bedf04d]: https://github.com/onprem-hipster-timer/frontend/compare/main...v2026.04.04-bedf04d
