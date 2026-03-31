import 'dart:async';

import 'package:eqchart_flutter/eqchart_flutter.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'sample_data.dart';

void main() {
  runApp(const EqChartExampleApp());
}

class EqChartExampleApp extends StatelessWidget {
  const EqChartExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0E8A76),
      surface: const Color(0xFFF4F7FA),
    );

    return MaterialApp(
      title: 'EQChart Flutter',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const _ExampleScrollBehavior(),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFFF4F7FA),
        textTheme: Typography.blackCupertino.apply(
          bodyColor: const Color(0xFF132636),
          displayColor: const Color(0xFF132636),
        ),
      ),
      home: const ExampleHomePage(),
    );
  }
}

class _ExampleScrollBehavior extends MaterialScrollBehavior {
  const _ExampleScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => <PointerDeviceKind>{
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.unknown,
      };
}

class ExampleHomePage extends StatelessWidget {
  const ExampleHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final demos = <_DemoEntry>[
      _DemoEntry(
        title: 'Pie + Donut',
        subtitle: 'Selection, labels, center text',
        accent: const Color(0xFFEF476F),
        builder: (_) => const PieDonutDemoPage(),
      ),
      _DemoEntry(
        title: 'Bar',
        subtitle: 'Grouped, stacked, negative baseline',
        accent: const Color(0xFF2B80FF),
        builder: (_) => const BarDemoPage(),
      ),
      _DemoEntry(
        title: 'Line + Area',
        subtitle: 'Multi-series lines and filled trends',
        accent: const Color(0xFF13C3A3),
        builder: (_) => const LineAreaDemoPage(),
      ),
      _DemoEntry(
        title: 'Radar',
        subtitle: 'Polygon grid, labels, multi-series',
        accent: const Color(0xFF8A79FF),
        builder: (_) => const RadarDemoPage(),
      ),
      _DemoEntry(
        title: 'Bubble',
        subtitle: 'Scatter scales and packed cluster layout',
        accent: const Color(0xFF4A7FB1),
        builder: (_) => const BubbleDemoPage(),
      ),
      _DemoEntry(
        title: 'Heatmap',
        subtitle: 'Sectioned treemap colored by change %',
        accent: const Color(0xFFF4511E),
        builder: (_) => const HeatmapDemoPage(),
      ),
      _DemoEntry(
        title: 'Box Plot',
        subtitle: 'Quartiles, whiskers, outliers, median labels',
        accent: const Color(0xFF2563EB),
        builder: (_) => const BoxPlotDemoPage(),
      ),
      _DemoEntry(
        title: 'Histogram',
        subtitle: 'Bucket ranges, baseline, animated bars',
        accent: const Color(0xFF14B8A6),
        builder: (_) => const HistogramDemoPage(),
      ),
      _DemoEntry(
        title: 'Range Bar',
        subtitle: 'Timeline intervals on a shared axis',
        accent: const Color(0xFF0F766E),
        builder: (_) => const RangeBarDemoPage(),
      ),
      _DemoEntry(
        title: 'Gauge',
        subtitle: 'Threshold ranges, ticks, animated needle',
        accent: const Color(0xFFFFB703),
        builder: (_) => const GaugeDemoPage(),
      ),
      _DemoEntry(
        title: 'Waveform',
        subtitle: 'PCM min/max renderer with live append',
        accent: const Color(0xFF62D5FF),
        builder: (_) => const WaveformDemoPage(),
      ),
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Color(0xFF0D3B66),
                    Color(0xFF0E8A76),
                    Color(0xFFF4F7FA),
                  ],
                  stops: <double>[0, 0.55, 1],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'EQChart Flutter',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 440,
                    child: Text(
                      'Painter-based charts mirroring the Android EQChart demos, rebuilt for Flutter with reusable widgets and a focused example app.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white.withOpacity(0.86),
                            height: 1.35,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            sliver: SliverList.separated(
              itemBuilder: (context, index) {
                final demo = demos[index];
                return _DemoCard(entry: demo);
              },
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemCount: demos.length,
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoEntry {
  const _DemoEntry({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.builder,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final WidgetBuilder builder;
}

class _DemoCard extends StatelessWidget {
  const _DemoCard({required this.entry});

  final _DemoEntry entry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: entry.builder),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: <Widget>[
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: entry.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.auto_graph_rounded, color: entry.accent),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      entry.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF5F7183),
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class PieDonutDemoPage extends StatefulWidget {
  const PieDonutDemoPage({super.key});

  @override
  State<PieDonutDemoPage> createState() => _PieDonutDemoPageState();
}

class _PieDonutDemoPageState extends State<PieDonutDemoPage> {
  var _showLabels = true;
  String _selection = 'Tap a slice to inspect it.';

  @override
  Widget build(BuildContext context) {
    final behavior = EqPieChartBehavior(
      showLabels: _showLabels,
      centerText: '100%',
      centerSubText: 'Team Split',
    );

    return _DemoScaffold(
      title: 'Pie + Donut',
      controls: <Widget>[
        SwitchListTile.adaptive(
          value: _showLabels,
          contentPadding: EdgeInsets.zero,
          title: const Text('Show labels'),
          onChanged: (value) => setState(() => _showLabels = value),
        ),
      ],
      footerText: _selection,
      children: <Widget>[
        _ChartPanel(
          title: 'Traffic sources',
          subtitle: 'Pie chart with slice selection',
          child: SizedBox(
            height: 320,
            child: EqPieChart(
              slices: ExampleChartData.pieSlices(),
              behavior: behavior,
              onItemTap: (selection) {
                setState(() {
                  _selection =
                      '${selection.datum.label}: ${selection.datum.value.toStringAsFixed(0)}';
                });
              },
            ),
          ),
        ),
        _ChartPanel(
          title: 'Department mix',
          subtitle: 'Donut chart with center copy',
          child: SizedBox(
            height: 320,
            child: EqDonutChart(
              slices: ExampleChartData.donutSlices(),
              behavior: behavior,
              onItemTap: (selection) {
                setState(() {
                  _selection =
                      '${selection.datum.label}: ${selection.datum.value.toStringAsFixed(0)}';
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}

class BarDemoPage extends StatefulWidget {
  const BarDemoPage({super.key});

  @override
  State<BarDemoPage> createState() => _BarDemoPageState();
}

class _BarDemoPageState extends State<BarDemoPage> {
  var _layoutMode = EqBarLayoutMode.grouped;
  var _showGrid = true;
  String _selection = 'Tap a bar to inspect it.';

  @override
  Widget build(BuildContext context) {
    return _DemoScaffold(
      title: 'Bar',
      controls: <Widget>[
        SegmentedButton<EqBarLayoutMode>(
          segments: const <ButtonSegment<EqBarLayoutMode>>[
            ButtonSegment<EqBarLayoutMode>(
              value: EqBarLayoutMode.grouped,
              label: Text('Grouped'),
            ),
            ButtonSegment<EqBarLayoutMode>(
              value: EqBarLayoutMode.stacked,
              label: Text('Stacked'),
            ),
          ],
          selected: <EqBarLayoutMode>{_layoutMode},
          onSelectionChanged: (value) {
            setState(() => _layoutMode = value.first);
          },
        ),
        SwitchListTile.adaptive(
          value: _showGrid,
          contentPadding: EdgeInsets.zero,
          title: const Text('Show grid'),
          onChanged: (value) => setState(() => _showGrid = value),
        ),
      ],
      footerText: _selection,
      children: <Widget>[
        _ChartPanel(
          title: 'Device usage',
          subtitle: 'Negative baseline remains visible in Q1 tablet',
          child: SizedBox(
            height: 340,
            child: EqBarChart(
              series: ExampleChartData.barSeries(),
              behavior: EqBarChartBehavior(
                layoutMode: _layoutMode,
                showGrid: _showGrid,
              ),
              onItemTap: (selection) {
                setState(() {
                  _selection =
                      '${selection.datum.category}: ${selection.datum.value.toStringAsFixed(1)}';
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}

class LineAreaDemoPage extends StatefulWidget {
  const LineAreaDemoPage({super.key});

  @override
  State<LineAreaDemoPage> createState() => _LineAreaDemoPageState();
}

class _LineAreaDemoPageState extends State<LineAreaDemoPage> {
  var _showPoints = true;
  var _showAreaFill = false;
  String _selection = 'Tap a data point to inspect it.';

  @override
  Widget build(BuildContext context) {
    String formatter(double value) {
      final monthIndex = value.round().clamp(0, 11);
      return ExampleChartData.monthLabel(monthIndex);
    }

    return _DemoScaffold(
      title: 'Line + Area',
      controls: <Widget>[
        SwitchListTile.adaptive(
          value: _showPoints,
          contentPadding: EdgeInsets.zero,
          title: const Text('Show points'),
          onChanged: (value) => setState(() => _showPoints = value),
        ),
        SwitchListTile.adaptive(
          value: _showAreaFill,
          contentPadding: EdgeInsets.zero,
          title: const Text('Fill line chart'),
          onChanged: (value) => setState(() => _showAreaFill = value),
        ),
      ],
      footerText: _selection,
      children: <Widget>[
        _ChartPanel(
          title: 'Traffic trend',
          subtitle: 'Line chart with toggled point markers and fill',
          child: SizedBox(
            height: 340,
            child: EqLineChart(
              series: ExampleChartData.lineSeries(),
              behavior: EqLineChartBehavior(
                showPoints: _showPoints,
                showAreaFill: _showAreaFill,
                xLabelFormatter: formatter,
              ),
              onItemTap: (selection) {
                setState(() {
                  _selection =
                      '${ExampleChartData.monthLabel(selection.datum.x.round())}: ${selection.datum.y.toStringAsFixed(1)}';
                });
              },
            ),
          ),
        ),
        _ChartPanel(
          title: 'Projected vs baseline',
          subtitle: 'Area chart variant using the same line renderer',
          child: SizedBox(
            height: 340,
            child: EqAreaChart(
              series: ExampleChartData.areaSeries(),
              behavior: EqLineChartBehavior(
                showPoints: _showPoints,
                xLabelFormatter: formatter,
              ),
              onItemTap: (selection) {
                setState(() {
                  _selection =
                      '${ExampleChartData.monthLabel(selection.datum.x.round())}: ${selection.datum.y.toStringAsFixed(1)}';
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}

class RadarDemoPage extends StatefulWidget {
  const RadarDemoPage({super.key});

  @override
  State<RadarDemoPage> createState() => _RadarDemoPageState();
}

class _RadarDemoPageState extends State<RadarDemoPage> {
  var _showLabels = true;
  var _showPoints = true;
  String _selection = 'Tap a radar point to inspect it.';

  @override
  Widget build(BuildContext context) {
    return _DemoScaffold(
      title: 'Radar',
      controls: <Widget>[
        SwitchListTile.adaptive(
          value: _showLabels,
          contentPadding: EdgeInsets.zero,
          title: const Text('Show axis labels'),
          onChanged: (value) => setState(() => _showLabels = value),
        ),
        SwitchListTile.adaptive(
          value: _showPoints,
          contentPadding: EdgeInsets.zero,
          title: const Text('Show points'),
          onChanged: (value) => setState(() => _showPoints = value),
        ),
      ],
      footerText: _selection,
      children: <Widget>[
        _ChartPanel(
          title: 'Fruit comparison',
          subtitle: 'Multi-series radar chart with polygon grid',
          child: SizedBox(
            height: 360,
            child: EqRadarChart(
              axes: ExampleChartData.radarAxes(),
              series: ExampleChartData.radarSeries(),
              behavior: EqRadarChartBehavior(
                showAxisLabels: _showLabels,
                showPoints: _showPoints,
              ),
              onItemTap: (selection) {
                setState(() {
                  _selection =
                      '${selection.datum.series.name} / ${selection.datum.axis.label}: ${selection.datum.value.toStringAsFixed(0)}';
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}

class BubbleDemoPage extends StatefulWidget {
  const BubbleDemoPage({super.key});

  @override
  State<BubbleDemoPage> createState() => _BubbleDemoPageState();
}

class _BubbleDemoPageState extends State<BubbleDemoPage> {
  var _layoutMode = EqBubbleLayoutMode.scatter;
  var _showGrid = true;
  String _selection = 'Tap a bubble to inspect it.';

  @override
  Widget build(BuildContext context) {
    final isScatter = _layoutMode == EqBubbleLayoutMode.scatter;
    final data = isScatter
        ? ExampleChartData.bubbleScatterData()
        : ExampleChartData.bubblePackedData();

    return _DemoScaffold(
      title: 'Bubble',
      controls: <Widget>[
        SegmentedButton<EqBubbleLayoutMode>(
          segments: const <ButtonSegment<EqBubbleLayoutMode>>[
            ButtonSegment<EqBubbleLayoutMode>(
              value: EqBubbleLayoutMode.scatter,
              label: Text('Scatter'),
            ),
            ButtonSegment<EqBubbleLayoutMode>(
              value: EqBubbleLayoutMode.packed,
              label: Text('Packed'),
            ),
          ],
          selected: <EqBubbleLayoutMode>{_layoutMode},
          onSelectionChanged: (value) {
            setState(() => _layoutMode = value.first);
          },
        ),
        SwitchListTile.adaptive(
          value: _showGrid,
          contentPadding: EdgeInsets.zero,
          title: const Text('Show scatter grid'),
          onChanged:
              isScatter ? (value) => setState(() => _showGrid = value) : null,
        ),
      ],
      footerText: _selection,
      children: <Widget>[
        _ChartPanel(
          title: 'Sector cluster',
          subtitle:
              'Packed mode matches the Android bubble sample; scatter exposes scale mapping.',
          child: SizedBox(
            height: 380,
            child: EqBubbleChart(
              data: data,
              behavior: EqBubbleChartBehavior(
                layoutMode: _layoutMode,
                showGrid: isScatter && _showGrid,
                showAxes: isScatter,
                showTicks: isScatter,
              ),
              onItemTap: (selection) {
                setState(() {
                  _selection =
                      '${selection.datum.label}: ${formatBubbleNumberCompact(selection.datum.size)}';
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}

class HeatmapDemoPage extends StatefulWidget {
  const HeatmapDemoPage({super.key});

  @override
  State<HeatmapDemoPage> createState() => _HeatmapDemoPageState();
}

class _HeatmapDemoPageState extends State<HeatmapDemoPage> {
  var _showHeaders = true;
  String _selection = 'Tap a block to inspect it.';

  @override
  Widget build(BuildContext context) {
    return _DemoScaffold(
      title: 'Heatmap',
      controls: <Widget>[
        SwitchListTile.adaptive(
          value: _showHeaders,
          contentPadding: EdgeInsets.zero,
          title: const Text('Show section headers'),
          onChanged: (value) => setState(() => _showHeaders = value),
        ),
      ],
      footerText: _selection,
      children: <Widget>[
        _ChartPanel(
          title: 'US large caps',
          subtitle:
              'Treemap block area follows size ratio and block color reflects percentage change.',
          child: SizedBox(
            height: 560,
            child: EqStockHeatmapChart(
              sections: ExampleChartData.heatmapSections(),
              behavior: EqStockHeatmapChartBehavior(
                showSectionHeaders: _showHeaders,
              ),
              onItemTap: (selection) {
                setState(() {
                  _selection =
                      '${selection.datum.symbol} ${formatStockHeatmapChange(selection.datum.changePct)} / ${formatStockHeatmapMarketCap(selection.datum.marketCap)}';
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}

class BoxPlotDemoPage extends StatefulWidget {
  const BoxPlotDemoPage({super.key});

  @override
  State<BoxPlotDemoPage> createState() => _BoxPlotDemoPageState();
}

class _BoxPlotDemoPageState extends State<BoxPlotDemoPage> {
  var _showGrid = true;
  var _showValueLabels = true;
  String _selection = 'Tap a box to inspect it.';

  @override
  Widget build(BuildContext context) {
    return _DemoScaffold(
      title: 'Box Plot',
      controls: <Widget>[
        SwitchListTile.adaptive(
          value: _showGrid,
          contentPadding: EdgeInsets.zero,
          title: const Text('Show grid'),
          onChanged: (value) => setState(() => _showGrid = value),
        ),
        SwitchListTile.adaptive(
          value: _showValueLabels,
          contentPadding: EdgeInsets.zero,
          title: const Text('Show median labels'),
          onChanged: (value) => setState(() => _showValueLabels = value),
        ),
      ],
      footerText: _selection,
      children: <Widget>[
        _ChartPanel(
          title: 'Service latency spread',
          subtitle:
              'Quartile boxes and whiskers mirror the EQChart sample for category-by-category response time ranges.',
          child: SizedBox(
            height: 360,
            child: EqBoxPlotChart(
              entries: ExampleChartData.boxPlotEntries(),
              behavior: EqBoxPlotChartBehavior(
                showGrid: _showGrid,
                showValueLabels: _showValueLabels,
                yLabelFormatter: (value) =>
                    '${formatBoxPlotAxisValue(value)}ms',
              ),
              onItemTap: (selection) {
                setState(() {
                  _selection =
                      '${selection.datum.label}: median ${selection.datum.median.toStringAsFixed(0)}ms';
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}

class HistogramDemoPage extends StatefulWidget {
  const HistogramDemoPage({super.key});

  @override
  State<HistogramDemoPage> createState() => _HistogramDemoPageState();
}

class _HistogramDemoPageState extends State<HistogramDemoPage> {
  var _showGrid = true;
  var _showLabels = true;
  String _selection = 'Tap a histogram bar to inspect it.';

  @override
  Widget build(BuildContext context) {
    return _DemoScaffold(
      title: 'Histogram',
      controls: <Widget>[
        SwitchListTile.adaptive(
          value: _showGrid,
          contentPadding: EdgeInsets.zero,
          title: const Text('Show grid'),
          onChanged: (value) => setState(() => _showGrid = value),
        ),
        SwitchListTile.adaptive(
          value: _showLabels,
          contentPadding: EdgeInsets.zero,
          title: const Text('Show value labels'),
          onChanged: (value) => setState(() => _showLabels = value),
        ),
      ],
      footerText: _selection,
      children: <Widget>[
        _ChartPanel(
          title: 'Response time distribution',
          subtitle:
              'Ordered bins share the Android sample ranges and render compact bucket labels on the X axis.',
          child: SizedBox(
            height: 340,
            child: EqHistogramChart(
              bins: ExampleChartData.histogramBins(),
              behavior: EqHistogramChartBehavior(
                showGrid: _showGrid,
                showBarLabels: _showLabels,
                valueLabelFormatter: (value) => value.toStringAsFixed(0),
                yLabelFormatter: (value) => value.toStringAsFixed(0),
              ),
              onItemTap: (selection) {
                setState(() {
                  _selection =
                      '${formatHistogramBoundary(selection.datum.start)}-${formatHistogramBoundary(selection.datum.end)}ms: ${selection.datum.value.toStringAsFixed(0)}';
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}

class RangeBarDemoPage extends StatefulWidget {
  const RangeBarDemoPage({super.key});

  @override
  State<RangeBarDemoPage> createState() => _RangeBarDemoPageState();
}

class _RangeBarDemoPageState extends State<RangeBarDemoPage> {
  var _showGrid = true;
  var _showLabels = true;
  String _selection = 'Tap a timeline bar to inspect it.';

  @override
  Widget build(BuildContext context) {
    return _DemoScaffold(
      title: 'Range Bar',
      controls: <Widget>[
        SwitchListTile.adaptive(
          value: _showGrid,
          contentPadding: EdgeInsets.zero,
          title: const Text('Show grid'),
          onChanged: (value) => setState(() => _showGrid = value),
        ),
        SwitchListTile.adaptive(
          value: _showLabels,
          contentPadding: EdgeInsets.zero,
          title: const Text('Show interval labels'),
          onChanged: (value) => setState(() => _showLabels = value),
        ),
      ],
      footerText: _selection,
      children: <Widget>[
        _ChartPanel(
          title: 'Delivery timeline',
          subtitle:
              'Horizontal start/end intervals mirror the Android EQChart roadmap sample.',
          child: SizedBox(
            height: 360,
            child: EqRangeBarChart(
              entries: ExampleChartData.rangeBarEntries(),
              behavior: EqRangeBarChartBehavior(
                showGrid: _showGrid,
                showBarLabels: _showLabels,
                xLabelFormatter: (value) => 'W${value.toInt() + 1}',
                barLabelFormatter: (entry) =>
                    'W${entry.startValue.toInt() + 1} - W${entry.endValue.toInt() + 1}',
              ),
              onItemTap: (selection) {
                final duration =
                    (selection.datum.end - selection.datum.start).abs();
                setState(() {
                  _selection =
                      '${selection.datum.payload ?? selection.datum.label}: ${duration.toStringAsFixed(0)}w';
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}

class WaveformDemoPage extends StatefulWidget {
  const WaveformDemoPage({super.key});

  @override
  State<WaveformDemoPage> createState() => _WaveformDemoPageState();
}

class _WaveformDemoPageState extends State<WaveformDemoPage> {
  static const int _sampleRateHz = 44100;
  static const int _chunkSize = 2205;

  late final EqPcmWaveformController _controller;
  late final List<int> _loopSamples;
  Timer? _timer;
  var _showCenterLine = true;
  var _amplitudeScale = 1.0;
  var _streaming = false;
  var _cursor = 0;
  String _status = 'Static 1.6s sample loaded.';

  @override
  void initState() {
    super.initState();
    _controller = EqPcmWaveformController(
      sampleRateHz: _sampleRateHz,
      windowDurationMs: 2000,
    );
    _loopSamples = ExampleChartData.waveformSamples(
      sampleRateHz: _sampleRateHz,
      durationMs: 1600,
      frequencyHz: 220,
    );
    _controller.setPcm16Mono(_loopSamples);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _toggleStreaming() {
    if (_streaming) {
      _timer?.cancel();
      setState(() {
        _streaming = false;
        _status = 'Streaming paused.';
      });
      return;
    }

    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      _controller.appendPcm16Mono(_nextWaveChunk());
    });
    setState(() {
      _streaming = true;
      _status = 'Appending live 16-bit PCM chunks.';
    });
  }

  List<int> _nextWaveChunk() {
    if (_loopSamples.isEmpty) {
      return const <int>[];
    }

    final out = List<int>.generate(
      _chunkSize,
      (index) => _loopSamples[(_cursor + index) % _loopSamples.length],
      growable: false,
    );
    _cursor = (_cursor + _chunkSize) % _loopSamples.length;
    return out;
  }

  void _reloadStatic() {
    _timer?.cancel();
    _cursor = 0;
    _controller.setPcm16Mono(_loopSamples);
    setState(() {
      _streaming = false;
      _status = 'Static 1.6s sample reloaded.';
    });
  }

  void _clearBuffer() {
    _timer?.cancel();
    _controller.clear();
    setState(() {
      _streaming = false;
      _status = 'Waveform buffer cleared.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return _DemoScaffold(
      title: 'Waveform',
      controls: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: FilledButton(
                onPressed: _toggleStreaming,
                child: Text(_streaming ? 'Stop stream' : 'Start stream'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: _reloadStatic,
                child: const Text('Reload sample'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _clearBuffer,
          child: const Text('Clear buffer'),
        ),
        SwitchListTile.adaptive(
          value: _showCenterLine,
          contentPadding: EdgeInsets.zero,
          title: const Text('Show center line'),
          onChanged: (value) => setState(() => _showCenterLine = value),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Amplitude ${_amplitudeScale.toStringAsFixed(1)}x',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Slider(
              value: _amplitudeScale,
              min: 0.4,
              max: 2.2,
              divisions: 9,
              label: _amplitudeScale.toStringAsFixed(1),
              onChanged: (value) => setState(() => _amplitudeScale = value),
            ),
          ],
        ),
      ],
      footerText: _status,
      children: <Widget>[
        _ChartPanel(
          title: 'PCM waveform',
          subtitle:
              'Min/max downsampling per pixel keeps short peaks visible during streaming.',
          child: SizedBox(
            height: 240,
            child: EqPcmWaveformChart(
              controller: _controller,
              style: EqPcmWaveformStyle(
                showCenterLine: _showCenterLine,
                amplitudeScale: _amplitudeScale,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class GaugeDemoPage extends StatefulWidget {
  const GaugeDemoPage({super.key});

  @override
  State<GaugeDemoPage> createState() => _GaugeDemoPageState();
}

class _GaugeDemoPageState extends State<GaugeDemoPage> {
  var _currentValue = 72.0;
  var _showTicks = true;
  var _showMinMaxLabels = true;

  String get _zoneLabel {
    if (_currentValue >= 80) {
      return 'Critical zone';
    }
    if (_currentValue >= 55) {
      return 'Warning zone';
    }
    return 'Healthy zone';
  }

  @override
  Widget build(BuildContext context) {
    return _DemoScaffold(
      title: 'Gauge',
      controls: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Current load ${_currentValue.toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Slider(
              value: _currentValue,
              min: 0,
              max: 100,
              divisions: 20,
              label: _currentValue.toStringAsFixed(0),
              onChanged: (value) => setState(() => _currentValue = value),
            ),
          ],
        ),
        SwitchListTile.adaptive(
          value: _showTicks,
          contentPadding: EdgeInsets.zero,
          title: const Text('Show ticks'),
          onChanged: (value) => setState(() => _showTicks = value),
        ),
        SwitchListTile.adaptive(
          value: _showMinMaxLabels,
          contentPadding: EdgeInsets.zero,
          title: const Text('Show min / max labels'),
          onChanged: (value) => setState(() => _showMinMaxLabels = value),
        ),
      ],
      footerText: '$_zoneLabel at ${_currentValue.toStringAsFixed(0)}%',
      children: <Widget>[
        _ChartPanel(
          title: 'Server load',
          subtitle:
              'Semi-circular gauge ported from EQChart with threshold bands and animated value changes.',
          child: SizedBox(
            height: 320,
            child: EqGaugeChart(
              value: GaugeValue(
                value: _currentValue,
                minValue: 0,
                maxValue: 100,
                label: 'CPU Load',
              ),
              ranges: ExampleChartData.gaugeRanges(),
              behavior: EqGaugeChartBehavior(
                showTicks: _showTicks,
                showMinMaxLabels: _showMinMaxLabels,
                valueFormatter: (value) => '${value.toStringAsFixed(0)}%',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DemoScaffold extends StatelessWidget {
  const _DemoScaffold({
    required this.title,
    required this.controls,
    required this.children,
    required this.footerText,
  });

  final String title;
  final List<Widget> controls;
  final List<Widget> children;
  final String footerText;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        children: <Widget>[
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(children: controls),
            ),
          ),
          const SizedBox(height: 14),
          ...children
              .expand((child) => <Widget>[child, const SizedBox(height: 14)]),
          Material(
            color: const Color(0xFF132636),
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                footerText,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartPanel extends StatelessWidget {
  const _ChartPanel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF5F7183),
                  ),
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}
