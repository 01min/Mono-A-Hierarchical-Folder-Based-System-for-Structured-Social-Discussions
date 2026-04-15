import 'package:flutter_test/flutter_test.dart';
import 'package:mono/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Since our app requires DatabaseService initialization in main.dart,
    // we just test the MonoApp widget itself here.
    await tester.pumpWidget(const MonoApp());
    expect(find.byType(MonoApp), findsOneWidget);
  });
}
