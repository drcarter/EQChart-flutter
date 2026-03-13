import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../common/chart_legend.dart';
import '../../common/chart_math.dart';
import '../../common/chart_types.dart';
import '../../theme/chart_defaults.dart';

class RadarAxis {
  const RadarAxis(
    this.label, {
    this.maxValue = 100,
    this.payload,
  });

  final String label;
  final double maxValue;
  final Object? payload;
}

class RadarSeries {
  const RadarSeries(
    this.name,
    this.color,
    this.values, {
    this.payload,
  });

  final String name;
  final Color color;
  final List<double> values;
  final Object? payload;
}

class RadarPointDatum {
  const RadarPointDatum({
    required this.axis,
    required this.series,
    required this.value,
  });

  final RadarAxis axis;
  final RadarSeries series;
  final double value;
}

class EqRadarChartStyle {
  const EqRadarChartStyle({
    this.backgroundColor = Colors.transparent,
    this.padding = EqChartDefaults.chartPadding,
    this.gridColor = EqChartDefaults.grid,
    this.axisColor = EqChartDefaults.axis,
    this.axisLabelTextStyle = EqChartDefaults.axisTextStyle,
    this.legendTextStyle = EqChartDefaults.legendTextStyle,
    this.strokeWidth = 2.5,
    this.pointRadius = 4.5,
    this.fillOpacity = 0.16,
  });

  final Color backgroundColor;
  final EdgeInsets padding;
  final Color gridColor;
  final Color axisColor;
  final TextStyle axisLabelTextStyle;
  final TextStyle legendTextStyle;
  final double strokeWidth;
  final double pointRadius;
  final double fillOpacity;
}

class EqRadarChartBehavior {
  const EqRadarChartBehavior({
    this.showLegend = true,
    this.showAxisLabels = true,
    this.showPoints = true,
    this.animateOnDataChange = true,
    this.selectionEnabled = true,
    this.animationDuration = const Duration(milliseconds: 720),
    this.gridLevels = 5,
    this.startAngleDeg = -90,
    this.emptyText = 'No data',
  });

  final bool showLegend;
  final bool showAxisLabels;
  final bool showPoints;
  final bool animateOnDataChange;
  final bool selectionEnabled;
  final Duration animationDuration;
  final int gridLevels;
  final double startAngleDeg;
  final String emptyText;
}

@visibleForTesting
class RadarPointLayout {
  const RadarPointLayout({
    required this.position,
    required this.seriesIndex,
    required this.axisIndex,
    required this.value,
  });

  final Offset position;
  final int seriesIndex;
  final int axisIndex;
  final double value;
}

@visibleForTesting
class RadarChartLayout {
  const RadarChartLayout({
    required this.center,
    required this.radius,
    required this.axisAngles,
    required this.seriesPoints,
  });

  final Offset center;
  final double radius;
  final List<double> axisAngles;
  final List<List<RadarPointLayout>> seriesPoints;
}

@visibleForTesting
RadarChartLayout computeRadarChartLayout(
  Size size,
  List<RadarAxis> axes,
  List<RadarSeries> series,
  EqRadarChartStyle style,
  EqRadarChartBehavior behavior,
) {
  final labelReserve = behavior.showAxisLabels ? 36.0 : 12.0;
  final bounds = style.padding.deflateRect(Offset.zero & size);
  final radius =
      math.max(0.0, (math.min(bounds.width, bounds.height) / 2) - labelReserve);
  final center = bounds.center;
  final step = axes.isEmpty ? 0.0 : (math.pi * 2) / axes.length;
  final startAngle = behavior.startAngleDeg * math.pi / 180;
  final axisAngles = List<double>.generate(
    axes.length,
    (index) => startAngle + (step * index),
    growable: false,
  );

  final seriesPoints = <List<RadarPointLayout>>[];
  for (var seriesIndex = 0; seriesIndex < series.length; seriesIndex++) {
    final group = series[seriesIndex];
    final points = <RadarPointLayout>[];
    for (var axisIndex = 0; axisIndex < axes.length; axisIndex++) {
      final axis = axes[axisIndex];
      final value =
          axisIndex < group.values.length ? group.values[axisIndex] : 0.0;
      final fraction = axis.maxValue <= 0
          ? 0.0
          : (value / axis.maxValue).clamp(0.0, 1.0).toDouble();
      final angle = axisAngles[axisIndex];
      points.add(
        RadarPointLayout(
          position: Offset(
            center.dx + math.cos(angle) * radius * fraction,
            center.dy + math.sin(angle) * radius * fraction,
          ),
          seriesIndex: seriesIndex,
          axisIndex: axisIndex,
          value: value,
        ),
      );
    }
    seriesPoints.add(points);
  }

  return RadarChartLayout(
    center: center,
    radius: radius,
    axisAngles: axisAngles,
    seriesPoints: seriesPoints,
  );
}

class EqRadarChart extends StatefulWidget {
  const EqRadarChart({
    super.key,
    required this.axes,
    required this.series,
    this.style = const EqRadarChartStyle(),
    this.behavior = const EqRadarChartBehavior(),
    this.onItemTap,
  });

  final List<RadarAxis> axes;
  final List<RadarSeries> series;
  final EqRadarChartStyle style;
  final EqRadarChartBehavior behavior;
  final EqSelectionChanged<RadarPointDatum>? onItemTap;

  @override
  State<EqRadarChart> createState() => _EqRadarChartState();
}

class _EqRadarChartState extends State<EqRadarChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int? _selectedSeriesIndex;
  int? _selectedAxisIndex;

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
  void didUpdateWidget(covariant EqRadarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.behavior.animationDuration !=
        widget.behavior.animationDuration) {
      _controller.duration = widget.behavior.animationDuration;
    }
    if (widget.behavior.animateOnDataChange &&
        (oldWidget.axes != widget.axes ||
            oldWidget.series != widget.series ||
            oldWidget.behavior.startAngleDeg !=
                widget.behavior.startAngleDeg)) {
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
    final layout = computeRadarChartLayout(
      size,
      widget.axes,
      widget.series,
      widget.style,
      widget.behavior,
    );
    RadarPointLayout? best;
    var bestDistance = double.infinity;
    for (final group in layout.seriesPoints) {
      for (final point in group) {
        final distance = (point.position - details.localPosition).distance;
        if (distance < bestDistance) {
          bestDistance = distance;
          best = point;
        }
      }
    }
    if (best == null || bestDistance > 24) {
      return;
    }

    if (widget.behavior.selectionEnabled) {
      setState(() {
        _selectedSeriesIndex = best!.seriesIndex;
        _selectedAxisIndex = best.axisIndex;
      });
    }

    widget.onItemTap?.call(
      EqChartSelection<RadarPointDatum>(
        seriesIndex: best.seriesIndex,
        itemIndex: best.axisIndex,
        datum: RadarPointDatum(
          axis: widget.axes[best.axisIndex],
          series: widget.series[best.seriesIndex],
          value: best.value,
        ),
        localPosition: details.localPosition,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasData = widget.axes.isNotEmpty &&
        widget.series.any((group) => group.values.isNotEmpty);
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
                        : 300,
                  );
                  return GestureDetector(
                    onTapUp: widget.onItemTap != null ||
                            widget.behavior.selectionEnabled
                        ? (details) => _handleTap(details, size)
                        : null,
                    child: RepaintBoundary(
                      child: CustomPaint(
                        size: size,
                        painter: _RadarChartPainter(
                          axes: widget.axes,
                          series: widget.series,
                          style: widget.style,
                          behavior: widget.behavior,
                          progress: _controller.value,
                          selectedSeriesIndex: _selectedSeriesIndex,
                          selectedAxisIndex: _selectedAxisIndex,
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
                SizedBox(height: 300, child: chartBody),
              legend,
            ],
          );
        },
      ),
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  const _RadarChartPainter({
    required this.axes,
    required this.series,
    required this.style,
    required this.behavior,
    required this.progress,
    required this.selectedSeriesIndex,
    required this.selectedAxisIndex,
  });

  final List<RadarAxis> axes;
  final List<RadarSeries> series;
  final EqRadarChartStyle style;
  final EqRadarChartBehavior behavior;
  final double progress;
  final int? selectedSeriesIndex;
  final int? selectedAxisIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = computeRadarChartLayout(size, axes, series, style, behavior);
    if (axes.isEmpty || layout.radius <= 0) {
      return;
    }

    final gridPaint = Paint()
      ..color = style.gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final axisPaint = Paint()
      ..color = style.axisColor
      ..strokeWidth = 1.2;

    for (var level = 1; level <= math.max(1, behavior.gridLevels); level++) {
      final fraction = level / math.max(1, behavior.gridLevels);
      final path = Path();
      for (var axisIndex = 0; axisIndex < axes.length; axisIndex++) {
        final angle = layout.axisAngles[axisIndex];
        final point = Offset(
          layout.center.dx + math.cos(angle) * layout.radius * fraction,
          layout.center.dy + math.sin(angle) * layout.radius * fraction,
        );
        if (axisIndex == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    for (var axisIndex = 0; axisIndex < axes.length; axisIndex++) {
      final angle = layout.axisAngles[axisIndex];
      final endpoint = Offset(
        layout.center.dx + math.cos(angle) * layout.radius,
        layout.center.dy + math.sin(angle) * layout.radius,
      );
      canvas.drawLine(layout.center, endpoint, axisPaint);

      if (behavior.showAxisLabels) {
        final label = axes[axisIndex].label;
        final painter = buildTextPainter(
          label,
          style.axisLabelTextStyle,
          textAlign: TextAlign.center,
          maxLines: 2,
        );
        final labelPoint = Offset(
          layout.center.dx + math.cos(angle) * (layout.radius + 18),
          layout.center.dy + math.sin(angle) * (layout.radius + 18),
        );
        painter.paint(
          canvas,
          Offset(
            labelPoint.dx - painter.width / 2,
            labelPoint.dy - painter.height / 2,
          ),
        );
      }
    }

    for (var seriesIndex = 0;
        seriesIndex < layout.seriesPoints.length;
        seriesIndex++) {
      final points = layout.seriesPoints[seriesIndex];
      if (points.isEmpty) {
        continue;
      }

      final path = Path();
      for (var pointIndex = 0; pointIndex < points.length; pointIndex++) {
        final point = points[pointIndex];
        final animatedPoint = Offset(
          layout.center.dx +
              ((point.position.dx - layout.center.dx) * progress),
          layout.center.dy +
              ((point.position.dy - layout.center.dy) * progress),
        );
        if (pointIndex == 0) {
          path.moveTo(animatedPoint.dx, animatedPoint.dy);
        } else {
          path.lineTo(animatedPoint.dx, animatedPoint.dy);
        }
      }
      path.close();
      final color = series[seriesIndex].color;
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.fill
          ..color = color.withOpacity(style.fillOpacity),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = style.strokeWidth
          ..color = color,
      );

      if (behavior.showPoints) {
        for (final point in points) {
          final animatedPoint = Offset(
            layout.center.dx +
                ((point.position.dx - layout.center.dx) * progress),
            layout.center.dy +
                ((point.position.dy - layout.center.dy) * progress),
          );
          final isSelected = selectedSeriesIndex == point.seriesIndex &&
              selectedAxisIndex == point.axisIndex;
          canvas.drawCircle(
            animatedPoint,
            isSelected ? style.pointRadius + 2 : style.pointRadius,
            Paint()..color = color,
          );
          canvas.drawCircle(
            animatedPoint,
            isSelected ? style.pointRadius : style.pointRadius - 1,
            Paint()..color = Colors.white,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RadarChartPainter oldDelegate) {
    return oldDelegate.axes != axes ||
        oldDelegate.series != series ||
        oldDelegate.progress != progress ||
        oldDelegate.selectedSeriesIndex != selectedSeriesIndex ||
        oldDelegate.selectedAxisIndex != selectedAxisIndex;
  }
}
