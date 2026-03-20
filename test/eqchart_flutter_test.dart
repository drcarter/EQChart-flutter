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

  test('bubble layout creates scaled scatter nodes', () {
    final layout = computeBubbleChartLayout(
      const Size(360, 280),
      const <BubbleDatum>[
        BubbleDatum(x: 10, y: 20, size: 100, color: Colors.red),
        BubbleDatum(x: 40, y: 60, size: 400, color: Colors.blue),
      ],
      const EqBubbleChartStyle(),
      const EqBubbleChartBehavior(),
    );

    expect(layout.bubbles, hasLength(2));
    expect(layout.xTicks, hasLength(5));
    expect(layout.yTicks, hasLength(5));
    expect(
        layout.bubbles.first.radius, greaterThan(layout.bubbles.last.radius));
  });

  test('heatmap layout creates blocks and section headers', () {
    final layout = computeStockHeatmapLayout(
      const Size(360, 420),
      const <StockHeatmapSection>[
        StockHeatmapSection(
          name: 'Tech',
          color: Colors.blue,
          stocks: <StockHeatmapItem>[
            StockHeatmapItem(
              symbol: 'AAPL',
              name: 'Apple',
              sector: 'Tech',
              price: 200,
              changePct: 1.2,
              marketCap: 1000,
              sizeRatio: 8,
            ),
            StockHeatmapItem(
              symbol: 'MSFT',
              name: 'Microsoft',
              sector: 'Tech',
              price: 300,
              changePct: -0.4,
              marketCap: 900,
              sizeRatio: 6,
            ),
          ],
        ),
        StockHeatmapSection(
          name: 'Finance',
          color: Colors.brown,
          stocks: <StockHeatmapItem>[
            StockHeatmapItem(
              symbol: 'JPM',
              name: 'JPMorgan',
              sector: 'Finance',
              price: 180,
              changePct: 0.3,
              marketCap: 700,
              sizeRatio: 5,
            ),
          ],
        ),
      ],
      const EqStockHeatmapChartStyle(),
      const EqStockHeatmapChartBehavior(),
    );

    expect(layout.blocks, isNotEmpty);
    expect(layout.headers, isNotEmpty);
  });

  test('waveform min max downsampling preserves segment peaks', () {
    final minMax = computePcmWaveformMinMaxPerPixel(
      <int>[0, 10, -12, 8, 20, -4, 2, -18],
      4,
    );

    expect(minMax, hasLength(8));
    expect(minMax[0], closeTo(0, 0.001));
    expect(minMax[1], closeTo(10 / 32767, 0.001));
    expect(minMax[6], closeTo(-18 / 32767, 0.001));
    expect(minMax[7], closeTo(2 / 32767, 0.001));
  });

  test('waveform controller keeps only the visible recent window', () {
    final controller = EqPcmWaveformController(
      sampleRateHz: 8000,
      windowDurationMs: 200,
    );

    controller.setPcm16Mono(List<int>.generate(2000, (index) => index));
    expect(controller.snapshot(), hasLength(1600));
    expect(controller.snapshot().first, 400);
    expect(controller.snapshot().last, 1999);

    controller.appendPcm16Mono(const <int>[2000, 2001]);
    expect(controller.snapshot().last, 2001);
  });

  test('gauge value resolution clamps into the current domain', () {
    final resolved = resolveGaugeValue(
      const GaugeValue(
        value: 132,
        minValue: 0,
        maxValue: 100,
        label: 'Load',
      ),
    );

    expect(resolved, isNotNull);
    expect(resolved!.clampedValue, 100);
    expect(resolved.progress, 1);
    expect(resolved.label, 'Load');
  });

  testWidgets('public charts render inside a material app', (tester) async {
    final waveformController = EqPcmWaveformController();
    waveformController.setPcm16Mono(const <int>[0, 1200, -600, 300, -150]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                const SizedBox(
                  height: 220,
                  child: EqPieChart(
                    slices: <PieSlice>[
                      PieSlice('A', 1, Colors.red),
                      PieSlice('B', 2, Colors.blue),
                    ],
                  ),
                ),
                const SizedBox(
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
                const SizedBox(
                  height: 220,
                  child: EqBubbleChart(
                    data: <BubbleDatum>[
                      BubbleDatum(
                        x: 10,
                        y: 20,
                        size: 50,
                        color: Colors.orange,
                        label: 'A',
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 220,
                  child: EqGaugeChart(
                    value: GaugeValue(
                      value: 72,
                      minValue: 0,
                      maxValue: 100,
                      label: 'CPU',
                    ),
                    ranges: <GaugeRange>[
                      GaugeRange(
                        startValue: 0,
                        endValue: 70,
                        color: Colors.green,
                      ),
                      GaugeRange(
                        startValue: 70,
                        endValue: 90,
                        color: Colors.orange,
                      ),
                      GaugeRange(
                        startValue: 90,
                        endValue: 100,
                        color: Colors.red,
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 220,
                  child: EqStockHeatmapChart(
                    sections: <StockHeatmapSection>[
                      StockHeatmapSection(
                        name: 'Tech',
                        color: Colors.blue,
                        stocks: <StockHeatmapItem>[
                          StockHeatmapItem(
                            symbol: 'AAPL',
                            name: 'Apple',
                            sector: 'Tech',
                            price: 200,
                            changePct: 1.2,
                            marketCap: 1000,
                            sizeRatio: 8,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 180,
                  child: EqPcmWaveformChart(
                    controller: waveformController,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(EqPieChart), findsOneWidget);
    expect(find.byType(EqBarChart), findsOneWidget);
    expect(find.byType(EqBubbleChart), findsOneWidget);
    expect(find.byType(EqGaugeChart), findsOneWidget);
    expect(find.byType(EqStockHeatmapChart), findsOneWidget);
    expect(find.byType(EqPcmWaveformChart), findsOneWidget);
  });
}
