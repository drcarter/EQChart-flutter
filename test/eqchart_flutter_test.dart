import 'package:eqchart_flutter/eqchart_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pie layout normalizes slices to full circle', () {
    final layouts = computePieArcLayout(
      const <PieSlice>[
        PieSlice('A', 40, Colors.red),
        PieSlice('B', 60, Colors.blue),
      ],
      const EqPieChartBehavior(),
    );

    final totalSweep = layouts.fold<double>(
      0,
      (sum, layout) => sum + layout.sweepAngle,
    );

    expect(layouts, hasLength(2));
    expect(totalSweep, closeTo(6.28318, 0.001));
    expect(layouts.first.fraction, closeTo(0.4, 0.001));
  });

  test('bar layout keeps zero baseline inside plot for mixed values', () {
    final layout = computeBarChartLayout(
      const Size(320, 240),
      const <BarSeries>[
        BarSeries(
          name: 'Series',
          color: Colors.red,
          points: <BarDatum>[
            BarDatum('Q1', -2),
            BarDatum('Q2', 6),
          ],
        ),
      ],
      const EqBarChartStyle(),
      const EqBarChartBehavior(),
    );

    expect(
      layout.baselineY,
      inInclusiveRange(layout.plotRect.top, layout.plotRect.bottom),
    );
    expect(layout.bars, hasLength(2));
  });

  test('line layout computes positions for each series point', () {
    final layout = computeLineChartLayout(
      const Size(360, 240),
      const <LineSeries>[
        LineSeries(
          name: 'Traffic',
          color: Colors.blue,
          points: <LineDatum>[
            LineDatum(0, 10),
            LineDatum(1, 20),
            LineDatum(2, 15),
          ],
        ),
      ],
      const EqLineChartStyle(),
      const EqLineChartBehavior(),
    );

    expect(layout.points, hasLength(1));
    expect(layout.points.first, hasLength(3));
    expect(
      layout.points.first.first.position.dx,
      lessThan(layout.points.first.last.position.dx),
    );
  });

  test('radar layout creates one point per axis', () {
    final layout = computeRadarChartLayout(
      const Size(320, 320),
      const <RadarAxis>[
        RadarAxis('sweet'),
        RadarAxis('price'),
        RadarAxis('fresh'),
      ],
      const <RadarSeries>[
        RadarSeries('Apple', Colors.purple, <double>[40, 80, 60]),
      ],
      const EqRadarChartStyle(),
      const EqRadarChartBehavior(),
    );

    expect(layout.axisAngles, hasLength(3));
    expect(layout.seriesPoints.single, hasLength(3));
  });

  testWidgets('public charts render inside a material app', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: <Widget>[
              SizedBox(
                height: 220,
                child: EqPieChart(
                  slices: <PieSlice>[
                    PieSlice('A', 1, Colors.red),
                    PieSlice('B', 2, Colors.blue),
                  ],
                ),
              ),
              SizedBox(
                height: 220,
                child: EqBarChart(
                  series: <BarSeries>[
                    BarSeries(
                      name: 'A',
                      color: Colors.red,
                      points: <BarDatum>[
                        BarDatum('Q1', 3),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(EqPieChart), findsOneWidget);
    expect(find.byType(EqBarChart), findsOneWidget);
  });
}
