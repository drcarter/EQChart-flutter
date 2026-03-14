import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../common/chart_legend.dart';
import '../../common/chart_math.dart';
import '../../common/chart_types.dart';
import '../../theme/chart_defaults.dart';

class BubbleDatum {
  const BubbleDatum({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    this.label,
    this.legendGroup,
    this.payload,
  });

  final double x;
  final double y;
  final double size;
  final Color color;
  final String? label;
  final String? legendGroup;
  final Object? payload;
}

enum EqBubbleLayoutMode {
  scatter,
  packed,
}

class EqBubbleScaleOverride {
  const EqBubbleScaleOverride({
    this.xMin,
    this.xMax,
    this.yMin,
    this.yMax,
    this.sizeMin,
    this.sizeMax,
  });

  final double? xMin;
  final double? xMax;
  final double? yMin;
  final double? yMax;
  final double? sizeMin;
  final double? sizeMax;
}

class EqBubbleChartStyle {
  const EqBubbleChartStyle({
    this.backgroundColor = Colors.transparent,
    this.padding = EqChartDefaults.chartPadding,
    this.axisColor = EqChartDefaults.axis,
    this.gridColor = EqChartDefaults.grid,
    this.axisLabelTextStyle = EqChartDefaults.axisTextStyle,
    this.legendTextStyle = EqChartDefaults.legendTextStyle,
    this.bubbleLabelTextStyle = EqChartDefaults.labelTextStyle,
    this.selectionStrokeColor = Colors.white,
    this.legendMarkerSize = 10,
    this.minBubbleRadius = 8,
    this.maxBubbleRadiusRatio = 0.12,
  });

  final Color backgroundColor;
  final EdgeInsets padding;
  final Color axisColor;
  final Color gridColor;
  final TextStyle axisLabelTextStyle;
  final TextStyle legendTextStyle;
  final TextStyle bubbleLabelTextStyle;
  final Color selectionStrokeColor;
  final double legendMarkerSize;
  final double minBubbleRadius;
  final double maxBubbleRadiusRatio;
}

class EqBubbleChartBehavior {
  const EqBubbleChartBehavior({
    this.showLegend = true,
    this.showAxes = true,
    this.showGrid = true,
    this.showTicks = true,
    this.animateOnDataChange = true,
    this.selectionEnabled = true,
    this.animationDuration = const Duration(milliseconds: 720),
    this.layoutMode = EqBubbleLayoutMode.scatter,
    this.scaleOverride = const EqBubbleScaleOverride(),
    this.xTickCount = 5,
    this.yTickCount = 5,
    this.xLabelFormatter,
    this.yLabelFormatter,
    this.emptyText = 'No data',
  });

  final bool showLegend;
  final bool showAxes;
  final bool showGrid;
  final bool showTicks;
  final bool animateOnDataChange;
  final bool selectionEnabled;
  final Duration animationDuration;
  final EqBubbleLayoutMode layoutMode;
  final EqBubbleScaleOverride scaleOverride;
  final int xTickCount;
  final int yTickCount;
  final EqValueFormatter? xLabelFormatter;
  final EqValueFormatter? yLabelFormatter;
  final String emptyText;
}

@visibleForTesting
class BubbleNumericRange {
  const BubbleNumericRange({
    required this.min,
    required this.max,
  });

  final double min;
  final double max;

  double get span => max - min;
}

@visibleForTesting
class BubbleNodeLayout {
  const BubbleNodeLayout({
    required this.center,
    required this.radius,
    required this.seriesIndex,
    required this.itemIndex,
    required this.datum,
  });

  final Offset center;
  final double radius;
  final int seriesIndex;
  final int itemIndex;
  final BubbleDatum datum;
}

@visibleForTesting
class BubbleChartLayout {
  const BubbleChartLayout({
    required this.plotRect,
    required this.xRange,
    required this.yRange,
    required this.sizeRange,
    required this.xTicks,
    required this.yTicks,
    required this.bubbles,
  });

  final Rect plotRect;
  final BubbleNumericRange xRange;
  final BubbleNumericRange yRange;
  final BubbleNumericRange sizeRange;
  final List<double> xTicks;
  final List<double> yTicks;
  final List<BubbleNodeLayout> bubbles;
}

@visibleForTesting
BubbleChartLayout computeBubbleChartLayout(
  Size size,
  List<BubbleDatum> data,
  EqBubbleChartStyle style,
  EqBubbleChartBehavior behavior,
) {
  final validData = <BubbleDatum>[
    for (final datum in data)
      if (datum.x.isFinite &&
          datum.y.isFinite &&
          datum.size.isFinite &&
          datum.size > 0)
        datum,
  ];
  final usesAxes = behavior.layoutMode == EqBubbleLayoutMode.scatter &&
      (behavior.showAxes || behavior.showTicks);
  final leftReserve = usesAxes ? 52.0 : 0.0;
  final bottomReserve = usesAxes ? 38.0 : 0.0;
  final topReserve =
      behavior.layoutMode == EqBubbleLayoutMode.scatter ? 12.0 : 0.0;
  final rightReserve =
      behavior.layoutMode == EqBubbleLayoutMode.scatter ? 12.0 : 0.0;

  final plotRect = Rect.fromLTWH(
    style.padding.left + leftReserve,
    style.padding.top + topReserve,
    math.max(
      0.0,
      size.width - style.padding.horizontal - leftReserve - rightReserve,
    ),
    math.max(
      0.0,
      size.height - style.padding.vertical - bottomReserve - topReserve,
    ),
  );

  final xRange = _resolveBubbleRange(
    validData.map((datum) => datum.x),
    behavior.scaleOverride.xMin,
    behavior.scaleOverride.xMax,
  );
  final yRange = _resolveBubbleRange(
    validData.map((datum) => datum.y),
    behavior.scaleOverride.yMin,
    behavior.scaleOverride.yMax,
  );
  final sizeRange = _resolveBubbleRange(
    validData.map((datum) => datum.size),
    behavior.scaleOverride.sizeMin,
    behavior.scaleOverride.sizeMax,
  );

  if (plotRect.width <= 0 || plotRect.height <= 0 || validData.isEmpty) {
    return BubbleChartLayout(
      plotRect: plotRect,
      xRange: xRange,
      yRange: yRange,
      sizeRange: sizeRange,
      xTicks: const <double>[],
      yTicks: const <double>[],
      bubbles: const <BubbleNodeLayout>[],
    );
  }

  final minRadius = math.max(
    style.minBubbleRadius,
    math.min(plotRect.width, plotRect.height) * 0.01,
  );
  final maxRadius =
      math.min(plotRect.width, plotRect.height) * style.maxBubbleRadiusRatio;
  final bubbles = behavior.layoutMode == EqBubbleLayoutMode.packed
      ? _computePackedBubbleLayout(
          plotRect,
          validData,
          sizeRange,
          minRadius,
          maxRadius,
        )
      : _computeScatterBubbleLayout(
          plotRect,
          validData,
          xRange,
          yRange,
          sizeRange,
          minRadius,
          maxRadius,
        );

  return BubbleChartLayout(
    plotRect: plotRect,
    xRange: xRange,
    yRange: yRange,
    sizeRange: sizeRange,
    xTicks: behavior.layoutMode == EqBubbleLayoutMode.scatter
        ? _buildBubbleTicks(xRange, behavior.xTickCount)
        : const <double>[],
    yTicks: behavior.layoutMode == EqBubbleLayoutMode.scatter
        ? _buildBubbleTicks(yRange, behavior.yTickCount)
        : const <double>[],
    bubbles: bubbles,
  );
}

class EqBubbleChart extends StatefulWidget {
  const EqBubbleChart({
    super.key,
    required this.data,
    this.style = const EqBubbleChartStyle(),
    this.behavior = const EqBubbleChartBehavior(),
    this.onItemTap,
  });

  final List<BubbleDatum> data;
  final EqBubbleChartStyle style;
  final EqBubbleChartBehavior behavior;
  final EqSelectionChanged<BubbleDatum>? onItemTap;

  @override
  State<EqBubbleChart> createState() => _EqBubbleChartState();
}

class _EqBubbleChartState extends State<EqBubbleChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
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
  void didUpdateWidget(covariant EqBubbleChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.behavior.animationDuration !=
        widget.behavior.animationDuration) {
      _controller.duration = widget.behavior.animationDuration;
    }
    if (widget.behavior.animateOnDataChange &&
        (oldWidget.data != widget.data ||
            oldWidget.behavior.layoutMode != widget.behavior.layoutMode ||
            oldWidget.behavior.scaleOverride !=
                widget.behavior.scaleOverride)) {
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
    final layout = computeBubbleChartLayout(
      size,
      widget.data,
      widget.style,
      widget.behavior,
    );
    final hit = layout.bubbles.reversed.firstWhere(
      (bubble) =>
          (bubble.center - details.localPosition).distance <= bubble.radius,
      orElse: () => const BubbleNodeLayout(
        center: Offset.zero,
        radius: -1,
        seriesIndex: 0,
        itemIndex: -1,
        datum: BubbleDatum(
          x: 0,
          y: 0,
          size: 0,
          color: Colors.transparent,
        ),
      ),
    );
    if (hit.itemIndex < 0) {
      return;
    }

    if (widget.behavior.selectionEnabled) {
      setState(() {
        _selectedItemIndex = hit.itemIndex;
      });
    }
    widget.onItemTap?.call(
      EqChartSelection<BubbleDatum>(
        seriesIndex: hit.seriesIndex,
        itemIndex: hit.itemIndex,
        datum: hit.datum,
        localPosition: details.localPosition,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final validData = widget.data.where(
      (datum) =>
          datum.x.isFinite &&
          datum.y.isFinite &&
          datum.size.isFinite &&
          datum.size > 0,
    );
    final hasData = validData.isNotEmpty;
    final legendItems = _resolveBubbleLegendItems(widget.data);
    final xFormatter =
        widget.behavior.xLabelFormatter ?? formatBubbleNumberCompact;
    final yFormatter =
        widget.behavior.yLabelFormatter ?? formatBubbleNumberCompact;

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
                        : 320,
                  );
                  return GestureDetector(
                    onTapUp: widget.onItemTap != null ||
                            widget.behavior.selectionEnabled
                        ? (details) => _handleTap(details, size)
                        : null,
                    child: RepaintBoundary(
                      child: CustomPaint(
                        size: size,
                        painter: _BubbleChartPainter(
                          data: widget.data,
                          style: widget.style,
                          behavior: widget.behavior,
                          xFormatter: xFormatter,
                          yFormatter: yFormatter,
                          progress: _controller.value,
                          selectedItemIndex: _selectedItemIndex,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );

    final legend = widget.behavior.showLegend && legendItems.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
            child: EqChartLegend(
              items: legendItems,
              textStyle: widget.style.legendTextStyle,
              markerSize: widget.style.legendMarkerSize,
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
                SizedBox(height: 320, child: chartBody),
              legend,
            ],
          );
        },
      ),
    );
  }
}

class _BubbleChartPainter extends CustomPainter {
  const _BubbleChartPainter({
    required this.data,
    required this.style,
    required this.behavior,
    required this.xFormatter,
    required this.yFormatter,
    required this.progress,
    required this.selectedItemIndex,
  });

  final List<BubbleDatum> data;
  final EqBubbleChartStyle style;
  final EqBubbleChartBehavior behavior;
  final EqValueFormatter xFormatter;
  final EqValueFormatter yFormatter;
  final double progress;
  final int? selectedItemIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = computeBubbleChartLayout(size, data, style, behavior);
    if (layout.plotRect.width <= 0 || layout.plotRect.height <= 0) {
      return;
    }

    final axisPaint = Paint()
      ..color = style.axisColor
      ..strokeWidth = 1.2;
    final gridPaint = Paint()
      ..color = style.gridColor
      ..strokeWidth = 1;
    final labelCenter = layout.plotRect.center;

    if (behavior.layoutMode == EqBubbleLayoutMode.scatter &&
        behavior.showGrid) {
      for (final tick in layout.xTicks) {
        final x = _mapBubbleLinear(
            tick, layout.xRange, layout.plotRect.left, layout.plotRect.right);
        canvas.drawLine(
          Offset(x, layout.plotRect.top),
          Offset(x, layout.plotRect.bottom),
          gridPaint,
        );
      }
      for (final tick in layout.yTicks) {
        final y = _mapBubbleLinearInverted(
            tick, layout.yRange, layout.plotRect.top, layout.plotRect.bottom);
        canvas.drawLine(
          Offset(layout.plotRect.left, y),
          Offset(layout.plotRect.right, y),
          gridPaint,
        );
      }
    }

    if (behavior.layoutMode == EqBubbleLayoutMode.scatter &&
        behavior.showAxes) {
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
    }

    if (behavior.layoutMode == EqBubbleLayoutMode.scatter &&
        behavior.showTicks) {
      for (final tick in layout.xTicks) {
        final x = _mapBubbleLinear(
            tick, layout.xRange, layout.plotRect.left, layout.plotRect.right);
        final painter = buildTextPainter(
          xFormatter(tick),
          style.axisLabelTextStyle,
          textAlign: TextAlign.center,
        );
        painter.paint(
          canvas,
          Offset(x - (painter.width / 2), layout.plotRect.bottom + 8),
        );
      }
      for (final tick in layout.yTicks) {
        final y = _mapBubbleLinearInverted(
            tick, layout.yRange, layout.plotRect.top, layout.plotRect.bottom);
        final painter = buildTextPainter(
          yFormatter(tick),
          style.axisLabelTextStyle,
          textAlign: TextAlign.right,
        );
        painter.paint(
          canvas,
          Offset(
              layout.plotRect.left - painter.width - 8, y - painter.height / 2),
        );
      }
    }

    for (final bubble in layout.bubbles) {
      final animatedCenter = Offset.lerp(labelCenter, bubble.center, progress)!;
      final animatedRadius = bubble.radius * (0.2 + (0.8 * progress));
      canvas.drawCircle(
        animatedCenter,
        animatedRadius,
        Paint()..color = bubble.datum.color,
      );

      if (selectedItemIndex == bubble.itemIndex && behavior.selectionEnabled) {
        canvas.drawCircle(
          animatedCenter,
          animatedRadius,
          Paint()
            ..color = style.selectionStrokeColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }

      _paintBubbleLabel(canvas, bubble, animatedCenter, animatedRadius);
    }
  }

  void _paintBubbleLabel(
    Canvas canvas,
    BubbleNodeLayout bubble,
    Offset center,
    double radius,
  ) {
    final label = bubble.datum.label?.trim();
    if (label == null || label.isEmpty || radius < 18) {
      return;
    }

    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: style.bubbleLabelTextStyle.copyWith(
          color: bubble.datum.color.computeLuminance() > 0.52
              ? const Color(0xFF111111)
              : Colors.white,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 3,
      ellipsis: '…',
    )..layout(maxWidth: radius * 1.55);

    if (painter.width > radius * 1.7 || painter.height > radius * 1.5) {
      return;
    }

    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _BubbleChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.style != style ||
        oldDelegate.behavior != behavior ||
        oldDelegate.progress != progress ||
        oldDelegate.selectedItemIndex != selectedItemIndex;
  }
}

BubbleNumericRange _resolveBubbleRange(
  Iterable<double> values,
  double? overrideMin,
  double? overrideMax, {
  double paddingRatio = 0.05,
}) {
  final list = values.toList(growable: false);
  var min = overrideMin ?? (list.isEmpty ? 0.0 : list.reduce(math.min));
  var max = overrideMax ?? (list.isEmpty ? 1.0 : list.reduce(math.max));

  if (min > max) {
    final temp = min;
    min = max;
    max = temp;
  }

  if ((max - min).abs() < 1e-9) {
    final pad = math.max(1.0, min.abs() * paddingRatio);
    min -= pad;
    max += pad;
  }

  return BubbleNumericRange(min: min, max: max);
}

double _normalizeBubbleValue(double value, BubbleNumericRange range) {
  if (range.span <= 0) {
    return 0.5;
  }
  return ((value - range.min) / range.span).clamp(0.0, 1.0).toDouble();
}

double _mapBubbleLinear(
  double value,
  BubbleNumericRange range,
  double outMin,
  double outMax,
) {
  final t = _normalizeBubbleValue(value, range);
  return outMin + ((outMax - outMin) * t);
}

double _mapBubbleLinearInverted(
  double value,
  BubbleNumericRange range,
  double outMin,
  double outMax,
) {
  final t = _normalizeBubbleValue(value, range);
  return outMax - ((outMax - outMin) * t);
}

double _mapBubbleRadius(
  double value,
  BubbleNumericRange range,
  double minRadius,
  double maxRadius,
) {
  final eased = math.sqrt(_normalizeBubbleValue(value, range));
  return minRadius + ((maxRadius - minRadius) * eased);
}

List<double> _buildBubbleTicks(BubbleNumericRange range, int count) {
  final safeCount = count < 2 ? 2 : count;
  if (range.span <= 0) {
    return <double>[range.min, range.max];
  }
  return List<double>.generate(
    safeCount,
    (index) => range.min + (range.span * index) / (safeCount - 1),
    growable: false,
  );
}

List<BubbleNodeLayout> _computeScatterBubbleLayout(
  Rect plotRect,
  List<BubbleDatum> data,
  BubbleNumericRange xRange,
  BubbleNumericRange yRange,
  BubbleNumericRange sizeRange,
  double minRadius,
  double maxRadius,
) {
  final layouts = <BubbleNodeLayout>[];
  for (var index = 0; index < data.length; index++) {
    final datum = data[index];
    final radius =
        _mapBubbleRadius(datum.size, sizeRange, minRadius, maxRadius);
    final center = Offset(
      _mapBubbleLinear(datum.x, xRange, plotRect.left, plotRect.right)
          .clamp(plotRect.left + radius, plotRect.right - radius),
      _mapBubbleLinearInverted(datum.y, yRange, plotRect.top, plotRect.bottom)
          .clamp(plotRect.top + radius, plotRect.bottom - radius),
    );
    layouts.add(
      BubbleNodeLayout(
        center: center,
        radius: radius,
        seriesIndex: 0,
        itemIndex: index,
        datum: datum,
      ),
    );
  }
  layouts.sort((a, b) => b.radius.compareTo(a.radius));
  return layouts;
}

class _PackedBubbleNode {
  _PackedBubbleNode({
    required this.datum,
    required this.radius,
    required this.index,
    required this.x,
    required this.y,
  });

  final BubbleDatum datum;
  final double radius;
  final int index;
  double x;
  double y;
}

List<BubbleNodeLayout> _computePackedBubbleLayout(
  Rect plotRect,
  List<BubbleDatum> data,
  BubbleNumericRange sizeRange,
  double minRadius,
  double maxRadius,
) {
  final centerX = plotRect.center.dx;
  final centerY = plotRect.center.dy;
  final spiralStep = maxRadius * 1.45;
  const gap = 2.0;
  const gravity = 0.045;
  const iterations = 220;
  const goldenAngle = 2.3999633;

  final nodes = data
      .asMap()
      .entries
      .map(
        (entry) => _PackedBubbleNode(
          datum: entry.value,
          radius: _mapBubbleRadius(
              entry.value.size, sizeRange, minRadius, maxRadius),
          index: entry.key,
          x: centerX,
          y: centerY,
        ),
      )
      .toList(growable: false)
    ..sort((a, b) => b.radius.compareTo(a.radius));

  for (var index = 0; index < nodes.length; index++) {
    final node = nodes[index];
    if (index == 0) {
      node.x = centerX;
      node.y = centerY;
      continue;
    }
    final angle = goldenAngle * index;
    final distance = math.sqrt(index) * spiralStep;
    node.x = centerX + (math.cos(angle) * distance);
    node.y = centerY + (math.sin(angle) * distance);
  }

  for (var iteration = 0; iteration < iterations; iteration++) {
    for (final node in nodes) {
      node.x += (centerX - node.x) * gravity;
      node.y += (centerY - node.y) * gravity;
    }

    for (var i = 0; i < nodes.length - 1; i++) {
      final a = nodes[i];
      for (var j = i + 1; j < nodes.length; j++) {
        final b = nodes[j];
        var dx = b.x - a.x;
        var dy = b.y - a.y;
        var distance = math.sqrt((dx * dx) + (dy * dy));
        final minDistance = a.radius + b.radius + gap;

        if (distance < minDistance) {
          if (distance < 0.001) {
            final seedAngle = (((i * 73) + (j * 37)) % 360) * (math.pi / 180);
            dx = math.cos(seedAngle);
            dy = math.sin(seedAngle);
            distance = 1;
          }

          final overlap = (minDistance - distance) * 0.5;
          final ux = dx / distance;
          final uy = dy / distance;

          a.x -= ux * overlap;
          a.y -= uy * overlap;
          b.x += ux * overlap;
          b.y += uy * overlap;
        }
      }
    }
  }

  var minX = double.infinity;
  var minY = double.infinity;
  var maxX = double.negativeInfinity;
  var maxY = double.negativeInfinity;

  for (final node in nodes) {
    minX = math.min(minX, node.x - node.radius);
    minY = math.min(minY, node.y - node.radius);
    maxX = math.max(maxX, node.x + node.radius);
    maxY = math.max(maxY, node.y + node.radius);
  }

  final clusterWidth = math.max(1.0, maxX - minX);
  final clusterHeight = math.max(1.0, maxY - minY);
  final scale = math.min(
    (plotRect.width * 0.94) / clusterWidth,
    (plotRect.height * 0.94) / clusterHeight,
  );
  final clusterCenterX = (minX + maxX) * 0.5;
  final clusterCenterY = (minY + maxY) * 0.5;

  return nodes.map(
    (node) {
      final radius = node.radius * scale;
      return BubbleNodeLayout(
        center: Offset(
          (centerX + ((node.x - clusterCenterX) * scale))
              .clamp(plotRect.left + radius, plotRect.right - radius),
          (centerY + ((node.y - clusterCenterY) * scale))
              .clamp(plotRect.top + radius, plotRect.bottom - radius),
        ),
        radius: radius,
        seriesIndex: 0,
        itemIndex: node.index,
        datum: node.datum,
      );
    },
  ).toList(growable: false);
}

List<EqChartLegendItem> _resolveBubbleLegendItems(List<BubbleDatum> data) {
  final items = <EqChartLegendItem>[];
  final seen = <String>{};
  for (final datum in data) {
    final label =
        (datum.legendGroup != null && datum.legendGroup!.trim().isNotEmpty)
            ? datum.legendGroup!.trim()
            : _bubbleColorHex(datum.color);
    if (seen.add(label)) {
      items.add(EqChartLegendItem(label: label, color: datum.color));
    }
  }
  return items;
}

String _bubbleColorHex(Color color) {
  final value = color.value & 0x00FFFFFF;
  return '#${value.toRadixString(16).toUpperCase().padLeft(6, '0')}';
}

String formatBubbleNumberCompact(double value) {
  final absValue = value.abs();
  if (absValue >= 1000000000) {
    return '${(value / 1000000000).toStringAsFixed(1)}B';
  }
  if (absValue >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (absValue >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}K';
  }
  if (absValue >= 100) {
    return value.toStringAsFixed(0);
  }
  if (absValue >= 10) {
    return value.toStringAsFixed(1);
  }
  return value.toStringAsFixed(2);
}
