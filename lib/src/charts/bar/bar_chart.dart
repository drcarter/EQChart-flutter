import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../common/chart_legend.dart';
import '../../common/chart_math.dart';
import '../../common/chart_types.dart';
import '../../theme/chart_defaults.dart';

class BarDatum {
  const BarDatum(
    this.category,
    this.value, {
    this.payload,
  });

  final String category;
  final double value;
  final Object? payload;
}

class BarSeries {
  const BarSeries({
    required this.name,
    required this.color,
    required this.points,
  });

  final String name;
  final Color color;
  final List<BarDatum> points;
}

class EqBarChartStyle {
  const EqBarChartStyle({
    this.backgroundColor = Colors.transparent,
    this.padding = EqChartDefaults.chartPadding,
    this.axisColor = EqChartDefaults.axis,
    this.gridColor = EqChartDefaults.grid,
    this.axisLabelTextStyle = EqChartDefaults.axisTextStyle,
    this.legendTextStyle = EqChartDefaults.legendTextStyle,
    this.labelTextStyle = EqChartDefaults.labelTextStyle,
    this.barSpacing = 8,
    this.categorySpacing = 22,
    this.barRadius = 10,
  });

  final Color backgroundColor;
  final EdgeInsets padding;
  final Color axisColor;
  final Color gridColor;
  final TextStyle axisLabelTextStyle;
  final TextStyle legendTextStyle;
  final TextStyle labelTextStyle;
  final double barSpacing;
  final double categorySpacing;
  final double barRadius;
}

class EqBarChartBehavior {
  const EqBarChartBehavior({
    this.showLegend = true,
    this.showGrid = true,
    this.showAxes = true,
    this.animateOnDataChange = true,
    this.selectionEnabled = true,
    this.animationDuration = const Duration(milliseconds: 700),
    this.layoutMode = EqBarLayoutMode.grouped,
    this.orientation = EqBarOrientation.vertical,
    this.yTickCount = 5,
    this.xLabelFormatter,
    this.yLabelFormatter,
    this.emptyText = 'No data',
  });

  final bool showLegend;
  final bool showGrid;
  final bool showAxes;
  final bool animateOnDataChange;
  final bool selectionEnabled;
  final Duration animationDuration;
  final EqBarLayoutMode layoutMode;
  final EqBarOrientation orientation;
  final int yTickCount;
  final EqCategoryFormatter? xLabelFormatter;
  final EqValueFormatter? yLabelFormatter;
  final String emptyText;
}

@visibleForTesting
class BarRectLayout {
  const BarRectLayout({
    required this.rect,
    required this.seriesIndex,
    required this.categoryIndex,
    required this.datum,
  });

  final Rect rect;
  final int seriesIndex;
  final int categoryIndex;
  final BarDatum datum;
}

@visibleForTesting
class BarChartLayout {
  const BarChartLayout({
    required this.plotRect,
    required this.categories,
    required this.yTicks,
    required this.minValue,
    required this.maxValue,
    required this.baselineY,
    required this.bars,
  });

  final Rect plotRect;
  final List<String> categories;
  final List<double> yTicks;
  final double minValue;
  final double maxValue;
  final double baselineY;
  final List<BarRectLayout> bars;
}

@visibleForTesting
BarChartLayout computeBarChartLayout(
  Size size,
  List<BarSeries> series,
  EqBarChartStyle style,
  EqBarChartBehavior behavior,
) {
  final categories = <String>{};
  for (final group in series) {
    for (final point in group.points) {
      categories.add(point.category);
    }
  }
  final orderedCategories = categories.toList(growable: false);

  final leftReserve = behavior.showAxes ? 44.0 : 10.0;
  final bottomReserve = behavior.showAxes ? 30.0 : 10.0;
  final plotRect = Rect.fromLTWH(
    style.padding.left + leftReserve,
    style.padding.top + 6,
    math.max(0, size.width - style.padding.horizontal - leftReserve - 10),
    math.max(0, size.height - style.padding.vertical - bottomReserve - 6),
  );

  final values = <double>[];
  if (behavior.layoutMode == EqBarLayoutMode.stacked) {
    for (final category in orderedCategories) {
      var positive = 0.0;
      var negative = 0.0;
      for (final group in series) {
        final datum = group.points.cast<BarDatum?>().firstWhere(
              (point) => point?.category == category,
              orElse: () => null,
            );
        if (datum == null) {
          continue;
        }
        if (datum.value >= 0) {
          positive += datum.value;
        } else {
          negative += datum.value;
        }
      }
      values
        ..add(positive)
        ..add(negative);
    }
  } else {
    for (final group in series) {
      values.addAll(group.points.map((point) => point.value));
    }
  }

  final range = includeZeroInRange(values);
  final baselineY = mapToRange(
    value: 0,
    domainMin: range.min,
    domainMax: range.max,
    rangeMin: plotRect.bottom,
    rangeMax: plotRect.top,
  );
  final yTicks = buildLinearTicks(
    range.min,
    range.max,
    count: behavior.yTickCount,
  );
  final bars = <BarRectLayout>[];

  if (orderedCategories.isNotEmpty &&
      plotRect.width > 0 &&
      plotRect.height > 0) {
    final slotWidth = plotRect.width / orderedCategories.length;
    final usableWidth = math.max(8, slotWidth - style.categorySpacing);
    if (behavior.layoutMode == EqBarLayoutMode.grouped) {
      final totalBarSpacing = style.barSpacing * math.max(0, series.length - 1);
      final barWidth = math.max(
          4, (usableWidth - totalBarSpacing) / math.max(1, series.length));
      for (var categoryIndex = 0;
          categoryIndex < orderedCategories.length;
          categoryIndex++) {
        final category = orderedCategories[categoryIndex];
        final leftStart = plotRect.left +
            (slotWidth * categoryIndex) +
            ((slotWidth - usableWidth) / 2);
        for (var seriesIndex = 0; seriesIndex < series.length; seriesIndex++) {
          final datum = series[seriesIndex].points.cast<BarDatum?>().firstWhere(
                (point) => point?.category == category,
                orElse: () => null,
              );
          if (datum == null) {
            continue;
          }
          final topValueY = mapToRange(
            value: datum.value,
            domainMin: range.min,
            domainMax: range.max,
            rangeMin: plotRect.bottom,
            rangeMax: plotRect.top,
          );
          final left =
              leftStart + (seriesIndex * (barWidth + style.barSpacing));
          bars.add(
            BarRectLayout(
              rect: Rect.fromLTRB(
                left,
                math.min(topValueY, baselineY),
                left + barWidth,
                math.max(topValueY, baselineY),
              ),
              seriesIndex: seriesIndex,
              categoryIndex: categoryIndex,
              datum: datum,
            ),
          );
        }
      }
    } else {
      for (var categoryIndex = 0;
          categoryIndex < orderedCategories.length;
          categoryIndex++) {
        final category = orderedCategories[categoryIndex];
        final left = plotRect.left +
            (slotWidth * categoryIndex) +
            ((slotWidth - usableWidth) / 2);
        final right = left + usableWidth;
        var positiveBase = 0.0;
        var negativeBase = 0.0;

        for (var seriesIndex = 0; seriesIndex < series.length; seriesIndex++) {
          final datum = series[seriesIndex].points.cast<BarDatum?>().firstWhere(
                (point) => point?.category == category,
                orElse: () => null,
              );
          if (datum == null) {
            continue;
          }

          final start = datum.value >= 0 ? positiveBase : negativeBase;
          final end = start + datum.value;
          final startY = mapToRange(
            value: start,
            domainMin: range.min,
            domainMax: range.max,
            rangeMin: plotRect.bottom,
            rangeMax: plotRect.top,
          );
          final endY = mapToRange(
            value: end,
            domainMin: range.min,
            domainMax: range.max,
            rangeMin: plotRect.bottom,
            rangeMax: plotRect.top,
          );
          bars.add(
            BarRectLayout(
              rect: Rect.fromLTRB(
                left,
                math.min(startY, endY),
                right,
                math.max(startY, endY),
              ),
              seriesIndex: seriesIndex,
              categoryIndex: categoryIndex,
              datum: datum,
            ),
          );
          if (datum.value >= 0) {
            positiveBase = end;
          } else {
            negativeBase = end;
          }
        }
      }
    }
  }

  return BarChartLayout(
    plotRect: plotRect,
    categories: orderedCategories,
    yTicks: yTicks,
    minValue: range.min,
    maxValue: range.max,
    baselineY: baselineY,
    bars: bars,
  );
}

class EqBarChart extends StatefulWidget {
  const EqBarChart({
    super.key,
    required this.series,
    this.style = const EqBarChartStyle(),
    this.behavior = const EqBarChartBehavior(),
    this.onItemTap,
  });

  final List<BarSeries> series;
  final EqBarChartStyle style;
  final EqBarChartBehavior behavior;
  final EqSelectionChanged<BarDatum>? onItemTap;

  @override
  State<EqBarChart> createState() => _EqBarChartState();
}

class _EqBarChartState extends State<EqBarChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int? _selectedSeriesIndex;
  int? _selectedItemIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.behavior.animationDuration,
      value: widget.behavior.animateOnDataChange ? 0 : 1,
    );
    if (widget.behavior.animateOnDataChange) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant EqBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.behavior.animationDuration !=
        widget.behavior.animationDuration) {
      _controller.duration = widget.behavior.animationDuration;
    }
    if (widget.behavior.animateOnDataChange &&
        (oldWidget.series != widget.series ||
            oldWidget.behavior.layoutMode != widget.behavior.layoutMode)) {
      _controller.forward(from: 0);
    } else if (!widget.behavior.animateOnDataChange) {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap(TapUpDetails details, Size size) {
    final layout = computeBarChartLayout(
      size,
      widget.series,
      widget.style,
      widget.behavior,
    );
    final hit = layout.bars.lastWhere(
      (bar) => bar.rect.contains(details.localPosition),
      orElse: () => const BarRectLayout(
        rect: Rect.zero,
        seriesIndex: -1,
        categoryIndex: -1,
        datum: BarDatum('', 0),
      ),
    );
    if (hit.seriesIndex < 0) {
      return;
    }

    if (widget.behavior.selectionEnabled) {
      setState(() {
        _selectedSeriesIndex = hit.seriesIndex;
        _selectedItemIndex = hit.categoryIndex;
      });
    }

    widget.onItemTap?.call(
      EqChartSelection<BarDatum>(
        seriesIndex: hit.seriesIndex,
        itemIndex: hit.categoryIndex,
        datum: hit.datum,
        localPosition: details.localPosition,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasData = widget.series.any((group) => group.points.isNotEmpty);
    final xFormatter =
        fallbackCategoryFormatter(widget.behavior.xLabelFormatter);
    final yFormatter = fallbackValueFormatter(widget.behavior.yLabelFormatter);

    final chartBody = !hasData
        ? Center(
            child: Text(
              widget.behavior.emptyText,
              style: widget.style.labelTextStyle.copyWith(
                color: EqChartDefaults.softInk,
              ),
            ),
          )
        : AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(
                    constraints.maxWidth,
                    constraints.maxHeight.isFinite
                        ? constraints.maxHeight
                        : 280,
                  );

                  return GestureDetector(
                    onTapUp: widget.onItemTap != null ||
                            widget.behavior.selectionEnabled
                        ? (details) => _handleTap(details, size)
                        : null,
                    child: RepaintBoundary(
                      child: CustomPaint(
                        size: size,
                        painter: _BarChartPainter(
                          series: widget.series,
                          style: widget.style,
                          behavior: widget.behavior,
                          progress: _controller.value,
                          selectedSeriesIndex: _selectedSeriesIndex,
                          selectedItemIndex: _selectedItemIndex,
                          xFormatter: xFormatter,
                          yFormatter: yFormatter,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );

    final legend = widget.behavior.showLegend
        ? Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
            child: EqChartLegend(
              items: widget.series
                  .map(
                    (group) => EqChartLegendItem(
                      label: group.name,
                      color: group.color,
                    ),
                  )
                  .toList(growable: false),
              textStyle: widget.style.legendTextStyle,
            ),
          )
        : const SizedBox.shrink();

    return DecoratedBox(
      decoration: BoxDecoration(color: widget.style.backgroundColor),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final boundedHeight = constraints.maxHeight.isFinite;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (boundedHeight)
                Expanded(child: chartBody)
              else
                SizedBox(height: 280, child: chartBody),
              legend,
            ],
          );
        },
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  const _BarChartPainter({
    required this.series,
    required this.style,
    required this.behavior,
    required this.progress,
    required this.selectedSeriesIndex,
    required this.selectedItemIndex,
    required this.xFormatter,
    required this.yFormatter,
  });

  final List<BarSeries> series;
  final EqBarChartStyle style;
  final EqBarChartBehavior behavior;
  final double progress;
  final int? selectedSeriesIndex;
  final int? selectedItemIndex;
  final EqCategoryFormatter xFormatter;
  final EqValueFormatter yFormatter;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = computeBarChartLayout(size, series, style, behavior);
    final axisPaint = Paint()
      ..color = style.axisColor
      ..strokeWidth = 1.2;
    final gridPaint = Paint()
      ..color = style.gridColor
      ..strokeWidth = 1;

    if (behavior.showGrid) {
      for (final tick in layout.yTicks) {
        final y = mapToRange(
          value: tick,
          domainMin: layout.minValue,
          domainMax: layout.maxValue,
          rangeMin: layout.plotRect.bottom,
          rangeMax: layout.plotRect.top,
        );
        canvas.drawLine(
          Offset(layout.plotRect.left, y),
          Offset(layout.plotRect.right, y),
          gridPaint,
        );
      }
    }

    if (behavior.showAxes) {
      canvas.drawLine(
        Offset(layout.plotRect.left, layout.plotRect.top),
        Offset(layout.plotRect.left, layout.plotRect.bottom),
        axisPaint,
      );
      canvas.drawLine(
        Offset(layout.plotRect.left, layout.baselineY),
        Offset(layout.plotRect.right, layout.baselineY),
        axisPaint,
      );

      for (final tick in layout.yTicks) {
        final y = mapToRange(
          value: tick,
          domainMin: layout.minValue,
          domainMax: layout.maxValue,
          rangeMin: layout.plotRect.bottom,
          rangeMax: layout.plotRect.top,
        );
        final painter = buildTextPainter(
          yFormatter(tick),
          style.axisLabelTextStyle,
          textAlign: TextAlign.right,
        );
        painter.paint(
          canvas,
          Offset(layout.plotRect.left - painter.width - 8,
              y - (painter.height / 2)),
        );
      }

      if (layout.categories.isNotEmpty) {
        final slotWidth = layout.plotRect.width / layout.categories.length;
        for (var index = 0; index < layout.categories.length; index++) {
          final category = xFormatter(layout.categories[index]);
          final painter = buildTextPainter(
            category,
            style.axisLabelTextStyle,
            textAlign: TextAlign.center,
          );
          final x = layout.plotRect.left +
              (slotWidth * index) +
              (slotWidth / 2) -
              (painter.width / 2);
          painter.paint(
            canvas,
            Offset(x, layout.plotRect.bottom + 8),
          );
        }
      }
    }

    for (final bar in layout.bars) {
      final animatedRect = Rect.fromLTRB(
        bar.rect.left,
        layout.baselineY + ((bar.rect.top - layout.baselineY) * progress),
        bar.rect.right,
        layout.baselineY + ((bar.rect.bottom - layout.baselineY) * progress),
      );
      final color = series[bar.seriesIndex].color;
      final isSelected = selectedSeriesIndex == bar.seriesIndex &&
          selectedItemIndex == bar.categoryIndex;
      final paint = Paint()
        ..color = isSelected ? Color.lerp(color, Colors.white, 0.18)! : color;
      final rrect = RRect.fromRectAndRadius(
        animatedRect,
        Radius.circular(style.barRadius),
      );
      canvas.drawRRect(rrect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.series != series ||
        oldDelegate.progress != progress ||
        oldDelegate.selectedSeriesIndex != selectedSeriesIndex ||
        oldDelegate.selectedItemIndex != selectedItemIndex;
  }
}
