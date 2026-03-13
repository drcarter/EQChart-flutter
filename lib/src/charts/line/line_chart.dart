import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../common/chart_legend.dart';
import '../../common/chart_math.dart';
import '../../common/chart_types.dart';
import '../../theme/chart_defaults.dart';

class LineDatum {
  const LineDatum(
    this.x,
    this.y, {
    this.label,
    this.payload,
  });

  final double x;
  final double y;
  final String? label;
  final Object? payload;
}

class LineSeries {
  const LineSeries({
    required this.name,
    required this.color,
    required this.points,
    this.payload,
    this.areaFillColor,
  });

  final String name;
  final Color color;
  final List<LineDatum> points;
  final Object? payload;
  final Color? areaFillColor;
}

class EqLineChartStyle {
  const EqLineChartStyle({
    this.backgroundColor = Colors.transparent,
    this.padding = EqChartDefaults.chartPadding,
    this.axisColor = EqChartDefaults.axis,
    this.gridColor = EqChartDefaults.grid,
    this.axisLabelTextStyle = EqChartDefaults.axisTextStyle,
    this.legendTextStyle = EqChartDefaults.legendTextStyle,
    this.strokeWidth = 3,
    this.pointRadius = 4.5,
    this.areaOpacity = 0.18,
  });

  final Color backgroundColor;
  final EdgeInsets padding;
  final Color axisColor;
  final Color gridColor;
  final TextStyle axisLabelTextStyle;
  final TextStyle legendTextStyle;
  final double strokeWidth;
  final double pointRadius;
  final double areaOpacity;
}

class EqLineChartBehavior {
  const EqLineChartBehavior({
    this.showLegend = true,
    this.showGrid = true,
    this.showAxes = true,
    this.showPoints = true,
    this.showAreaFill = false,
    this.animateOnDataChange = true,
    this.selectionEnabled = true,
    this.animationDuration = const Duration(milliseconds: 720),
    this.xTickCount = 6,
    this.yTickCount = 5,
    this.xLabelFormatter,
    this.yLabelFormatter,
    this.emptyText = 'No data',
  });

  final bool showLegend;
  final bool showGrid;
  final bool showAxes;
  final bool showPoints;
  final bool showAreaFill;
  final bool animateOnDataChange;
  final bool selectionEnabled;
  final Duration animationDuration;
  final int xTickCount;
  final int yTickCount;
  final EqValueFormatter? xLabelFormatter;
  final EqValueFormatter? yLabelFormatter;
  final String emptyText;
}

@visibleForTesting
class LinePointLayout {
  const LinePointLayout({
    required this.position,
    required this.seriesIndex,
    required this.itemIndex,
    required this.datum,
  });

  final Offset position;
  final int seriesIndex;
  final int itemIndex;
  final LineDatum datum;
}

@visibleForTesting
class LineChartLayout {
  const LineChartLayout({
    required this.plotRect,
    required this.xMin,
    required this.xMax,
    required this.yMin,
    required this.yMax,
    required this.xTicks,
    required this.yTicks,
    required this.points,
  });

  final Rect plotRect;
  final double xMin;
  final double xMax;
  final double yMin;
  final double yMax;
  final List<double> xTicks;
  final List<double> yTicks;
  final List<List<LinePointLayout>> points;
}

@visibleForTesting
LineChartLayout computeLineChartLayout(
  Size size,
  List<LineSeries> series,
  EqLineChartStyle style,
  EqLineChartBehavior behavior,
) {
  final allPoints =
      series.expand((group) => group.points).toList(growable: false);
  final xValues = allPoints.map((point) => point.x);
  final yValues = allPoints.map((point) => point.y);

  double xMin = 0;
  double xMax = 1;
  if (allPoints.isNotEmpty) {
    xMin = xValues.reduce(math.min);
    xMax = xValues.reduce(math.max);
    if ((xMax - xMin).abs() < 1e-9) {
      xMax += 1;
    }
  }
  final yRange = includeZeroInRange(yValues);

  final leftReserve = behavior.showAxes ? 46.0 : 10.0;
  final bottomReserve = behavior.showAxes ? 28.0 : 10.0;
  final plotRect = Rect.fromLTWH(
    style.padding.left + leftReserve,
    style.padding.top + 8,
    math.max(0, size.width - style.padding.horizontal - leftReserve - 10),
    math.max(0, size.height - style.padding.vertical - bottomReserve - 8),
  );

  final points = <List<LinePointLayout>>[];
  for (var seriesIndex = 0; seriesIndex < series.length; seriesIndex++) {
    final group = series[seriesIndex];
    points.add(
      List<LinePointLayout>.generate(
        group.points.length,
        (itemIndex) {
          final datum = group.points[itemIndex];
          final dx = mapToRange(
            value: datum.x,
            domainMin: xMin,
            domainMax: xMax,
            rangeMin: plotRect.left,
            rangeMax: plotRect.right,
          );
          final dy = mapToRange(
            value: datum.y,
            domainMin: yRange.min,
            domainMax: yRange.max,
            rangeMin: plotRect.bottom,
            rangeMax: plotRect.top,
          );
          return LinePointLayout(
            position: Offset(dx, dy),
            seriesIndex: seriesIndex,
            itemIndex: itemIndex,
            datum: datum,
          );
        },
        growable: false,
      ),
    );
  }

  return LineChartLayout(
    plotRect: plotRect,
    xMin: xMin,
    xMax: xMax,
    yMin: yRange.min,
    yMax: yRange.max,
    xTicks: buildLinearTicks(xMin, xMax, count: behavior.xTickCount),
    yTicks:
        buildLinearTicks(yRange.min, yRange.max, count: behavior.yTickCount),
    points: points,
  );
}

class EqLineChart extends StatelessWidget {
  const EqLineChart({
    super.key,
    required this.series,
    this.style = const EqLineChartStyle(),
    this.behavior = const EqLineChartBehavior(),
    this.onItemTap,
  });

  final List<LineSeries> series;
  final EqLineChartStyle style;
  final EqLineChartBehavior behavior;
  final EqSelectionChanged<LineDatum>? onItemTap;

  @override
  Widget build(BuildContext context) {
    return _EqLineChartBase(
      series: series,
      style: style,
      behavior: behavior,
      forceAreaFill: false,
      onItemTap: onItemTap,
    );
  }
}

class EqAreaChart extends StatelessWidget {
  const EqAreaChart({
    super.key,
    required this.series,
    this.style = const EqLineChartStyle(),
    this.behavior = const EqLineChartBehavior(showAreaFill: true),
    this.onItemTap,
  });

  final List<LineSeries> series;
  final EqLineChartStyle style;
  final EqLineChartBehavior behavior;
  final EqSelectionChanged<LineDatum>? onItemTap;

  @override
  Widget build(BuildContext context) {
    return _EqLineChartBase(
      series: series,
      style: style,
      behavior: behavior,
      forceAreaFill: true,
      onItemTap: onItemTap,
    );
  }
}

class _EqLineChartBase extends StatefulWidget {
  const _EqLineChartBase({
    required this.series,
    required this.style,
    required this.behavior,
    required this.forceAreaFill,
    this.onItemTap,
  });

  final List<LineSeries> series;
  final EqLineChartStyle style;
  final EqLineChartBehavior behavior;
  final bool forceAreaFill;
  final EqSelectionChanged<LineDatum>? onItemTap;

  @override
  State<_EqLineChartBase> createState() => _EqLineChartBaseState();
}

class _EqLineChartBaseState extends State<_EqLineChartBase>
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
  void didUpdateWidget(covariant _EqLineChartBase oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.behavior.animationDuration !=
        widget.behavior.animationDuration) {
      _controller.duration = widget.behavior.animationDuration;
    }
    if (widget.behavior.animateOnDataChange &&
        (oldWidget.series != widget.series ||
            oldWidget.behavior.showAreaFill != widget.behavior.showAreaFill ||
            oldWidget.forceAreaFill != widget.forceAreaFill)) {
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
    final layout = computeLineChartLayout(
      size,
      widget.series,
      widget.style,
      widget.behavior,
    );
    LinePointLayout? best;
    var bestDistance = double.infinity;
    for (final group in layout.points) {
      for (final point in group) {
        final distance = (point.position - details.localPosition).distance;
        if (distance < bestDistance) {
          bestDistance = distance;
          best = point;
        }
      }
    }

    if (best == null || bestDistance > 22) {
      return;
    }

    if (widget.behavior.selectionEnabled) {
      setState(() {
        _selectedSeriesIndex = best!.seriesIndex;
        _selectedItemIndex = best.itemIndex;
      });
    }
    widget.onItemTap?.call(
      EqChartSelection<LineDatum>(
        seriesIndex: best.seriesIndex,
        itemIndex: best.itemIndex,
        datum: best.datum,
        localPosition: details.localPosition,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasData = widget.series.any((group) => group.points.isNotEmpty);
    final xFormatter = fallbackValueFormatter(widget.behavior.xLabelFormatter);
    final yFormatter = fallbackValueFormatter(widget.behavior.yLabelFormatter);

    final chartBody = !hasData
        ? Center(
            child: Text(
              widget.behavior.emptyText,
              style: EqChartDefaults.labelTextStyle.copyWith(
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
                        painter: _LineChartPainter(
                          series: widget.series,
                          style: widget.style,
                          behavior: widget.behavior,
                          xFormatter: xFormatter,
                          yFormatter: yFormatter,
                          progress: _controller.value,
                          selectedSeriesIndex: _selectedSeriesIndex,
                          selectedItemIndex: _selectedItemIndex,
                          forceAreaFill: widget.forceAreaFill,
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

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter({
    required this.series,
    required this.style,
    required this.behavior,
    required this.xFormatter,
    required this.yFormatter,
    required this.progress,
    required this.selectedSeriesIndex,
    required this.selectedItemIndex,
    required this.forceAreaFill,
  });

  final List<LineSeries> series;
  final EqLineChartStyle style;
  final EqLineChartBehavior behavior;
  final EqValueFormatter xFormatter;
  final EqValueFormatter yFormatter;
  final double progress;
  final int? selectedSeriesIndex;
  final int? selectedItemIndex;
  final bool forceAreaFill;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = computeLineChartLayout(size, series, style, behavior);
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
          domainMin: layout.yMin,
          domainMax: layout.yMax,
          rangeMin: layout.plotRect.bottom,
          rangeMax: layout.plotRect.top,
        );
        canvas.drawLine(
          Offset(layout.plotRect.left, y),
          Offset(layout.plotRect.right, y),
          gridPaint,
        );
      }
      for (final tick in layout.xTicks) {
        final x = mapToRange(
          value: tick,
          domainMin: layout.xMin,
          domainMax: layout.xMax,
          rangeMin: layout.plotRect.left,
          rangeMax: layout.plotRect.right,
        );
        canvas.drawLine(
          Offset(x, layout.plotRect.top),
          Offset(x, layout.plotRect.bottom),
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
        Offset(layout.plotRect.left, layout.plotRect.bottom),
        Offset(layout.plotRect.right, layout.plotRect.bottom),
        axisPaint,
      );

      for (final tick in layout.yTicks) {
        final y = mapToRange(
          value: tick,
          domainMin: layout.yMin,
          domainMax: layout.yMax,
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
                y - painter.height / 2));
      }

      for (final tick in layout.xTicks) {
        final x = mapToRange(
          value: tick,
          domainMin: layout.xMin,
          domainMax: layout.xMax,
          rangeMin: layout.plotRect.left,
          rangeMax: layout.plotRect.right,
        );
        final painter = buildTextPainter(
          xFormatter(tick),
          style.axisLabelTextStyle,
          textAlign: TextAlign.center,
        );
        painter.paint(
            canvas, Offset(x - painter.width / 2, layout.plotRect.bottom + 8));
      }
    }

    final baselineY = mapToRange(
      value: 0,
      domainMin: layout.yMin,
      domainMax: layout.yMax,
      rangeMin: layout.plotRect.bottom,
      rangeMax: layout.plotRect.top,
    );

    for (var seriesIndex = 0;
        seriesIndex < layout.points.length;
        seriesIndex++) {
      final group = layout.points[seriesIndex];
      if (group.isEmpty) {
        continue;
      }

      final linePath = Path()..moveTo(group.first.position.dx, baselineY);
      final strokePath = Path();
      for (var index = 0; index < group.length; index++) {
        final point = group[index];
        final animatedPosition = Offset(
          point.position.dx,
          baselineY + ((point.position.dy - baselineY) * progress),
        );
        if (index == 0) {
          strokePath.moveTo(animatedPosition.dx, animatedPosition.dy);
          linePath.lineTo(animatedPosition.dx, animatedPosition.dy);
        } else {
          strokePath.lineTo(animatedPosition.dx, animatedPosition.dy);
          linePath.lineTo(animatedPosition.dx, animatedPosition.dy);
        }
      }
      linePath
        ..lineTo(group.last.position.dx, baselineY)
        ..close();

      final lineColor = series[seriesIndex].color;
      if (forceAreaFill || behavior.showAreaFill) {
        canvas.drawPath(
          linePath,
          Paint()
            ..style = PaintingStyle.fill
            ..color = (series[seriesIndex].areaFillColor ?? lineColor)
                .withOpacity(style.areaOpacity),
        );
      }

      canvas.drawPath(
        strokePath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = style.strokeWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = lineColor,
      );

      if (behavior.showPoints) {
        for (final point in group) {
          final animatedPosition = Offset(
            point.position.dx,
            baselineY + ((point.position.dy - baselineY) * progress),
          );
          final isSelected = selectedSeriesIndex == point.seriesIndex &&
              selectedItemIndex == point.itemIndex;
          canvas.drawCircle(
            animatedPosition,
            isSelected ? style.pointRadius + 2 : style.pointRadius,
            Paint()..color = lineColor,
          );
          canvas.drawCircle(
            animatedPosition,
            isSelected ? style.pointRadius : style.pointRadius - 1,
            Paint()..color = Colors.white,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.series != series ||
        oldDelegate.progress != progress ||
        oldDelegate.selectedSeriesIndex != selectedSeriesIndex ||
        oldDelegate.selectedItemIndex != selectedItemIndex ||
        oldDelegate.forceAreaFill != forceAreaFill;
  }
}
