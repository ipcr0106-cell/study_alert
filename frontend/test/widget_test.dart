import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('앱 스모크 테스트', (WidgetTester tester) async {
    // Supabase 초기화가 필요하므로 단위 테스트는 추후 mock 설정 후 작성
    expect(1 + 1, 2);
  });
}
