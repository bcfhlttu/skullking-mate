import 'package:flutter_test/flutter_test.dart';
import 'package:skullking_mate/main.dart';

void main() {
  testWidgets('앱이 정상적으로 빌드된다', (tester) async {
    await tester.pumpWidget(const SkullKingMateApp());
    expect(find.text('스컬킹 메이트'), findsOneWidget);
  });
}
