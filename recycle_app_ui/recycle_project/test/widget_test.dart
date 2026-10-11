import 'package:flutter_test/flutter_test.dart';
import 'package:recycle_project/main.dart';

void main() {
  testWidgets('앱이 정상적으로 실행되는지 확인', (WidgetTester tester) async {
    await tester.pumpWidget(const RecycleApp());
  });
}
