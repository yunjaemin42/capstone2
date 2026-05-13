import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'login_screen.dart'; 
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; 
import 'firebase_options.dart';

void main() async {
  // 1. 필수: 플러터 엔진과 상호작용 준비
  WidgetsFlutterBinding.ensureInitialized();

  // 2. 파이어베이스 시동 (firebase_options.dart 파일이 있어야 합니다)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. 알림 권한 요청 (안드로이드 13+ 및 iOS 필수)
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  print('🔔 권한 상태: ${settings.authorizationStatus}');

  // 4. 내 폰의 주소(FCM 토큰)를 뽑아서 터미널에 보여주는 코드
  String? token = await messaging.getToken();
  print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  print("🔥 내 기기 FCM 토큰: $token");
  print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

  // 5. '토픽' 구독 (노드 서버에서 'highfive_alerts' 토픽으로 알림을 보낼 예정입니다)
  await messaging.subscribeToTopic('highfive_alerts');
  print('📢 highfive_alerts 토픽 구독 성공!');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home Secure App', // 프로젝트 제목 확인
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.backgroundLight,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.mainBlue),
        useMaterial3: true,
      ),
      home: const LoginScreen(), 
    );
  }
}