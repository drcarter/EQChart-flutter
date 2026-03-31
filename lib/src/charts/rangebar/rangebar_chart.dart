import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../common/chart_math.dart';
import '../../common/chart_types.dart';
import '../../theme/chart_defaults.dart';

class RangeBarEntry {
  const RangeBarEntry({
    required this.label,
    required this.start,
    required this.end,
    this.color,
    this.title,
    this.payload,
  });

  final String label;
  final double start;
  final double end;
  final Color? color;
  final String? title;
  final Object? payload;
}

class EqRangeBarChartStyle {
  const EqRangeBarChartStyle({
    this.backgroundColor = Colors.transparent,
    this.padding = EqChartDefaults.chartPadding,
    this.gridColor = EqChartDefaults.grid,
    this.axisColor = EqChartDefaults.axis,
    this.axisLabelTextStyle = EqChartDefaults.axisTextStyle,
    this.barLabelTextStyle = EqChartDefaults.labelTextStyle,
    this.barColor = EqChartDefaults.accentBlue,
    this.selectedBarStrokeColor = EqChartDefaults.ink,
    this.rowSpacing = 12,
    this.barHeightFactor = 0.58,
    this.barRadius = 4,
    this.selectionPadding = 1.5,
    this.minBarWidth = 6,
  });

  final Color backgroundColor;
  final EdgeInsets padding;
  final Color gridColor;
  final Color axisColor;
  final TextStyle axisLabelTextStyle;
  final TextStyle barLabelTextStyle;
  final Color barColor;
  final Color selectedBarStrokeColor;
  final double rowSpacing;
  final double barHeightFactor;
  final double barRadius;
  final double selectionPadding;
  final double minBarWidth;
}

typedef EqRangeBarLabelFormatter = String Function(ResolvedRangeBarEntry entry);

class EqRangeBarChartBehavior {
  const EqRangeBarChartBehavior({
    this.showGrid = true,
    this.showAxes = true,
    this.showBarLabels = true,
    this.animateOnDataChange = true,
    this.selectionEnabled = true,
    this.animationDuration = const Duration(milliseconds: 680),
    this.animationCurve = Curves.easeOutCubic,
    this.animateFromStart = true,
    this.emptyText = 'No data',
    this.xTickCount = 6,
    this.xLabelFormatter,
    this.rowLabelFormatter,
    this.barLabelFormatter,
  });

  final bool showGrid;
  final bool showAxes;
  final bool showBarLabels;
  final bool animateOnDataChange;
  final bool selectionEnabled;
  final Duration animationDuration;
  final Curve animationCurve;
  final bool animateFromStart;
  final String emptyText;
  final int xTickCount;
  final EqValueFormatter? xLabelFormatter;
  final EqCategoryFormatter? rowLabelFormatter;
  final EqRangeBarLabelFormatter? barLabelFormatter;
}

@visibleForTesting
class ResolvedRangeBarEntry {
  const ResolvedRangeBarEntry({
    required this.index,
    required this.label,
    required this.title,
    required this.rawStartValue,
    required this.rawEndValue,
    required this.startValue,
    required this.endValue,
    required this.duration,
    required this.color,
    required this.sourceEntry,
  });

  final int index;
  final String label;
  final String? title;
  final double rawStartValue;
  final double rawEndValue;
  final double startValue;
  final double endValue;
  final double duration;
  final Color color;
  final RangeBarEntry sourceEntry;
}

@visibleForTesting
class RangeBarTickLayout {
  const RangeBarTickLayout({
    required this.value,
    required this.x,
    required this.label,
  });

  final double value;
  final double x;
  final String label;
}

@visibleForTesting
class RangeBarRowLabelLayout {
  const RangeBarRowLabelLayout({
    required this.index,
    required this.label,
    required this.centerY,
  });

  final int index;
  final String label;
  final double centerY;
}

@visibleForTesting
class RangeBarRectLayout {
  const RangeBarRectLayout({
    required this.rect,
    required this.entry,
    required this.labelText,
  });

  final Rect rect;
  final ResolvedRangeBarEntry entry;
  final String labelText;
}

@visibleForTesting
class RangeBarChartLayout {
  const RangeBarChartLayout({
    required this.plotRect,
    required this.minValue,
    required this.maxValue,
    required this.ticks,
    required this.rowLabels,
    required this.bars,
    required this.rowHeight,
  });

  final Rect plotRect;
  final double minValue;
  final double maxValue;
  final List<RangeBarTickLayout> ticks;
  final List<RangeBarRowLabelLayout> rowLabels;
  final List<RangeBarRectLayout> bars;
  final double rowHeight;
}

String formatRangeBarAxisValue(double value) {
  if (!value.isFinite) {
    return '0';
  }

  final absolute = value.abs();
  if (absolute >= 1000000) {
    return '${_trimRangeBarAxisValue(value / 1000000)}M';
  }
  if (absolute >= 1000) {
    return '${_trimRangeBarAxisValue(value / 1000)}K';
  }
  if ((value - value.roundToDouble()).abs() <= 1e-9) {
    return value.round().toString();
  }
  return _trimRangeBarAxisValue(value);
}

String _trimRangeBarAxisValue(double value) {
  final rounded = (value * 10).roundToDouble() / 10;
  if ((rounded - rounded.roundToDouble()).abs() <= 1e-9) {
    return rounded.round().toString();
  }
  return rounded.toString().replaceFirst(RegExp(r'\.?0+$'), '');
}

List<ResolvedRangeBarEntry> _resolveRangeBarEntries(
  List<RangeBarEntry> entries,
  EqRangeBarChartStyle style,
) {
  final resolved = <ResolvedRangeBarEntry>[];
  for (var index = 0; index < entries.length; index++) {
    final entry = entries[index];
    if (entry.label.trim().isEmpty ||
        !entry.start.isFinite ||
        !entry.end.isFinite) {
      continue;
    }

    final startValue = math.min(entry.start, entry.end);
    final endValue = math.max(entry.start, entry.end);
    resolved.add(
      ResolvedRangeBarEntry(
        index: index,
        label: entry.label,
        title:
            entry.title?.trim().isNotEmpty == true ? entry.title!.trim() : null,
        rawStartValue: entry.start,
        rawEndValue: entry.end,
        startValue: startValue,
        endValue: endValue,
        duration: endValue - startValue,
        color: entry.color ?? style.barColor,
        sourceEntry: entry,
      ),
    );
  }
  return resolved;
}

double _rangeBarValueToX(
  Rect plotRect,
  double value,
  double minValue,
  double maxValue,
) {
  return mapToRange(
    value: value,
    domainMin: minValue,
    domainMax: maxValue,
    rangeMin: plotRect.left,
    rangeMax: plotRect.right,
  );
}

double _animatedRangeBarEndValue(
  ResolvedRangeBarEntry entry,
  EqRangeBarChartBehavior behavior,
  double progress,
) {
  if (!behavior.animateFromStart) {
    return entry.endValue;
  }
  return entry.startValue + ((entry.endValue - entry.startValue) * progress);
}

String _defaultRangeBarLabelFormatter(ResolvedRangeBarEntry entry) {
  if (entry.title != null) {
    return entry.title!;
  }
  return '${entry.label}: ${formatRangeBarAxisValue(entry.startValue)}-${formatRangeBarAxisValue(entry.endValue)}';
}

@visibleForTesting
RangeBarChartLayout computeRangeBarChartLayout(
  Size size,
  List<RangeBarEntry> entries,
  EqRangeBarChartStyle style,
  EqRangeBarChartBehavior behavior, {
  double progress = 1,
}) {
  final resolvedEntries = _resolveRangeBarEntries(entries, style);
  final xFormatter = behavior.xLabelFormatter ?? formatRangeBarAxisValue;
  final rowFormatter = fallbackCategoryFormatter(behavior.rowLabelFormatter);
  final barFormatter =
      behavior.barLabelFormatter ?? _defaultRangeBarLabelFormatter;

  var minValue = -1.0;
  var maxValue = 1.0;
  if (resolvedEntries.isNotEmpty) {
    minValue = resolvedEntries.first.startValue;
    maxValue = resolvedEntries.first.endValue;
    for (final entry in resolvedEntries.skip(1)) {
      minValue = math.min(minValue, entry.startValue);
      maxValue = math.max(maxValue, entry.endValue);
    }
    if ((maxValue - minValue).abs() <= 1e-9) {
      minValue -= 1;
      maxValue += 1;
    }
  }

  final tickValues = buildLinearTicks(
    minValue,
    maxValue,
    count: behavior.xTickCount,
  );
  final tickLabels =
      tickValues.map((value) => xFormatter(value)).toList(growable: false);
  final maxTickHeight = tickLabels.fold<double>(
    0,
    (current, label) => math.max(
      current,
      measureText(label, style.axisLabelTextStyle).height,
    ),
  );
  final maxRowLabelWidth = resolvedEntries.fold<double>(
    0,
    (current, entry) => math.max(
      current,
      measureText(rowFormatter(entry.label), style.axisLabelTextStyle).width,
    ),
  );
  final maxBarLabelHeight = resolvedEntries.fold<double>(
    0,
    (current, entry) => math.max(
      current,
      measureText(barFormatter(entry), style.barLabelTextStyle).height,
    ),
  );

  final leftReserve = style.padding.left + maxRowLabelWidth + 16;
  final topReserve = style.padding.top +
      (behavior.showBarLabels ? maxBarLabelHeight + 12 : 10);
  final bottomReserve = style.padding.bottom + maxTickHeight + 18;
  final plotRect = Rect.fromLTWH(
    leftReserve,
    topReserve,
    math.max(0, size.width - leftReserve - style.padding.right),
    math.max(0, size.height - topReserve - bottomReserve),
  );

  if (resolvedEntries.isEmpty || plotRect.width <= 0 || plotRect.height <= 0) {
    return RangeBarChartLayout(
      plotRect: plotRect,
      minValue: minValue,
      maxValue: maxValue,
      ticks: tickValues
          .map(
            (value) => RangeBarTickLayout(
              value: value,
              x: plotRect.left,
              label: xFormatter(value),
            ),
          )
          .toList(growable: false),
      rowLabels: const <RangeBarRowLabelLayout>[],
      bars: const <RangeBarRectLayout>[],
      rowHeight: 0,
    );
  }

  final clampedProgress = progress.clamp(0.0, 1.0);
  final safeRowSpacing = math.max(0, style.rowSpacing);
  final availableHeight = math.max(
    0,
    plotRect.height -
        (safeRowSpacing * math.max(0, resolvedEntries.length - 1)),
  );
  final rowHeight = availableHeight / resolvedEntries.length;
  final barHeight = rowHeight * style.barHeightFactor.clamp(0.2, 1.0);

  final bars = <RangeBarRectLayout>[];
  final rowLabels = <RangeBarRowLabelLayout>[];
  for (var index = 0; index < resolvedEntries.length; index++) {
    final entry = resolvedEntries[index];
    final rowTop = plotRect.top + (index * (rowHeight + safeRowSpacing));
    final top = rowTop + ((rowHeight - barHeight) / 2);
    final bottom = top + barHeight;
    final left =
        _rangeBarValueToX(plotRect, entry.startValue, minValue, maxValue);
    final rawRight = _rangeBarValueToX(
      plotRect,
      _animatedRangeBarEndValue(entry, behavior, clampedProgress),
      minValue,
      maxValue,
    );
    var right = math.max(left, rawRight);
    if (right - left < style.minBarWidth) {
      right = math.min(plotRect.right, left + style.minBarWidth);
    }
    final rect = Rect.fromLTRB(left, top, right, bottom);
    bars.add(
      RangeBarRectLayout(
        rect: rect,
        entry: entry,
        labelText: barFormatter(entry),
      ),
    );
    rowLabels.add(
      RangeBarRowLabelLayout(
        index: index,
        label: rowFormatter(entry.label),
        centerY: rect.center.dy,
      ),
    );
  }

  final ticks = tickValues
      .map(
        (value) => RangeBarTickLayout(
          value: value,
          x: _rangeBarValueToX(plotRect, value, minValue, maxValue),
          label: xFormatter(value),
        ),
      )
      .toList(growable: false);

  return RangeBarChartLayout(
    plotRect: plotRect,
    minValue: minValue,
    maxValue: maxValue,
    ticks: ticks,
    rowLabels: rowLabels,
    bars: bars,
    rowHeight: rowHeight,
  );
}

class EqRangeBarChart extends StatefulWidget {
  const EqRangeBarChart({
    super.key,
    required this.entries,
    this.style = const EqRangeBarChartStyle(),
    this.behavior = const EqRangeBarChartBehavior(),
    this.onItemTap,
  });

  final List<RangeBarEntry> entries;
  final EqRangeBarChartStyle style;
  final EqRangeBarChartBehavior behavior;
  final EqSelectionChanged<RangeBarEntry>? onItemTap;

  @override
  State<EqRangeBarChart> createState() => _EqRangeBarChartState();
}

class _EqRangeBarChartState extends State<EqRangeBarChart>
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
  void didUpdateWidget(covariant EqRangeBarChart oldWidget) {
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
    final layout = computeRangeBarChartLayout(
      size,
      widget.entries,
      widget.style,
      widget.behavior,
    );
    final hit = layout.bars.cast<RangeBarRectLayout?>().lastWhere(
          (bar) => bar?.rect.contains(details.localPosition) ?? false,
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
      EqChartSelection<RangeBarEntry>(
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
                    painter: _RangeBarChartPainter(
                      entries: widget.entries,
                      style: widget.style,
                      behavior: widget.behavior,
                      progress: progress,
                      selectedItemIndex: _selectedItemIndex,
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

class _RangeBarChartPainter extends CustomPainter {
  const _RangeBarChartPainter({
    required this.entries,
    required this.style,
    required this.behavior,
    required this.progress,
    required this.selectedItemIndex,
  });

  final List<RangeBarEntry> entries;
  final EqRangeBarChartStyle style;
  final EqRangeBarChartBehavior behavior;
  final double progress;
  final int? selectedItemIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = computeRangeBarChartLayout(
      size,
      entries,
      style,
      behavior,
      progress: progress,
    );
    final axisPaint = Paint()
      ..color = style.axisColor
      ..strokeWidth = 1.2;
    final gridPaint = Paint()
      ..color = style.gridColor
      ..strokeWidth = 1;
    final barPaint = Paint()..style = PaintingStyle.fill;
    final selectionPaint = Paint()
      ..color = style.selectedBarStrokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    if (layout.bars.isEmpty) {
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
      for (final tick in layout.ticks) {
        canvas.drawLine(
          Offset(tick.x, layout.plotRect.top),
          Offset(tick.x, layout.plotRect.bottom),
          gridPaint,
        );
      }
    }

    if (behavior.showAxes) {
      canvas.drawLine(
        Offset(layout.plotRect.left, layout.plotRect.bottom),
        Offset(layout.plotRect.right, layout.plotRect.bottom),
        axisPaint,
      );
    }

    for (final bar in layout.bars) {
      barPaint.color = bar.entry.color;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          bar.rect,
          Radius.circular(style.barRadius),
        ),
        barPaint,
      );

      if (selectedItemIndex == bar.entry.index) {
        final selectionRect = Rect.fromLTRB(
          bar.rect.left - style.selectionPadding,
          bar.rect.top - style.selectionPadding,
          bar.rect.right + style.selectionPadding,
          bar.rect.bottom + style.selectionPadding,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            selectionRect,
            Radius.circular(style.barRadius),
          ),
          selectionPaint,
        );
      }

      if (behavior.showBarLabels) {
        final labelPainter = buildTextPainter(
          bar.labelText,
          style.barLabelTextStyle,
          textAlign: TextAlign.center,
        );
        final dx = math.max(
          layout.plotRect.left,
          math.min(
            bar.rect.center.dx - (labelPainter.width / 2),
            layout.plotRect.right - labelPainter.width,
          ),
        );
        labelPainter.paint(
          canvas,
          Offset(dx, bar.rect.top - labelPainter.height - 4),
        );
      }
    }

    for (final rowLabel in layout.rowLabels) {
      final painter = buildTextPainter(
        rowLabel.label,
        style.axisLabelTextStyle,
        textAlign: TextAlign.right,
      );
      painter.paint(
        canvas,
        Offset(
          layout.plotRect.left - painter.width - 10,
          rowLabel.centerY - (painter.height / 2),
        ),
      );
    }

    for (final tick in layout.ticks) {
      final painter = buildTextPainter(
        tick.label,
        style.axisLabelTextStyle,
        textAlign: TextAlign.center,
      );
      painter.paint(
        canvas,
        Offset(
          math.max(
            0,
            math.min(tick.x - (painter.width / 2), size.width - painter.width),
          ),
          layout.plotRect.bottom + 8,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RangeBarChartPainter oldDelegate) {
    return oldDelegate.entries != entries ||
        oldDelegate.style != style ||
        oldDelegate.behavior != behavior ||
        oldDelegate.progress != progress ||
        oldDelegate.selectedItemIndex != selectedItemIndex;
  }
}
