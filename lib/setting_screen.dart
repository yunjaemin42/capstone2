import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'app_colors.dart';
import 'config.dart';

class SettingScreen extends StatefulWidget {
  final String userId;
  const SettingScreen({super.key, required this.userId});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  int _sensitivity = 1; // 0: 둔감, 1: 보통, 2: 민감
  bool _isSaving = false;
  bool _isLoadingCurrent = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentSensitivity();
  }

  static const _toStr = {0: 'low', 1: 'mid', 2: 'high'};
  static const _toInt = {'low': 0, 'mid': 1, 'high': 2};

  Future<void> _loadCurrentSensitivity() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/user-info?user_id=${widget.userId}'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final val = _toInt[data['sensitivity']];
        if (val != null && mounted) {
          setState(() => _sensitivity = val);
        }
      }
    } catch (_) {
      // 불러오기 실패 시 기본값(보통) 유지
    } finally {
      if (mounted) setState(() => _isLoadingCurrent = false);
    }
  }

  Future<void> _saveSensitivity() async {
    setState(() => _isSaving = true);
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/settings'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.userId,
          'sensitivity': _toStr[_sensitivity],
        }),
      ).timeout(const Duration(seconds: 5));

      if (!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('설정이 저장되었습니다.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: ${response.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('서버 연결 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('민감도 설정', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _isLoadingCurrent
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: RadioGroup<int>(
                        groupValue: _sensitivity,
                        onChanged: (val) => setState(() => _sensitivity = val!),
                        child: Column(
                          children: const [
                            RadioListTile<int>(
                              title: Text('둔감'),
                              value: 0,
                            ),
                            RadioListTile<int>(
                              title: Text('보통'),
                              value: 1,
                            ),
                            RadioListTile<int>(
                              title: Text('민감'),
                              value: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
              const SizedBox(height: 16),
              const Text(
                '민감도 설정을 통해 알림 빈도와 배터리 소모를 줄여 감지를 최적화합니다.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveSensitivity,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mainBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('저장', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}