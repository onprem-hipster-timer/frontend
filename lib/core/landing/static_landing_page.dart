import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/landing/static_landing_bridge.dart'
    if (dart.library.js_interop) 'package:momeet/core/landing/static_landing_bridge_web.dart';

/// 랜딩 라우트. 랜딩은 web/index.html의 정적 HTML이라 Flutter는 빈 화면이고, 뜰 때 정적 랜딩을 보이게 한다.
///
/// GoRouter는 주소를 history API로 바꿔 hashchange가 일어나지 않으므로, 라우터가 /landing으로 보낼 때
/// (세션 확인 실패, 로그아웃 등) 정적 랜딩이 저절로 나타나지 않는다.
class StaticLandingPage extends StatefulWidget {
  const StaticLandingPage({super.key});

  @override
  State<StaticLandingPage> createState() => _StaticLandingPageState();
}

class _StaticLandingPageState extends State<StaticLandingPage> {
  @override
  void initState() {
    super.initState();
    showStaticLanding();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
