/// 라우팅 설정
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:momeet/features/home/presentation/pages/home_page.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),
    // 추가 라우트는 여기에 작성
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('오류')),
    body: Center(
      child: Text('페이지를 찾을 수 없습니다: ${state.error}'),
    ),
  ),
);
