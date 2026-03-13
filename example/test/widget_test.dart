import 'package:example/main.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('example app shows chart demo entries', (tester) async {
    await tester.pumpWidget(const EqChartExampleApp());
    await tester.pumpAndSettle();

    expect(find.text('EQChart Flutter'), findsWidgets);
    expect(find.text('Pie + Donut'), findsOneWidget);
    expect(find.text('Bar'), findsOneWidget);
    expect(find.text('Line + Area'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Radar'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Radar'), findsOneWidget);
  });
}
