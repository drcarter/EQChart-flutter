# eqchart_flutter

Painter-based Flutter charts inspired by the Android `EQChart` project.

Current widgets:

- `EqPieChart`
- `EqDonutChart`
- `EqBarChart`
- `EqLineChart`
- `EqAreaChart`
- `EqRadarChart`

## Structure

- `lib/`: reusable chart package
- `example/`: demo app with parity-focused sample screens
- `test/`: layout and widget smoke tests

## Getting Started

Add the package dependency:

```yaml
dependencies:
  eqchart_flutter:
    path: ../eqchart_flutter
```

## Usage

```dart
import 'package:eqchart_flutter/eqchart_flutter.dart';
import 'package:flutter/material.dart';

class PieExample extends StatelessWidget {
  const PieExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 280,
      child: EqPieChart(
        slices: <PieSlice>[
          PieSlice('Direct', 43, Color(0xFF2B80FF)),
          PieSlice('Search', 26, Color(0xFFFF9F1C)),
          PieSlice('Referral', 13, Color(0xFFEF476F)),
        ],
      ),
    );
  }
}
```

Bar, line/area, and radar charts follow the same public pattern:

- `data`
- `style`
- `behavior`
- `onItemTap`

## Example App

Run the demo app:

```bash
cd example
flutter run
```

The demo includes:

- pie + donut selection and label toggles
- grouped/stacked bar charts with negative baseline
- line and area charts with multi-series data
- radar chart with polygon grid and point selection

Run the same example on web:

```bash
cd example
flutter run -d chrome
```
