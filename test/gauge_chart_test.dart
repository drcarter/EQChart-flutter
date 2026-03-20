import 'package:eqchart_flutter/src/charts/gauge/gauge_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolveGaugeValue clamps out of range values', () {
    final resolved = resolveGaugeValue(
      const GaugeValue(
        value: 140,
        minValue: 0,
        maxValue: 100,
        label: 'CPU',
      ),
    );

    expect(resolved, isNotNull);
    expect(resolved!.clampedValue, 100);
    expect(resolved.progress, 1);
    expect(resolved.label, 'CPU');
  });

  test('resolveGaugeValue rejects invalid bounds and non-finite input', () {
    expect(
      resolveGaugeValue(
        const GaugeValue(
          value: 50,
          minValue: 10,
          maxValue: 10,
        ),
      ),
      isNull,
    );
    expect(
      resolveGaugeValue(
        const GaugeValue(
          value: double.nan,
          minValue: 0,
          maxValue: 100,
        ),
      ),
      isNull,
    );
    expect(resolveGaugeValue(null), isNull);
  });

  test('resolveGaugeRanges filters invalid ranges and clamps ends', () {
    final ranges = resolveGaugeRanges(
      const <GaugeRange>[
        GaugeRange(startValue: -10, endValue: 40, color: Colors.green),
        GaugeRange(startValue: 80, endValue: 120, color: Colors.red),
        GaugeRange(startValue: 60, endValue: 60, color: Colors.orange),
      ],
      0,
      100,
    );

    expect(ranges, hasLength(2));
    expect(ranges.first.startRatio, 0);
    expect(ranges.first.endRatio, 0.4);
    expect(ranges.last.startRatio, 0.8);
    expect(ranges.last.endRatio, 1);
  });

  test('gauge helpers return stable geometry and points', () {
    final geometry = computeGaugeChartGeometry(
      const Size(320, 220),
      const EqGaugeChartStyle(),
      const EqGaugeChartBehavior(showMinMaxLabels: true),
    );
    final angle = gaugeValueToAngle(0.5, 180, 180);
    final point = gaugePointOnCircle(const Offset(100, 100), 40, angle);

    expect(angle, 270);
    expect(geometry.radius, greaterThan(0));
    expect(geometry.arcRect.width, greaterThan(0));
    expect(point.dx, closeTo(100, 0.001));
    expect(point.dy, closeTo(60, 0.001));
  });

  testWidgets('EqGaugeChart renders without throwing for valid input', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 260,
            child: EqGaugeChart(
              value: GaugeValue(
                value: 72,
                minValue: 0,
                maxValue: 100,
                label: 'CPU Load',
              ),
              ranges: <GaugeRange>[
                GaugeRange(startValue: 0, endValue: 60, color: Colors.green),
                GaugeRange(startValue: 60, endValue: 85, color: Colors.orange),
                GaugeRange(startValue: 85, endValue: 100, color: Colors.red),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(EqGaugeChart), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('EqGaugeChart accepts invalid data and falls back safely', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 220,
            child: EqGaugeChart(
              value: GaugeValue(
                value: 30,
                minValue: 10,
                maxValue: 10,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(EqGaugeChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
