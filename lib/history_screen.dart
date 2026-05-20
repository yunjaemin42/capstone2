import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'app_colors.dart';

class HistoryScreen extends StatefulWidget {
  final String userId;
  const HistoryScreen({super.key, required this.userId});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final String myIp = '172.20.86.203';
  List<dynamic> _logs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    setState(() { _isLoading = true; });
    try {
      final response = await http.get(
        Uri.parse('http://$myIp:5000/api/logs?user_id=${widget.userId}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() { _logs = data['data'] ?? []; });
      } else {
        print('로그 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('로그 조회 에러: $e');
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('날짜 선택', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              // 달력 라이브러리가 들어갈 자리
              Container(
                height: 280,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                alignment: Alignment.center,
                child: const Text('달력 위젯 자리', style: TextStyle(color: Colors.grey)),
              ),
              const SizedBox(height: 32),
              const Text('AI 행동 분석', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              // 도넛 차트 3개 틀
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMockChart('정상 행동 비율', '??%', AppColors.mainBlue),
                    _buildMockChart('이상 행동 지속', '??분', Colors.orange),
                    _buildMockChart('주의 필요 이벤트', '??건', Colors.redAccent),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('이벤트 로그', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.grey),
                    onPressed: _fetchLogs,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _logs.isEmpty
                  ? Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      alignment: Alignment.center,
                      child: const Text('로그 없음', style: TextStyle(color: Colors.grey)),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _logs.length,
                      separatorBuilder: (_, __) => Divider(color: Colors.grey.shade200, height: 1),
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        final status = log['status'] ?? '-';
                        final isWarning = status == '위험' || status == '주의';
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: index == 0
                              ? const BorderRadius.vertical(top: Radius.circular(12))
                              : index == _logs.length - 1
                                ? const BorderRadius.vertical(bottom: Radius.circular(12))
                                : BorderRadius.zero,
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ListTile(
                            leading: Icon(
                              isWarning ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                              color: isWarning ? Colors.redAccent : Colors.green,
                            ),
                            title: Text(
                              '${log['action_type'] ?? '-'} (${log['target_type'] ?? '-'})',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              '${log['detection_time'] ?? '-'}  |  점수: ${log['final_score'] ?? '-'}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isWarning ? Colors.red.shade50 : Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isWarning ? Colors.redAccent : Colors.green,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMockChart(String title, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 6),
          ),
        ),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}