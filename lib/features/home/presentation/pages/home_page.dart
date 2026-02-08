// 홈 화면
import 'package:flutter/material.dart';
import 'package:momeet/shared/widgets/app_scaffold.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'MoMeet',
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'MoMeet 프로젝트 구조 설정 완료! 🎉',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Text(
              'Feature-based Clean Architecture',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
