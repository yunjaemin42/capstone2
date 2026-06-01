import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'app_colors.dart';
import 'config.dart';

class HomeScreen extends StatefulWidget {
  // 🔥 최신 감지 기록을 조회하려면 userId가 필요합니다 (main_screen.dart에서 전달)
  final String userId;
  const HomeScreen({super.key, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _volume = 50;

  Map<String, dynamic>? _latestEvent; // 가장 최근 감지 이벤트
  String? _currentClipUrl; // 현재 재생 중인 클립 주소 (중복 로드 방지용)
  VideoPlayerController? _videoController;
  Timer? _pollTimer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLatestDetection(); // 진입 시 1회 조회
    // ⏱️ 10초마다 자동으로 최신 감지 확인
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchLatestDetection();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _videoController?.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────
  // 📡 최신 감지 이벤트 조회 (/logs 재활용)
  // ──────────────────────────────────────────────
  Future<void> _fetchLatestDetection() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/logs?user_id=${widget.userId}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List logs = data['data'] ?? [];

        if (logs.isNotEmpty) {
          final latest = logs.first; // 백엔드가 최신순 정렬한다고 가정
          // 🔥 백엔드 필드명 확인 필요: 'clip_url' (10초 클립 영상 주소)
          final clipUrl = latest['clip_url'];

          if (!mounted) return;
          setState(() {
            _latestEvent = latest;
            _isLoading = false;
          });

          // 새로운 클립이 들어왔을 때만 플레이어 교체
          if (clipUrl != null &&
              clipUrl.toString().isNotEmpty &&
              clipUrl != _currentClipUrl) {
            _initVideo(clipUrl);
          }
        } else {
          if (!mounted) return;
          setState(() {
            _latestEvent = null;
            _isLoading = false;
          });
        }
      } else {
        print('최신 감지 조회 실패: ${response.statusCode}');
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      print('최신 감지 조회 에러: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ──────────────────────────────────────────────
  // 🎬 10초 클립 영상 로드
  // ──────────────────────────────────────────────
  Future<void> _initVideo(String url) async {
    final old = _videoController;
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _videoController = controller;
    _currentClipUrl = url;

    try {
      await controller.initialize();
      await controller.setLooping(true); // 10초 클립 반복 재생
      await controller.setVolume(_volume / 100);
      await controller.play();
      if (mounted) setState(() {});
    } catch (e) {
      print('영상 로드 에러: $e');
    }
    await old?.dispose(); // 이전 영상 정리
  }

  // 상태(status)에 따른 색상
  Color _statusColor() {
    final status = _latestEvent?['status'];
    if (status == '위험') return Colors.redAccent;
    if (status == '주의') return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final controller = _videoController;
    final isVideoReady = controller != null && controller.value.isInitialized;
    final actionType = _latestEvent?['action_type']; // 예: 낙상
    final status = _latestEvent?['status'];

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Text(
                  '위험 감지 영상',
                  style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),

                // 📺 감지 구간 클립 (실시간 X, 녹화된 10초 클립)
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: isVideoReady
                        ? FittedBox(
                            fit: BoxFit.cover,
                            clipBehavior: Clip.hardEdge,
                            child: SizedBox(
                              width: controller.value.size.width,
                              height: controller.value.size.height,
                              child: VideoPlayer(controller),
                            ),
                          )
                        : Center(
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white54)
                                : const Text(
                                    '감지된 영상이 없습니다',
                                    style: TextStyle(color: Colors.white54),
                                  ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // 🔊 볼륨 조절 (이제 클립 영상 볼륨을 실제로 제어)
                Row(
                  children: [
                    SvgPicture.asset(
                      'assets/icons/icon_speaker.svg',
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(
                          AppColors.mainBlue, BlendMode.srcIn),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8),
                        ),
                        child: Slider(
                          value: _volume,
                          min: 0,
                          max: 100,
                          activeColor: AppColors.mainBlue,
                          inactiveColor: Colors.blue.shade100,
                          onChanged: (val) {
                            setState(() => _volume = val);
                            _videoController?.setVolume(val / 100);
                          },
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                const Text(
                  '탐지된 행동',
                  style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),

                // 🚨 탐지된 클래스 박스 (예: 낙상)
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: actionType == null
                        ? const Text(
                            '행동 감지 대기 중...',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                status == '위험' || status == '주의'
                                    ? Icons.warning_amber_rounded
                                    : Icons.check_circle_outline,
                                color: _statusColor(),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$actionType',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _statusColor(),
                                ),
                              ),
                              if (status != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '($status)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _statusColor(),
                                  ),
                                ),
                              ],
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}