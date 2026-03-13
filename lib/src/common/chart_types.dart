import 'package:flutter/material.dart';

typedef EqValueFormatter = String Function(double value);
typedef EqCategoryFormatter = String Function(String value);
typedef EqSelectionChanged<T> = void Function(EqChartSelection<T> selection);

class EqChartSelection<T> {
  const EqChartSelection({
    required this.seriesIndex,
    required this.itemIndex,
    required this.datum,
    required this.localPosition,
  });

  final int seriesIndex;
  final int itemIndex;
  final T datum;
  final Offset localPosition;
}

enum EqPieLabelPosition {
  auto,
  inside,
  outside,
}

enum EqBarLayoutMode {
  grouped,
  stacked,
}

enum EqBarOrientation {
  vertical,
}
