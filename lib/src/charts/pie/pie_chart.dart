import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../common/chart_legend.dart';
import '../../common/chart_math.dart';
import '../../common/chart_types.dart';
import '../../theme/chart_defaults.dart';

class PieSlice {
  const PieSlice(
    this.label,
    this.value,
    this.color, {
    this.payload,
  });

  final String label;
  final double value;
  final Color color;
  final Object? payload;
}

class EqPieChartStyle {
  const EqPieChartStyle({
    this.backgroundColor = Colors.transparent,
    this.padding = EqChartDefaults.chartPadding,
    this.legendTextStyle = EqChartDefaults.legendTextStyle,
    this.labelTextStyle = EqChartDefaults.labelTextStyle,
    this.centerTextStyle = EqChartDefaults.centerTextStyle,
    this.centerSubTextStyle = EqChartDefaults.centerSubTextStyle,
    this.legendMarkerSize = 10,
    this.labelGuideColor = EqChartDefaults.axis,
  });

  final Color backgroundColor;
  final EdgeInsets padding;
  final TextStyle legendTextStyle;
  final TextStyle labelTextStyle;
  final TextStyle centerTextStyle;
  final TextStyle centerSubTextStyle;
  final double legendMarkerSize;
  final Color labelGuideColor;
}

class EqPieChartBehavior {
  const EqPieChartBehavior({
    this.showLegend = true,
    this.showLabels = true,
    this.labelPosition = EqPieLabelPosition.auto,
    this.selectionEnabled = true,
    this.selectionOffset = 12,
    this.animateOnDataChange = true,
    this.animationDuration = const Duration(milliseconds: 650),
    this.startAngleDeg = -90,
    this.clockwise = true,
    this.emptyText = 'No data',
    this.centerText,
    this.centerSubText,
  });

  final bool showLegend;
  final bool showLabels;
  final EqPieLabelPosition labelPosition;
  final bool selectionEnabled;
  final double selectionOffset;
  final bool animateOnDataChange;
  final Duration animationDuration;
  final double startAngleDeg;
  final bool clockwise;
  final String emptyText;
  final String? centerText;
  final String? centerSubText;
}

@visibleForTesting
class PieArcLayout {
  const PieArcLayout({
    required this.slice,
    required this.index,
    required this.startAngle,
    required this.sweepAngle,
    required this.fraction,
  });

  final PieSlice slice;
  final int index;
  final double startAngle;
  final double sweepAngle;
  final double fraction;

  double get midAngle => startAngle + (sweepAngle / 2);
}

@visibleForTesting
List<PieArcLayout> computePieArcLayout(
  List<PieSlice> slices,
  EqPieChartBehavior behavior,
) {
  final valid = <PieSlice>[
    for (final slice in slices)
      if (slice.value.isFinite && slice.value > 0) slice,
  ];
  if (valid.isEmpty) {
    return const <PieArcLayout>[];
  }

  final total = valid.fold<double>(0, (sum, slice) => sum + slice.value);
  var cursor = behavior.startAngleDeg * math.pi / 180;
  final direction = behavior.clockwise ? 1.0 : -1.0;
  final layouts = <PieArcLayout>[];

  for (var index = 0; index < valid.length; index++) {
    final slice = valid[index];
    final sweep = (slice.value / total) * math.pi * 2 * direction;
    layouts.add(
      PieArcLayout(
        slice: slice,
        index: index,
        startAngle: cursor,
        sweepAngle: sweep,
        fraction: slice.value / total,
      ),
    );
    cursor += sweep;
  }

  return layouts;
}

class EqPieChart extends StatelessWidget {
  const EqPieChart({
    super.key,
    required this.slices,
    this.style = const EqPieChartStyle(),
    this.behavior = const EqPieChartBehavior(),
    this.onItemTap,
  });

  final List<PieSlice> slices;
  final EqPieChartStyle style;
  final EqPieChartBehavior behavior;
  final EqSelectionChanged<PieSlice>? onItemTap;

  @override
  Widget build(BuildContext context) {
    return _EqPieChartBase(
      slices: slices,
      style: style,
      behavior: behavior,
      holeRatio: 0,
      onItemTap: onItemTap,
    );
  }
}

class EqDonutChart extends StatelessWidget {
  const EqDonutChart({
    super.key,
    required this.slices,
    this.style = const EqPieChartStyle(),
    this.behavior = const EqPieChartBehavior(),
    this.holeRatio = 0.58,
    this.onItemTap,
  }) : assert(holeRatio > 0 && holeRatio < 0.9);

  final List<PieSlice> slices;
  final EqPieChartStyle style;
  final EqPieChartBehavior behavior;
  final double holeRatio;
  final EqSelectionChanged<PieSlice>? onItemTap;

  @override
  Widget build(BuildContext context) {
    return _EqPieChartBase(
      slices: slices,
      style: style,
      behavior: behavior,
      holeRatio: holeRatio,
      onItemTap: onItemTap,
    );
  }
}

class _EqPieChartBase extends StatefulWidget {
  const _EqPieChartBase({
    required this.slices,
    required this.style,
    required this.behavior,
    required this.holeRatio,
    this.onItemTap,
  });

  final List<PieSlice> slices;
  final EqPieChartStyle style;
  final EqPieChartBehavior behavior;
  final double holeRatio;
  final EqSelectionChanged<PieSlice>? onItemTap;

  @override
  State<_EqPieChartBase> createState() => _EqPieChartBaseState();
}

class _EqPieChartBaseState extends State<_EqPieChartBase>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int? _selectedIndex;

  List<PieArcLayout> get _layouts =>
      computePieArcLayout(widget.slices, widget.behavior);

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
  void didUpdateWidget(covariant _EqPieChartBase oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.behavior.animationDuration !=
        widget.behavior.animationDuration) {
      _controller.duration = widget.behavior.animationDuration;
    }
    if (widget.behavior.animateOnDataChange &&
        (oldWidget.slices != widget.slices ||
            oldWidget.behavior.startAngleDeg != widget.behavior.startAngleDeg ||
            oldWidget.behavior.clockwise != widget.behavior.clockwise)) {
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
    final layouts = _layouts;
    final tappedIndex = _resolveTouchedIndex(
      details.localPosition,
      size,
      layouts,
      widget.style.padding,
      widget.holeRatio,
    );
    if (tappedIndex == null) {
      return;
    }

    final layout = layouts[tappedIndex];
    if (widget.behavior.selectionEnabled) {
      setState(() {
        _selectedIndex = _selectedIndex == tappedIndex ? null : tappedIndex;
      });
    }

    widget.onItemTap?.call(
      EqChartSelection<PieSlice>(
        seriesIndex: 0,
        itemIndex: tappedIndex,
        datum: layout.slice,
        localPosition: details.localPosition,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final layouts = _layouts;
    final legend = widget.behavior.showLegend
        ? Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
            child: EqChartLegend(
              items: layouts
                  .map(
                    (layout) => EqChartLegendItem(
                      label: layout.slice.label,
                      color: layout.slice.color,
                    ),
                  )
                  .toList(growable: false),
              textStyle: widget.style.legendTextStyle,
              markerSize: widget.style.legendMarkerSize,
            ),
          )
        : const SizedBox.shrink();

    final chartChild = layouts.isEmpty
        ? DecoratedBox(
            decoration: BoxDecoration(color: widget.style.backgroundColor),
            child: Center(
              child: Text(
                widget.behavior.emptyText,
                style: widget.style.labelTextStyle.copyWith(
                  color: EqChartDefaults.softInk,
                ),
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
                        : 260,
                  );
                  return GestureDetector(
                    onTapUp: widget.onItemTap != null ||
                            widget.behavior.selectionEnabled
                        ? (details) => _handleTap(details, size)
                        : null,
                    child: RepaintBoundary(
                      child: CustomPaint(
                        size: size,
                        painter: _PieChartPainter(
                          layouts: layouts,
                          progress: _controller.value,
                          style: widget.style,
                          behavior: widget.behavior,
                          holeRatio: widget.holeRatio,
                          selectedIndex: _selectedIndex,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final boundedHeight = constraints.maxHeight.isFinite;
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (boundedHeight)
              Expanded(child: chartChild)
            else
              SizedBox(height: 260, child: chartChild),
            legend,
          ],
        );

        return DecoratedBox(
          decoration: BoxDecoration(color: widget.style.backgroundColor),
          child: content,
        );
      },
    );
  }
}

class _PieChartPainter extends CustomPainter {
  const _PieChartPainter({
    required this.layouts,
    required this.progress,
    required this.style,
    required this.behavior,
    required this.holeRatio,
    required this.selectedIndex,
  });

  final List<PieArcLayout> layouts;
  final double progress;
  final EqPieChartStyle style;
  final EqPieChartBehavior behavior;
  final double holeRatio;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = style.padding.deflateRect(Offset.zero & size);
    final radius = math.min(bounds.width, bounds.height) / 2;
    if (radius <= 0) {
      return;
    }

    final center = bounds.center;
    final innerRadius = radius * holeRatio;

    for (final layout in layouts) {
      final animatedSweep = layout.sweepAngle * progress;
      final translate =
          selectedIndex == layout.index && behavior.selectionEnabled
              ? Offset(
                  math.cos(layout.midAngle) * behavior.selectionOffset,
                  math.sin(layout.midAngle) * behavior.selectionOffset,
                )
              : Offset.zero;
      final shiftedCenter = center + translate;

      if (holeRatio > 0) {
        final ringRect = Rect.fromCircle(
          center: shiftedCenter,
          radius: (radius + innerRadius) / 2,
        );
        final ringPaint = Paint()
          ..color = layout.slice.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius - innerRadius;
        canvas.drawArc(
          ringRect,
          layout.startAngle,
          animatedSweep,
          false,
          ringPaint,
        );
      } else {
        final arcRect = Rect.fromCircle(center: shiftedCenter, radius: radius);
        final path = Path()
          ..moveTo(shiftedCenter.dx, shiftedCenter.dy)
          ..arcTo(arcRect, layout.startAngle, animatedSweep, false)
          ..close();
        canvas.drawPath(path, Paint()..color = layout.slice.color);
      }
    }

    if (behavior.showLabels) {
      for (final layout in layouts) {
        _paintLabel(canvas, center, radius, innerRadius, layout);
      }
    }

    if (holeRatio > 0) {
      _paintCenterText(canvas, center);
    }
  }

  void _paintCenterText(Canvas canvas, Offset center) {
    final centerText = behavior.centerText;
    final subText = behavior.centerSubText;
    if (centerText == null && subText == null) {
      return;
    }

    final centerPainter = centerText == null
        ? null
        : buildTextPainter(
            centerText,
            style.centerTextStyle,
            textAlign: TextAlign.center,
          );
    final subPainter = subText == null
        ? null
        : buildTextPainter(
            subText,
            style.centerSubTextStyle,
            textAlign: TextAlign.center,
          );

    final totalHeight = (centerPainter?.height ?? 0) +
        ((centerPainter != null && subPainter != null) ? 4 : 0) +
        (subPainter?.height ?? 0);
    var top = center.dy - totalHeight / 2;
    if (centerPainter != null) {
      centerPainter.paint(
        canvas,
        Offset(center.dx - centerPainter.width / 2, top),
      );
      top += centerPainter.height + 4;
    }
    if (subPainter != null) {
      subPainter.paint(
        canvas,
        Offset(center.dx - subPainter.width / 2, top),
      );
    }
  }

  void _paintLabel(
    Canvas canvas,
    Offset center,
    double radius,
    double innerRadius,
    PieArcLayout layout,
  ) {
    final midAngle = layout.midAngle;
    final labelPosition = switch (behavior.labelPosition) {
      EqPieLabelPosition.inside => EqPieLabelPosition.inside,
      EqPieLabelPosition.outside => EqPieLabelPosition.outside,
      EqPieLabelPosition.auto => layout.fraction > 0.13 || holeRatio > 0
          ? EqPieLabelPosition.inside
          : EqPieLabelPosition.outside,
    };
    final text = '${layout.slice.label} ${(layout.fraction * 100).round()}%';
    final painter = buildTextPainter(
      text,
      style.labelTextStyle,
      textAlign: TextAlign.center,
    );

    if (labelPosition == EqPieLabelPosition.inside) {
      final labelRadius =
          holeRatio > 0 ? (radius + innerRadius) / 2 : radius * 0.64;
      final offset = Offset(
        center.dx + math.cos(midAngle) * labelRadius - painter.width / 2,
        center.dy + math.sin(midAngle) * labelRadius - painter.height / 2,
      );
      painter.paint(canvas, offset);
      return;
    }

    final anchor = Offset(
      center.dx + math.cos(midAngle) * radius,
      center.dy + math.sin(midAngle) * radius,
    );
    final outer = Offset(
      center.dx + math.cos(midAngle) * (radius + 18),
      center.dy + math.sin(midAngle) * (radius + 18),
    );
    final isRight = math.cos(midAngle) >= 0;
    final labelOffset = Offset(
      outer.dx + (isRight ? 6 : -painter.width - 6),
      outer.dy - painter.height / 2,
    );

    canvas.drawLine(
      anchor,
      outer,
      Paint()
        ..color = style.labelGuideColor
        ..strokeWidth = 1.5,
    );
    painter.paint(canvas, labelOffset);
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.layouts != layouts ||
        oldDelegate.progress != progress ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.holeRatio != holeRatio;
  }
}

int? _resolveTouchedIndex(
  Offset localPosition,
  Size size,
  List<PieArcLayout> layouts,
  EdgeInsets padding,
  double holeRatio,
) {
  if (layouts.isEmpty) {
    return null;
  }

  final bounds = padding.deflateRect(Offset.zero & size);
  final radius = math.min(bounds.width, bounds.height) / 2;
  final center = bounds.center;
  final distance = (localPosition - center).distance;
  final innerRadius = radius * holeRatio;

  if (distance > radius || distance < innerRadius) {
    return null;
  }

  var angle =
      math.atan2(localPosition.dy - center.dy, localPosition.dx - center.dx);
  if (angle < -math.pi) {
    angle += 2 * math.pi;
  }

  for (final layout in layouts) {
    final start = layout.startAngle;
    final end = layout.startAngle + layout.sweepAngle;
    final normalized = _normalizeAngle(angle);
    final normalizedStart = _normalizeAngle(start);
    final normalizedEnd = _normalizeAngle(end);

    if (layout.sweepAngle >= 0) {
      if (normalizedStart <= normalizedEnd) {
        if (normalized >= normalizedStart && normalized <= normalizedEnd) {
          return layout.index;
        }
      } else if (normalized >= normalizedStart || normalized <= normalizedEnd) {
        return layout.index;
      }
    } else {
      if (normalizedEnd <= normalizedStart) {
        if (normalized <= normalizedStart && normalized >= normalizedEnd) {
          return layout.index;
        }
      } else if (normalized <= normalizedStart || normalized >= normalizedEnd) {
        return layout.index;
      }
    }
  }

  return null;
}

double _normalizeAngle(double value) {
  var out = value % (math.pi * 2);
  if (out < 0) {
    out += math.pi * 2;
  }
  return out;
}
