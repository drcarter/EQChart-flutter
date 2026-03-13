# eqchart_flutter

`eqchart_flutter` is a painter-based Flutter chart package inspired by the Android `EQChart` project.

Implemented chart widgets:

- `EqPieChart`
- `EqDonutChart`
- `EqBarChart`
- `EqLineChart`
- `EqAreaChart`
- `EqRadarChart`

The package does not depend on a third-party chart library. All chart rendering is implemented with `CustomPainter`.

## Supported Charts

### Pie / Donut

- ratio-based slices
- legend and label rendering
- clockwise / start-angle control
- tap selection with expand offset
- donut center text and sub text

Main types:

- `PieSlice`
- `EqPieChartStyle`
- `EqPieChartBehavior`

### Bar

- grouped and stacked modes
- mixed positive / negative values with zero baseline
- axis, grid, legend, and tick labels
- x / y formatter callbacks
- tap selection per bar

Main types:

- `BarDatum`
- `BarSeries`
- `EqBarChartStyle`
- `EqBarChartBehavior`
- `EqBarLayoutMode`

### Line / Area

- multi-series line rendering
- optional point markers
- optional area fill
- axis / grid / legend
- x / y formatter callbacks
- tap selection on nearest point

Main types:

- `LineDatum`
- `LineSeries`
- `EqLineChartStyle`
- `EqLineChartBehavior`

### Radar

- multi-series polygon rendering
- configurable grid levels
- axis labels and point markers
- tap selection on a radar point

Main types:

- `RadarAxis`
- `RadarSeries`
- `RadarPointDatum`
- `EqRadarChartStyle`
- `EqRadarChartBehavior`

## Project Structure

- `lib/`: reusable chart package
- `example/`: parity-focused demo app for mobile and web
- `test/`: layout and widget smoke tests

## Installation

Add the package dependency:

```yaml
dependencies:
  eqchart_flutter:
    path: ../eqchart_flutter
```

Import:

```dart
import 'package:eqchart_flutter/eqchart_flutter.dart';
```

## Common API Pattern

Every chart follows the same top-level structure:

- `data`: slices, series, or axes
- `style`: colors, text styles, spacing, line widths
- `behavior`: legend, labels, animation, formatting, interaction
- `onItemTap`: chart-specific selection callback

Selection callbacks use:

- `EqChartSelection<PieSlice>`
- `EqChartSelection<BarDatum>`
- `EqChartSelection<LineDatum>`
- `EqChartSelection<RadarPointDatum>`

## Usage

### Pie Chart

```dart
SizedBox(
  height: 300,
  child: EqPieChart(
    slices: const <PieSlice>[
      PieSlice('Direct', 43, Color(0xFF2B80FF)),
      PieSlice('Social', 18, Color(0xFF13C3A3)),
      PieSlice('Search', 26, Color(0xFFFF9F1C)),
      PieSlice('Referral', 13, Color(0xFFEF476F)),
    ],
    behavior: const EqPieChartBehavior(
      showLabels: true,
      selectionEnabled: true,
      startAngleDeg: -90,
    ),
  ),
)
```

### Donut Chart

```dart
SizedBox(
  height: 300,
  child: EqDonutChart(
    slices: const <PieSlice>[
      PieSlice('Engineering', 38, Color(0xFF2A9D8F)),
      PieSlice('Marketing', 22, Color(0xFF3A86FF)),
      PieSlice('Sales', 27, Color(0xFFFFBE0B)),
      PieSlice('Ops', 13, Color(0xFFFB5607)),
    ],
    behavior: const EqPieChartBehavior(
      showLabels: true,
      centerText: '100%',
      centerSubText: 'Team Split',
    ),
  ),
)
```

### Bar Chart

```dart
SizedBox(
  height: 320,
  child: EqBarChart(
    series: const <BarSeries>[
      BarSeries(
        name: 'Desktop',
        color: Color(0xFF2B80FF),
        points: <BarDatum>[
          BarDatum('Q1', 10),
          BarDatum('Q2', 14),
          BarDatum('Q3', 19),
        ],
      ),
      BarSeries(
        name: 'Mobile',
        color: Color(0xFF13C3A3),
        points: <BarDatum>[
          BarDatum('Q1', 7),
          BarDatum('Q2', 10),
          BarDatum('Q3', 13),
        ],
      ),
    ],
    behavior: EqBarChartBehavior(
      layoutMode: EqBarLayoutMode.grouped,
      yLabelFormatter: (value) => value.toStringAsFixed(0),
    ),
  ),
)
```

### Line Chart

```dart
final monthLabels = <String>['Jan', 'Feb', 'Mar', 'Apr'];

SizedBox(
  height: 320,
  child: EqLineChart(
    series: const <LineSeries>[
      LineSeries(
        name: 'Traffic',
        color: Color(0xFF2B80FF),
        points: <LineDatum>[
          LineDatum(0, 10),
          LineDatum(1, 18),
          LineDatum(2, 15),
          LineDatum(3, 22),
        ],
      ),
    ],
    behavior: EqLineChartBehavior(
      showPoints: true,
      xLabelFormatter: (value) => monthLabels[value.round()],
    ),
  ),
)
```

### Area Chart

```dart
SizedBox(
  height: 320,
  child: EqAreaChart(
    series: const <LineSeries>[
      LineSeries(
        name: 'Projected',
        color: Color(0xFFFF9F1C),
        areaFillColor: Color(0xFFFF9F1C),
        points: <LineDatum>[
          LineDatum(0, 32),
          LineDatum(1, 40),
          LineDatum(2, 38),
          LineDatum(3, 46),
        ],
      ),
    ],
  ),
)
```

### Radar Chart

```dart
SizedBox(
  height: 340,
  child: EqRadarChart(
    axes: const <RadarAxis>[
      RadarAxis('sweet'),
      RadarAxis('price'),
      RadarAxis('color'),
      RadarAxis('fresh'),
      RadarAxis('good'),
    ],
    series: const <RadarSeries>[
      RadarSeries('Apple', Color(0xFFB899FF), <double>[48, 80, 84, 34, 40]),
      RadarSeries('Banana', Color(0xFF6F8695), <double>[30, 40, 90, 82, 62]),
    ],
    behavior: const EqRadarChartBehavior(
      gridLevels: 5,
      showAxisLabels: true,
    ),
  ),
)
```

## Example App

Run the mobile example:

```bash
cd example
flutter run
```

Run the web example:

```bash
cd example
flutter run -d chrome
```

Build the web example:

```bash
cd example
flutter build web
```

The example app currently includes:

- `Pie + Donut`: selection, labels, center text
- `Bar`: grouped / stacked mode, negative baseline
- `Line + Area`: multi-series trend rendering and area fill
- `Radar`: polygon grid, axis labels, multi-series comparison

## Notes

- The package currently focuses on `pie`, `donut`, `bar`, `line`, `area`, and `radar`.
- `bubble`, `heatmap`, and `waveform` are not implemented yet in the Flutter package.
- Tests cover chart layout helpers and widget smoke rendering in [`test/eqchart_flutter_test.dart`](/Users/daniel/dev_source/private/EQChart-flutter/test/eqchart_flutter_test.dart).
