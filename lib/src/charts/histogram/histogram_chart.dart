import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../common/chart_math.dart';
import '../../common/chart_types.dart';
import '../../theme/chart_defaults.dart';

class HistogramBin {
  const HistogramBin({
    required this.start,
    required this.end,
    required this.value,
    this.label,
    this.color,
    this.payload,
  });

  final double start;
  final double end;
  final double value;
  final String? label;
  final Color? color;
  final Object? payload;
}

class EqHistogramChartStyle {
  const EqHistogramChartStyle({
    this.backgroundColor = Colors.transparent,
    this.padding = EqChartDefaults.chartPadding,
    this.gridColor = EqChartDefaults.grid,
    this.axisColor = EqChartDefaults.axis,
    this.axisLabelTextStyle = EqChartDefaults.axisTextStyle,
    this.valueLabelTextStyle = EqChartDefaults.labelTextStyle,
    this.barColor = EqChartDefaults.accentBlue,
    this.categorySpacing = 6,
    this.barRadius = 3,
    this.selectionPadding = 1.5,
  });

  final Color backgroundColor;
  final EdgeInsets padding;
  final Color gridColor;
  final Color axisColor;
  final TextStyle axisLabelTextStyle;
  final TextStyle valueLabelTextStyle;
  final Color barColor;
  final double categorySpacing;
  final double barRadius;
  final double selectionPadding;
}

typedef EqHistogramBinFormatter = String Function(HistogramBin bin);

class EqHistogramChartBehavior {
  const EqHistogramChartBehavior({
    this.showGrid = true,
    this.showAxes = true,
    this.showBarLabels = true,
    this.animateOnDataChange = true,
    this.selectionEnabled = true,
    this.animationDuration = const Duration(milliseconds: 680),
    this.animationCurve = Curves.easeOutCubic,
    this.animateFromBaseline = true,
    this.emptyText = 'No data',
    this.yTickCount = 6,
    this.yLabelFormatter,
    this.valueLabelFormatter,
    this.binLabelFormatter,
  });

  final bool showGrid;
  final bool showAxes;
  final bool showBarLabels;
  final bool animateOnDataChange;
  final bool selectionEnabled;
  final Duration animationDuration;
  final Curve animationCurve;
  final bool animateFromBaseline;
  final String emptyText;
  final int yTickCount;
  final EqValueFormatter? yLabelFormatter;
  final EqValueFormatter? valueLabelFormatter;
  final EqHistogramBinFormatter? binLabelFormatter;
}

@visibleForTesting
class ResolvedHistogramBin {
  const ResolvedHistogramBin({
    required this.index,
    required this.start,
    required this.end,
    required this.value,
    required this.label,
    required this.color,
    required this.sourceBin,
  });

  final int index;
  final double start;
  final double end;
  final double value;
  final String label;
  final Color color;
  final HistogramBin sourceBin;
}

@visibleForTesting
class HistogramBarLayout {
  const HistogramBarLayout({
    required this.rect,
    required this.bin,
  });

  final Rect rect;
  final ResolvedHistogramBin bin;
}

@visibleForTesting
class HistogramChartLayout {
  const HistogramChartLayout({
    required this.plotRect,
    required this.minBinStart,
    required this.maxBinEnd,
    required this.minValue,
    required this.maxValue,
    required this.baselineValue,
    required this.yTicks,
    required this.bars,
  });

  final Rect plotRect;
  final double minBinStart;
  final double maxBinEnd;
  final double minValue;
  final double maxValue;
  final double baselineValue;
  final List<double> yTicks;
  final List<HistogramBarLayout> bars;
}

String formatHistogramBoundary(double value) {
  if ((value - value.roundToDouble()).abs() <= 1e-9) {
    return value.round().toString();
  }
  return value.toString().replaceFirst(RegExp(r'\.?0+$'), '');
}

List<ResolvedHistogramBin> _resolveHistogramBins(
  List<HistogramBin> bins,
  EqHistogramChartStyle style,
  EqHistogramChartBehavior behavior,
) {
  final labelFormatter = behavior.binLabelFormatter ??
      (HistogramBin bin) => bin.label?.trim().isNotEmpty == true
          ? bin.label!.trim()
          : '${formatHistogramBoundary(bin.start)}-${formatHistogramBoundary(bin.end)}';

  final resolved = <ResolvedHistogramBin>[];
  for (var index = 0; index < bins.length; index++) {
    final bin = bins[index];
    if (!bin.start.isFinite ||
        !bin.end.isFinite ||
        !bin.value.isFinite ||
        bin.end <= bin.start) {
      continue;
    }
    if (bin.label != null && bin.label!.trim().isEmpty) {
      continue;
    }
    resolved.add(
      ResolvedHistogramBin(
        index: index,
        start: bin.start,
        end: bin.end,
        value: bin.value,
        label: labelFormatter(bin),
        color: bin.color ?? style.barColor,
        sourceBin: bin,
      ),
    );
  }
  return resolved;
}

double _histogramValueToY(
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

double _histogramValueToX(
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

double _resolveHistogramBaseline(double minValue, double maxValue) {
  if (minValue <= 0 && maxValue >= 0) {
    return 0;
  }
  return minValue;
}

double _animatedHistogramValue(
  double value,
  double baselineValue,
  EqHistogramChartBehavior behavior,
  double progress,
) {
  if (!behavior.animateFromBaseline) {
    return value;
  }
  return baselineValue + ((value - baselineValue) * progress);
}

@visibleForTesting
HistogramChartLayout computeHistogramChartLayout(
  Size size,
  List<HistogramBin> bins,
  EqHistogramChartStyle style,
  EqHistogramChartBehavior behavior, {
  double progress = 1,
}) {
  final resolvedBins = _resolveHistogramBins(bins, style, behavior);
  final yFormatter = fallbackValueFormatter(behavior.yLabelFormatter);
  final axisLabelHeight = measureText('100', style.axisLabelTextStyle).height;
  final valueLabelHeight = measureText('100', style.valueLabelTextStyle).height;

  double minBinStart = 0;
  double maxBinEnd = 1;
  double minValue = -1;
  double maxValue = 1;

  if (resolvedBins.isNotEmpty) {
    minBinStart = resolvedBins.first.start;
    maxBinEnd = resolvedBins.first.end;
    minValue = math.min(resolvedBins.first.value, 0);
    maxValue = math.max(resolvedBins.first.value, 0);

    for (final bin in resolvedBins.skip(1)) {
      minBinStart = math.min(minBinStart, bin.start);
      maxBinEnd = math.max(maxBinEnd, bin.end);
      minValue = math.min(minValue, bin.value);
      maxValue = math.max(maxValue, bin.value);
    }

    minValue = math.min(minValue, 0);
    maxValue = math.max(maxValue, 0);
    if ((maxValue - minValue).abs() <= 1e-9) {
      minValue -= 1;
      maxValue += 1;
    }
  }

  final baselineValue = _resolveHistogramBaseline(minValue, maxValue);
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
  final bottomReserve = style.padding.bottom + axisLabelHeight + 20;
  final topReserve =
      style.padding.top + (behavior.showBarLabels ? valueLabelHeight + 12 : 10);
  final plotRect = Rect.fromLTWH(
    leftReserve,
    topReserve,
    math.max(0, size.width - leftReserve - style.padding.right),
    math.max(0, size.height - topReserve - bottomReserve),
  );

  if (resolvedBins.isEmpty || plotRect.width <= 0 || plotRect.height <= 0) {
    return HistogramChartLayout(
      plotRect: plotRect,
      minBinStart: minBinStart,
      maxBinEnd: maxBinEnd,
      minValue: minValue,
      maxValue: maxValue,
      baselineValue: baselineValue,
      yTicks: yTicks,
      bars: const <HistogramBarLayout>[],
    );
  }

  final clampedProgress = progress.clamp(0.0, 1.0);
  final bars = <HistogramBarLayout>[];
  for (final bin in resolvedBins) {
    final rawLeft =
        _histogramValueToX(plotRect, bin.start, minBinStart, maxBinEnd);
    final rawRight =
        _histogramValueToX(plotRect, bin.end, minBinStart, maxBinEnd);
    final maxInset = ((rawRight - rawLeft) / 2) - 0.5;
    final inset = math.max(0, math.min(style.categorySpacing / 2, maxInset));
    final left = rawLeft + inset;
    final right = math.max(left + 1, rawRight - inset);
    final startY =
        _histogramValueToY(plotRect, baselineValue, minValue, maxValue);
    final endY = _histogramValueToY(
      plotRect,
      _animatedHistogramValue(
          bin.value, baselineValue, behavior, clampedProgress),
      minValue,
      maxValue,
    );

    bars.add(
      HistogramBarLayout(
        rect: Rect.fromLTRB(
          left,
          math.min(startY, endY),
          right,
          math.max(startY, endY),
        ),
        bin: bin,
      ),
    );
  }

  return HistogramChartLayout(
    plotRect: plotRect,
    minBinStart: minBinStart,
    maxBinEnd: maxBinEnd,
    minValue: minValue,
    maxValue: maxValue,
    baselineValue: baselineValue,
    yTicks: yTicks,
    bars: bars,
  );
}

class EqHistogramChart extends StatefulWidget {
  const EqHistogramChart({
    super.key,
    required this.bins,
    this.style = const EqHistogramChartStyle(),
    this.behavior = const EqHistogramChartBehavior(),
    this.onItemTap,
  });

  final List<HistogramBin> bins;
  final EqHistogramChartStyle style;
  final EqHistogramChartBehavior behavior;
  final EqSelectionChanged<HistogramBin>? onItemTap;

  @override
  State<EqHistogramChart> createState() => _EqHistogramChartState();
}

class _EqHistogramChartState extends State<EqHistogramChart>
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
  void didUpdateWidget(covariant EqHistogramChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.behavior.animationDuration !=
        widget.behavior.animationDuration) {
      _controller.duration = widget.behavior.animationDuration;
    }
    if (widget.behavior.animateOnDataChange && oldWidget.bins != widget.bins) {
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
    final layout = computeHistogramChartLayout(
      size,
      widget.bins,
      widget.style,
      widget.behavior,
    );
    final hit = layout.bars.cast<HistogramBarLayout?>().lastWhere(
          (bar) => bar?.rect.contains(details.localPosition) ?? false,
          orElse: () => null,
        );
    if (hit == null) {
      return;
    }

    if (widget.behavior.selectionEnabled) {
      setState(() {
        _selectedItemIndex = hit.bin.index;
      });
    }

    widget.onItemTap?.call(
      EqChartSelection<HistogramBin>(
        seriesIndex: 0,
        itemIndex: hit.bin.index,
        datum: hit.bin.sourceBin,
        localPosition: details.localPosition,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasInteractiveHandler =
        widget.behavior.selectionEnabled || widget.onItemTap != null;
    final yFormatter = fallbackValueFormatter(widget.behavior.yLabelFormatter);
    final valueFormatter =
        fallbackValueFormatter(widget.behavior.valueLabelFormatter);
    final binFormatter = widget.behavior.binLabelFormatter ??
        (HistogramBin bin) => bin.label?.trim().isNotEmpty == true
            ? bin.label!.trim()
            : '${formatHistogramBoundary(bin.start)}-${formatHistogramBoundary(bin.end)}';

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
                    painter: _HistogramChartPainter(
                      bins: widget.bins,
                      style: widget.style,
                      behavior: widget.behavior,
                      progress: progress,
                      selectedItemIndex: _selectedItemIndex,
                      yFormatter: yFormatter,
                      valueFormatter: valueFormatter,
                      binFormatter: binFormatter,
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

class _HistogramChartPainter extends CustomPainter {
  const _HistogramChartPainter({
    required this.bins,
    required this.style,
    required this.behavior,
    required this.progress,
    required this.selectedItemIndex,
    required this.yFormatter,
    required this.valueFormatter,
    required this.binFormatter,
  });

  final List<HistogramBin> bins;
  final EqHistogramChartStyle style;
  final EqHistogramChartBehavior behavior;
  final double progress;
  final int? selectedItemIndex;
  final EqValueFormatter yFormatter;
  final EqValueFormatter valueFormatter;
  final EqHistogramBinFormatter binFormatter;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = computeHistogramChartLayout(
      size,
      bins,
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
    final barPaint = Paint()..style = PaintingStyle.fill;
    final selectionPaint = Paint()
      ..color = style.axisColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

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
      for (final tick in layout.yTicks) {
        final y = _histogramValueToY(
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
      final baselineY = _histogramValueToY(
        layout.plotRect,
        layout.baselineValue,
        layout.minValue,
        layout.maxValue,
      );
      canvas.drawLine(
        Offset(layout.plotRect.left, layout.plotRect.top),
        Offset(layout.plotRect.left, layout.plotRect.bottom),
        axisPaint,
      );
      canvas.drawLine(
        Offset(layout.plotRect.left, baselineY),
        Offset(layout.plotRect.right, baselineY),
        axisPaint,
      );
    }

    for (final bar in layout.bars) {
      barPaint.color = bar.bin.color;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          bar.rect,
          Radius.circular(style.barRadius),
        ),
        barPaint,
      );

      if (selectedItemIndex == bar.bin.index) {
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
          valueFormatter(bar.bin.value),
          style.valueLabelTextStyle,
          textAlign: TextAlign.center,
        );
        final labelTop = bar.bin.value >= layout.baselineValue
            ? bar.rect.top - labelPainter.height - 6
            : bar.rect.bottom + 4;
        labelPainter.paint(
          canvas,
          Offset(
            bar.rect.center.dx - (labelPainter.width / 2),
            labelTop,
          ),
        );
      }

      final binPainter = buildTextPainter(
        binFormatter(bar.bin.sourceBin),
        style.axisLabelTextStyle,
        textAlign: TextAlign.center,
      );
      binPainter.paint(
        canvas,
        Offset(
          bar.rect.center.dx - (binPainter.width / 2),
          layout.plotRect.bottom + 8,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HistogramChartPainter oldDelegate) {
    return oldDelegate.bins != bins ||
        oldDelegate.style != style ||
        oldDelegate.behavior != behavior ||
        oldDelegate.progress != progress ||
        oldDelegate.selectedItemIndex != selectedItemIndex;
  }
}
