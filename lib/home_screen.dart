import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _volume = 50;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, 
            children: [
              const SizedBox(height: 20),
              // 1. 실시간 영상 타이틀 (사진처럼 연한 회색으로!)
              const Text(
                '실시간 영상', 
                style: TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.w500)
              ),
              const SizedBox(height: 12),
              
              // 2. 검은색 영상 박스 (부드러운 그림자 추가)
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. 볼륨 조절 슬라이더
              Row(
                children: [
                  SvgPicture.asset(
                    'assets/icons/icon_speaker.svg',
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(AppColors.mainBlue, BlendMode.srcIn),
                  ),
                  Expanded(
                    // SliderTheme으로 선 굵기랑 동그라미 크기를 디자인과 똑같이 얇게 맞췄어요!
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
              // 4. 현재 상태 타이틀
              const Text(
                '현재 상태', 
                style: TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.w500)
              ),
              const SizedBox(height: 12),

              // 🃏 5. [수정 완료] 원하시던 디자인! "행동 클래스" 하나만 가운데에 띡!
              Container(
                height: 80, // 높이를 아담하게 조절
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16), // 둥근 모서리
                  border: Border.all(color: Colors.grey.shade200), // 아주 연한 테두리
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04), // 은은한 그림자
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    '행동 클래스',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey, // 사진처럼 연한 회색 텍스트
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}