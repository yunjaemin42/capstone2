import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _volume = 50; // 볼륨 UI용 변수만 남김

  @override
  Widget build(BuildContext context) {
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
                  '실시간 영상', 
                  style: TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.w500)
                ),
                const SizedBox(height: 12),
                
                // 📺 [수정됨] 아고라를 걷어낸 깔끔한 영상 빈 틀
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
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.videocam_off, color: Colors.white54, size: 40),
                          SizedBox(height: 12),
                          Text('실시간 영상 송출 기능 대기 중...', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 🔊 볼륨 조절 (UI 틀만 남겨둠)
                Row(
                  children: [
                    SvgPicture.asset(
                      'assets/icons/icon_speaker.svg',
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(AppColors.mainBlue, BlendMode.srcIn),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2, 
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                        ),
                        child: Slider(
                          value: _volume,
                          min: 0,
                          max: 100,
                          activeColor: AppColors.mainBlue,
                          inactiveColor: Colors.blue.shade100,
                          onChanged: (val) {
                            setState(() {
                              _volume = val;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                const Text(
                  '현재 상태', 
                  style: TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.w500)
                ),
                const SizedBox(height: 12),

                // 행동 클래스 박스
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
                  child: const Center(
                    child: Text(
                      '행동 감지 대기 중...', // 조금 더 자연스럽게 문구 수정
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
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