import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:simple_calc/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('Calculator app loads with the upgraded controls', (WidgetTester tester) async {
    await tester.pumpWidget(const CalcApp());
    await tester.pumpAndSettle();

    expect(find.text('Simple Calc'), findsOneWidget);
    expect(find.text('0'), findsWidgets);
    expect(find.text('M+'), findsOneWidget);
    expect(find.text('='), findsOneWidget);

    await tester.tap(find.byTooltip('Show scientific mode'));
    await tester.pumpAndSettle();

    expect(find.text('sin'), findsOneWidget);
    expect(find.text('log'), findsOneWidget);

    await tester.tap(find.byTooltip('Open history'));
    await tester.pumpAndSettle();

    expect(find.text('No calculations yet'), findsOneWidget);
  });
}
