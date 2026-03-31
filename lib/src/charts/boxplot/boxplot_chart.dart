import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../common/chart_math.dart';
import '../../common/chart_types.dart';
import '../../theme/chart_defaults.dart';

class BoxPlotEntry {
  const BoxPlotEntry({
    required this.label,
    required this.min,
    required this.q1,
    required this.median,
    required this.q3,
    required this.max,
    this.outliers = const <double>[],
    this.color,
    this.title,
    this.payload,
  });

  final String label;
  final double min;
  final double q1;
  final double median;
  final double q3;
  final double max;
  final List<double> outliers;
  final Color? color;
  final String? title;
  final Object? payload;
}

class EqBoxPlotChartStyle {
  const EqBoxPlotChartStyle({
    this.backgroundColor = Colors.transparent,
    this.padding = EqChartDefaults.chartPadding,
    this.gridColor = EqChartDefaults.grid,
    this.axisColor = EqChartDefaults.axis,
    this.axisLabelTextStyle = EqChartDefaults.axisTextStyle,
    this.valueLabelTextStyle = EqChartDefaults.labelTextStyle,
    this.defaultBoxColor = EqChartDefaults.accentBlue,
    this.medianLineColor = EqChartDefaults.ink,
    this.outlierColor = EqChartDefaults.accentRose,
    this.selectionColor = EqChartDefaults.ink,
    this.categorySpacing = 10,
    this.boxWidthRatio = 0.52,
    this.boxRadius = 3,
    this.whiskerStrokeWidth = 1.8,
    this.outlierRadius = 3,
    this.selectionPadding = 1.5,
  });

  final Color backgroundColor;
  final EdgeInsets padding;
  final Color gridColor;
  final Color axisColor;
  final TextStyle axisLabelTextStyle;
  final TextStyle valueLabelTextStyle;
  final Color defaultBoxColor;
  final Color medianLineColor;
  final Color outlierColor;
  final Color selectionColor;
  final double categorySpacing;
  final double boxWidthRatio;
  final double boxRadius;
  final double whiskerStrokeWidth;
  final double outlierRadius;
  final double selectionPadding;
}

typedef EqBoxPlotEntryFormatter = String Function(BoxPlotEntry entry);

class EqBoxPlotChartBehavior {
  const EqBoxPlotChartBehavior({
    this.showGrid = true,
    this.showAxes = true,
    this.showValueLabels = true,
    this.animateOnDataChange = true,
    this.selectionEnabled = true,
    this.animationDuration = const Duration(milliseconds: 680),
    this.animationCurve = Curves.easeOutCubic,
    this.animateFromMinValue = true,
    this.emptyText = 'No data',
    this.yTickCount = 6,
    this.yLabelFormatter,
    this.xLabelFormatter,
    this.valueLabelFormatter,
  });

  final bool showGrid;
  final bool showAxes;
  final bool showValueLabels;
  final bool animateOnDataChange;
  final bool selectionEnabled;
  final Duration animationDuration;
  final Curve animationCurve;
  final bool animateFromMinValue;
  final String emptyText;
  final int yTickCount;
  final EqValueFormatter? yLabelFormatter;
  final EqBoxPlotEntryFormatter? xLabelFormatter;
  final EqBoxPlotEntryFormatter? valueLabelFormatter;
}

@visibleForTesting
class ResolvedBoxPlotEntry {
  const ResolvedBoxPlotEntry({
    required this.index,
    required this.label,
    required this.title,
    required this.min,
    required this.q1,
    required this.median,
    required this.q3,
    required this.max,
    required this.outliers,
    required this.color,
    required this.sourceEntry,
  });

  final int index;
  final String label;
  final String? title;
  final double min;
  final double q1;
  final double median;
  final double q3;
  final double max;
  final List<double> outliers;
  final Color color;
  final BoxPlotEntry sourceEntry;
}

@visibleForTesting
class BoxPlotEntryLayout {
  const BoxPlotEntryLayout({
    required this.touchRect,
    required this.boxRect,
    required this.centerX,
    required this.minY,
    required this.maxY,
    required this.medianY,
    required this.capHalfWidth,
    required this.outlierOffsets,
    required this.entry,
  });

  final Rect touchRect;
  final Rect boxRect;
  final double centerX;
  final double minY;
  final double maxY;
  final double medianY;
  final double capHalfWidth;
  final List<Offset> outlierOffsets;
  final ResolvedBoxPlotEntry entry;
}

@visibleForTesting
class BoxPlotChartLayout {
  const BoxPlotChartLayout({
    required this.plotRect,
    required this.minValue,
    required this.maxValue,
    required this.yTicks,
    required this.entries,
  });

  final Rect plotRect;
  final double minValue;
  final double maxValue;
  final List<double> yTicks;
  final List<BoxPlotEntryLayout> entries;
}

String formatBoxPlotAxisValue(double value) {
  if (!value.isFinite) {
    return '0';
  }

  final absolute = value.abs();
  if (absolute >= 1000000) {
    return '${_trimCompactValue(value / 1000000)}M';
  }
  if (absolute >= 1000) {
    return '${_trimCompactValue(value / 1000)}K';
  }
  if ((value - value.roundToDouble()).abs() <= 1e-9) {
    return value.round().toString();
  }
  return _trimCompactValue(value);
}

String _trimCompactValue(double value) {
  final rounded = (value * 10).truncateToDouble() / 10;
  if ((rounded - rounded.roundToDouble()).abs() <= 1e-9) {
    return rounded.round().toString();
  }
  return rounded.toStringAsFixed(1);
}

List<ResolvedBoxPlotEntry> _resolveBoxPlotEntries(
  List<BoxPlotEntry> entries,
  EqBoxPlotChartStyle style,
) {
  final resolved = <ResolvedBoxPlotEntry>[];
  for (var index = 0; index < entries.length; index++) {
    final entry = entries[index];
    if (entry.label.trim().isEmpty) {
      continue;
    }

    final stats = <double>[
      entry.min,
      entry.q1,
      entry.median,
      entry.q3,
      entry.max
    ];
    if (stats.any((value) => !value.isFinite)) {
      continue;
    }

    stats.sort();
    resolved.add(
      ResolvedBoxPlotEntry(
        index: index,
        label: entry.label,
        title: entry.title?.trim().isEmpty ?? true ? null : entry.title,
        min: stats[0],
        q1: stats[1],
        median: stats[2],
        q3: stats[3],
        max: stats[4],
        outliers: entry.outliers
            .where((value) => value.isFinite)
            .toList(growable: false),
        color: entry.color ?? style.defaultBoxColor,
        sourceEntry: entry,
      ),
    );
  }
  return resolved;
}

double _boxPlotValueToY(
  Rect plotRect,
  double value,
  double minValue,
  double maxValue,
) {
  return mapToRange(
    value: value,
    domainMin: minValue,
    domainMax: maxValue,
    rangeMin: plotRect.bottom,
    rangeMax: plotRect.top,
  );
}

double _animatedBoxPlotValue(
  double value,
  double minValue,
  EqBoxPlotChartBehavior behavior,
  double progress,
) {
  if (!behavior.animateFromMinValue) {
    return value;
  }
  return minValue + ((value - minValue) * progress);
}

@visibleForTesting
BoxPlotChartLayout computeBoxPlotChartLayout(
  Size size,
  List<BoxPlotEntry> entries,
  EqBoxPlotChartStyle style,
  EqBoxPlotChartBehavior behavior, {
  double progress = 1,
}) {
  final resolvedEntries = _resolveBoxPlotEntries(entries, style);
  final yFormatter = fallbackValueFormatter(behavior.yLabelFormatter);
  final valueLabelStyle = style.valueLabelTextStyle;
  final valueLabelHeight = measureText('Median', valueLabelStyle).height;
  final axisLabelHeight = measureText('100', style.axisLabelTextStyle).height;

  double minValue = -1;
  double maxValue = 1;
  if (resolvedEntries.isNotEmpty) {
    minValue = resolvedEntries.first.min;
    maxValue = resolvedEntries.first.max;
    for (final entry in resolvedEntries) {
      minValue = math.min(minValue, entry.min);
      maxValue = math.max(maxValue, entry.max);
      for (final outlier in entry.outliers) {
        minValue = math.min(minValue, outlier);
        maxValue = math.max(maxValue, outlier);
      }
    }
    if ((maxValue - minValue).abs() <= 1e-9) {
      minValue -= 1;
      maxValue += 1;
    }
  }

  final yTicks =
      buildLinearTicks(minValue, maxValue, count: behavior.yTickCount);
  final maxTickWidth = yTicks.fold<double>(
    0,
    (current, tick) => math.max(
      current,
      measureText(yFormatter(tick), style.axisLabelTextStyle).width,
    ),
  );
  final leftReserve = style.padding.left + maxTickWidth + 14;
  final bottomReserve = style.padding.bottom + axisLabelHeight + 18;
  final topReserve = style.padding.top +
      (behavior.showValueLabels ? valueLabelHeight + 12 : 10);
  final plotRect = Rect.fromLTWH(
    leftReserve,
    topReserve,
    math.max(0, size.width - leftReserve - style.padding.right),
    math.max(0, size.height - topReserve - bottomReserve),
  );

  if (resolvedEntries.isEmpty || plotRect.width <= 0 || plotRect.height <= 0) {
    return BoxPlotChartLayout(
      plotRect: plotRect,
      minValue: minValue,
      maxValue: maxValue,
      yTicks: yTicks,
      entries: const <BoxPlotEntryLayout>[],
    );
  }

  final slotWidth = plotRect.width / resolvedEntries.length;
  final usableSlotWidth = math.max(1, slotWidth - style.categorySpacing);
  final boxWidth =
      math.max(8, usableSlotWidth * style.boxWidthRatio.clamp(0.2, 0.9));
  final capHalfWidth = boxWidth * 0.35;

  final layouts = <BoxPlotEntryLayout>[];
  final clampedProgress = progress.clamp(0.0, 1.0);
  for (var i = 0; i < resolvedEntries.length; i++) {
    final entry = resolvedEntries[i];
    final slotLeft = plotRect.left + (slotWidth * i);
    final slotRight = slotLeft + slotWidth;
    final centerX = (slotLeft + slotRight) / 2;

    final minY = _boxPlotValueToY(
      plotRect,
      _animatedBoxPlotValue(entry.min, minValue, behavior, clampedProgress),
      minValue,
      maxValue,
    );
    final q1Y = _boxPlotValueToY(
      plotRect,
      _animatedBoxPlotValue(entry.q1, minValue, behavior, clampedProgress),
      minValue,
      maxValue,
    );
    final medianY = _boxPlotValueToY(
      plotRect,
      _animatedBoxPlotValue(entry.median, minValue, behavior, clampedProgress),
      minValue,
      maxValue,
    );
    final q3Y = _boxPlotValueToY(
      plotRect,
      _animatedBoxPlotValue(entry.q3, minValue, behavior, clampedProgress),
      minValue,
      maxValue,
    );
    final maxY = _boxPlotValueToY(
      plotRect,
      _animatedBoxPlotValue(entry.max, minValue, behavior, clampedProgress),
      minValue,
      maxValue,
    );

    final boxRect = Rect.fromLTRB(
      centerX - (boxWidth / 2),
      math.min(q3Y, q1Y),
      centerX + (boxWidth / 2),
      math.max(q3Y, q1Y),
    );
    final touchRect = Rect.fromLTRB(
      slotLeft,
      math.min(maxY, boxRect.top),
      slotRight,
      math.max(minY, boxRect.bottom),
    );

    layouts.add(
      BoxPlotEntryLayout(
        touchRect: touchRect,
        boxRect: boxRect,
        centerX: centerX,
        minY: minY,
        maxY: maxY,
        medianY: medianY,
        capHalfWidth: capHalfWidth,
        outlierOffsets: entry.outliers
            .map(
              (value) => Offset(
                centerX,
                _boxPlotValueToY(
                  plotRect,
                  _animatedBoxPlotValue(
                      value, minValue, behavior, clampedProgress),
                  minValue,
                  maxValue,
                ),
              ),
            )
            .toList(growable: false),
        entry: entry,
      ),
    );
  }

  return BoxPlotChartLayout(
    plotRect: plotRect,
    minValue: minValue,
    maxValue: maxValue,
    yTicks: yTicks,
    entries: layouts,
  );
}

class EqBoxPlotChart extends StatefulWidget {
  const EqBoxPlotChart({
    super.key,
    required this.entries,
    this.style = const EqBoxPlotChartStyle(),
    this.behavior = const EqBoxPlotChartBehavior(),
    this.onItemTap,
  });

  final List<BoxPlotEntry> entries;
  final EqBoxPlotChartStyle style;
  final EqBoxPlotChartBehavior behavior;
  final EqSelectionChanged<BoxPlotEntry>? onItemTap;

  @override
  State<EqBoxPlotChart> createState() => _EqBoxPlotChartState();
}

class _EqBoxPlotChartState extends State<EqBoxPlotChart>
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
  void didUpdateWidget(covariant EqBoxPlotChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.behavior.animationDuration !=
        widget.behavior.animationDuration) {
      _controller.duration = widget.behavior.animationDuration;
    }
    if (widget.behavior.animateOnDataChange &&
        oldWidget.entries != widget.entries) {
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
    final layout = computeBoxPlotChartLayout(
      size,
      widget.entries,
      widget.style,
      widget.behavior,
    );
    final hit = layout.entries.cast<BoxPlotEntryLayout?>().lastWhere(
          (entry) => entry?.touchRect.contains(details.localPosition) ?? false,
          orElse: () => null,
        );
    if (hit == null) {
      return;
    }

    if (widget.behavior.selectionEnabled) {
      setState(() {
        _selectedItemIndex = hit.entry.index;
      });
    }

    widget.onItemTap?.call(
      EqChartSelection<BoxPlotEntry>(
        seriesIndex: 0,
        itemIndex: hit.entry.index,
        datum: hit.entry.sourceEntry,
        localPosition: details.localPosition,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasInteractiveHandler =
        widget.behavior.selectionEnabled || widget.onItemTap != null;
    final yFormatter = fallbackValueFormatter(widget.behavior.yLabelFormatter);
    final xFormatter =
        widget.behavior.xLabelFormatter ?? (BoxPlotEntry entry) => entry.label;
    final valueFormatter = widget.behavior.valueLabelFormatter ??
        (BoxPlotEntry entry) =>
            entry.title ?? formatBoxPlotAxisValue(entry.median);

    return DecoratedBox(
      decoration: BoxDecoration(color: widget.style.backgroundColor),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(
                constraints.maxWidth,
                constraints.maxHeight.isFinite ? constraints.maxHeight : 320,
              );
              final progress =
                  widget.behavior.animationCurve.transform(_controller.value);

              return GestureDetector(
                onTapUp: hasInteractiveHandler
                    ? (details) => _handleTap(details, size)
                    : null,
                child: RepaintBoundary(
                  child: CustomPaint(
                    size: size,
                    painter: _BoxPlotChartPainter(
                      entries: widget.entries,
                      style: widget.style,
                      behavior: widget.behavior,
                      progress: progress,
                      selectedItemIndex: _selectedItemIndex,
                      yFormatter: yFormatter,
                      xFormatter: xFormatter,
                      valueFormatter: valueFormatter,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _BoxPlotChartPainter extends CustomPainter {
  const _BoxPlotChartPainter({
    required this.entries,
    required this.style,
    required this.behavior,
    required this.progress,
    required this.selectedItemIndex,
    required this.yFormatter,
    required this.xFormatter,
    required this.valueFormatter,
  });

  final List<BoxPlotEntry> entries;
  final EqBoxPlotChartStyle style;
  final EqBoxPlotChartBehavior behavior;
  final double progress;
  final int? selectedItemIndex;
  final EqValueFormatter yFormatter;
  final EqBoxPlotEntryFormatter xFormatter;
  final EqBoxPlotEntryFormatter valueFormatter;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = computeBoxPlotChartLayout(
      size,
      entries,
      style,
      behavior,
      progress: progress,
    );
    final axisPaint = Paint()
      ..color = style.axisColor
      ..strokeWidth = 1.1;
    final gridPaint = Paint()
      ..color = style.gridColor
      ..strokeWidth = 1;

    if (layout.entries.isEmpty) {
      final emptyPainter = buildTextPainter(
        behavior.emptyText,
        style.axisLabelTextStyle,
        textAlign: TextAlign.center,
      );
      emptyPainter.paint(
        canvas,
        Offset(
          (size.width - emptyPainter.width) / 2,
          (size.height - emptyPainter.height) / 2,
        ),
      );
      return;
    }

    if (behavior.showGrid) {
      for (final tick in layout.yTicks) {
        final y = _boxPlotValueToY(
            layout.plotRect, tick, layout.minValue, layout.maxValue);
        canvas.drawLine(
          Offset(layout.plotRect.left, y),
          Offset(layout.plotRect.right, y),
          gridPaint,
        );

        final tickPainter = buildTextPainter(
          yFormatter(tick),
          style.axisLabelTextStyle,
          textAlign: TextAlign.right,
        );
        tickPainter.paint(
          canvas,
          Offset(
            layout.plotRect.left - tickPainter.width - 8,
            y - (tickPainter.height / 2),
          ),
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
    }

    final boxPaint = Paint()..style = PaintingStyle.fill;
    final whiskerPaint = Paint()
      ..color = style.axisColor
      ..strokeWidth = style.whiskerStrokeWidth;
    final medianPaint = Paint()
      ..color = style.medianLineColor
      ..strokeWidth = style.whiskerStrokeWidth;
    final outlierPaint = Paint()
      ..color = style.outlierColor
      ..style = PaintingStyle.fill;
    final selectionPaint = Paint()
      ..color = style.selectionColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final entryLayout in layout.entries) {
      canvas.drawLine(
        Offset(entryLayout.centerX, entryLayout.maxY),
        Offset(entryLayout.centerX, entryLayout.boxRect.top),
        whiskerPaint,
      );
      canvas.drawLine(
        Offset(entryLayout.centerX, entryLayout.boxRect.bottom),
        Offset(entryLayout.centerX, entryLayout.minY),
        whiskerPaint,
      );
      canvas.drawLine(
        Offset(
            entryLayout.centerX - entryLayout.capHalfWidth, entryLayout.maxY),
        Offset(
            entryLayout.centerX + entryLayout.capHalfWidth, entryLayout.maxY),
        whiskerPaint,
      );
      canvas.drawLine(
        Offset(
            entryLayout.centerX - entryLayout.capHalfWidth, entryLayout.minY),
        Offset(
            entryLayout.centerX + entryLayout.capHalfWidth, entryLayout.minY),
        whiskerPaint,
      );

      boxPaint.color = entryLayout.entry.color;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          entryLayout.boxRect,
          Radius.circular(style.boxRadius),
        ),
        boxPaint,
      );
      canvas.drawLine(
        Offset(entryLayout.boxRect.left, entryLayout.medianY),
        Offset(entryLayout.boxRect.right, entryLayout.medianY),
        medianPaint,
      );

      for (final outlier in entryLayout.outlierOffsets) {
        canvas.drawCircle(outlier, style.outlierRadius, outlierPaint);
      }

      if (selectedItemIndex == entryLayout.entry.index) {
        final top = math.min(entryLayout.maxY, entryLayout.boxRect.top) -
            style.selectionPadding;
        final bottom = math.max(entryLayout.minY, entryLayout.boxRect.bottom) +
            style.selectionPadding;
        final selectionRect = Rect.fromLTRB(
          entryLayout.boxRect.left - style.selectionPadding,
          top,
          entryLayout.boxRect.right + style.selectionPadding,
          bottom,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            selectionRect,
            Radius.circular(style.boxRadius),
          ),
          selectionPaint,
        );
      }

      final categoryPainter = buildTextPainter(
        xFormatter(entryLayout.entry.sourceEntry),
        style.axisLabelTextStyle,
        textAlign: TextAlign.center,
      );
      categoryPainter.paint(
        canvas,
        Offset(
          entryLayout.centerX - (categoryPainter.width / 2),
          layout.plotRect.bottom + 8,
        ),
      );

      if (behavior.showValueLabels) {
        final valuePainter = buildTextPainter(
          valueFormatter(entryLayout.entry.sourceEntry),
          style.valueLabelTextStyle,
          textAlign: TextAlign.center,
          maxLines: 1,
        );
        valuePainter.paint(
          canvas,
          Offset(
            entryLayout.centerX - (valuePainter.width / 2),
            math.min(entryLayout.maxY, entryLayout.boxRect.top) -
                valuePainter.height -
                6,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BoxPlotChartPainter oldDelegate) {
    return oldDelegate.entries != entries ||
        oldDelegate.style != style ||
        oldDelegate.behavior != behavior ||
        oldDelegate.progress != progress ||
        oldDelegate.selectedItemIndex != selectedItemIndex;
  }
}
