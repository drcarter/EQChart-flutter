import 'package:eqchart_flutter/eqchart_flutter.dart';
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
