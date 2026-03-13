import 'package:flutter/material.dart';

class EqChartLegendItem {
  const EqChartLegendItem({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;
}

class EqChartLegend extends StatelessWidget {
  const EqChartLegend({
    super.key,
    required this.items,
    required this.textStyle,
    this.markerSize = 10,
    this.spacing = 12,
    this.runSpacing = 8,
  });

  final List<EqChartLegendItem> items;
  final TextStyle textStyle;
  final double markerSize;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: items
          .map(
            (item) => Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: markerSize,
                  height: markerSize,
                  decoration: BoxDecoration(
                    color: item.color,
                    borderRadius: BorderRadius.circular(markerSize / 2),
                  ),
                ),
                const SizedBox(width: 6),
                Text(item.label, style: textStyle),
              ],
            ),
          )
          .toList(growable: false),
    );
  }
}
