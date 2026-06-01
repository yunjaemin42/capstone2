class AppConfig {
  // 서버 IP를 여기 한 곳만 바꾸면 모든 화면에 적용됩니다.
  static const String serverIp = '172.25.172.181';

  static const String apiBaseUrl = 'http://$serverIp:5000/api';
  static const String streamUrl = 'http://$serverIp:8888/live';
}
