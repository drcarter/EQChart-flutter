import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../common/chart_math.dart';
import '../../common/chart_types.dart';
import '../../theme/chart_defaults.dart';

class GaugeValue {
  const GaugeValue({
    required this.value,
    this.minValue = 0,
    this.maxValue = 100,
    this.label,
    this.payload,
  });

  final double value;
  final double minValue;
  final double maxValue;
  final String? label;
  final Object? payload;
}

class GaugeRange {
  const GaugeRange({
    required this.startValue,
    required this.endValue,
    required this.color,
    this.label,
  });

  final double startValue;
  final double endValue;
  final Color color;
  final String? label;
}

class EqGaugeChartStyle {
  const EqGaugeChartStyle({
    this.backgroundColor = Colors.transparent,
    this.padding = EqChartDefaults.chartPadding,
    this.trackColor = const Color(0xFFE7EDF4),
    this.progressColor = EqChartDefaults.accentBlue,
    this.progressThickness = 18,
    this.tickColor = const Color(0xFF8FA2B7),
    this.tickLength = 10,
    this.tickThickness = 2,
    this.indicatorColor = const Color(0xFF1F2A37),
    this.indicatorThickness = 3,
    this.indicatorCenterColor = const Color(0xFF1F2A37),
    this.indicatorCenterRadius = 5,
    this.valueTextStyle = const TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w800,
      color: EqChartDefaults.ink,
    ),
    this.labelTextStyle = const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: EqChartDefaults.softInk,
    ),
    this.minMaxTextStyle = const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: EqChartDefaults.softInk,
    ),
    this.emptyTextStyle = const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: EqChartDefaults.softInk,
    ),
  });

  final Color backgroundColor;
  final EdgeInsets padding;
  final Color trackColor;
  final Color progressColor;
  final double progressThickness;
  final Color tickColor;
  final double tickLength;
  final double tickThickness;
  final Color indicatorColor;
  final double indicatorThickness;
  final Color indicatorCenterColor;
  final double indicatorCenterRadius;
  final TextStyle valueTextStyle;
  final TextStyle labelTextStyle;
  final TextStyle minMaxTextStyle;
  final TextStyle emptyTextStyle;
}

class EqGaugeChartBehavior {
  const EqGaugeChartBehavior({
    this.startAngleDeg = 180,
    this.sweepAngleDeg = 180,
    this.showTicks = true,
    this.tickCount = 5,
    this.showMinMaxLabels = true,
    this.showValueText = true,
    this.showCenterLabel = true,
    this.animateOnValueChange = true,
    this.animationDuration = const Duration(milliseconds: 650),
    this.emptyText = 'No data',
    this.valueFormatter,
  });

  final double startAngleDeg;
  final double sweepAngleDeg;
  final bool showTicks;
  final int tickCount;
  final bool showMinMaxLabels;
  final bool showValueText;
  final bool showCenterLabel;
  final bool animateOnValueChange;
  final Duration animationDuration;
  final String emptyText;
  final EqValueFormatter? valueFormatter;
}

@visibleForTesting
class ResolvedGaugeValue {
  const ResolvedGaugeValue({
    required this.rawValue,
    required this.clampedValue,
    required this.minValue,
    required this.maxValue,
    required this.progress,
    required this.label,
    required this.payload,
  });

  final double rawValue;
  final double clampedValue;
  final double minValue;
  final double maxValue;
  final double progress;
  final String? label;
  final Object? payload;
}

@visibleForTesting
class ResolvedGaugeRange {
  const ResolvedGaugeRange({
    required this.startRatio,
    required this.endRatio,
    required this.color,
    required this.label,
  });

  final double startRatio;
  final double endRatio;
  final Color color;
  final String? label;
}

@visibleForTesting
class GaugeChartGeometry {
  const GaugeChartGeometry({
    required this.center,
    required this.radius,
    required this.arcRect,
    required this.valueTop,
    required this.labelTop,
    required this.minMaxTopOffset,
  });

  final Offset center;
  final double radius;
  final Rect arcRect;
  final double valueTop;
  final double labelTop;
  final double minMaxTopOffset;
}

@visibleForTesting
ResolvedGaugeValue? resolveGaugeValue(GaugeValue? value) {
  if (value == null ||
      !value.value.isFinite ||
      !value.minValue.isFinite ||
      !value.maxValue.isFinite ||
      value.maxValue <= value.minValue) {
    return null;
  }

  final clampedValue = value.value.clamp(value.minValue, value.maxValue);
  return ResolvedGaugeValue(
    rawValue: value.value,
    clampedValue: clampedValue,
    minValue: value.minValue,
    maxValue: value.maxValue,
    progress: normalizeGaugeValue(clampedValue, value.minValue, value.maxValue),
    label: value.label,
    payload: value.payload,
  );
}

@visibleForTesting
List<ResolvedGaugeRange> resolveGaugeRanges(
  List<GaugeRange> ranges,
  double minValue,
  double maxValue,
) {
  if (!minValue.isFinite || !maxValue.isFinite || maxValue <= minValue) {
    return const <ResolvedGaugeRange>[];
  }

  final resolved = <ResolvedGaugeRange>[];
  for (final range in ranges) {
    if (!range.startValue.isFinite || !range.endValue.isFinite) {
      continue;
    }
    final start = range.startValue.clamp(minValue, maxValue);
    final end = range.endValue.clamp(minValue, maxValue);
    if (end <= start) {
      continue;
    }
    resolved.add(
      ResolvedGaugeRange(
        startRatio: normalizeGaugeValue(start, minValue, maxValue),
        endRatio: normalizeGaugeValue(end, minValue, maxValue),
        color: range.color,
        label: range.label,
      ),
    );
  }
  return resolved;
}

@visibleForTesting
double normalizeGaugeValue(double value, double minValue, double maxValue) {
  if (!value.isFinite || !minValue.isFinite || !maxValue.isFinite) {
    return 0;
  }

  final span = maxValue - minValue;
  if (span <= 0) {
    return 0;
  }

  return ((value - minValue) / span).clamp(0.0, 1.0);
}

@visibleForTesting
double gaugeValueToAngle(
  double ratio,
  double startAngleDeg,
  double sweepAngleDeg,
) {
  return startAngleDeg + (sweepAngleDeg * ratio.clamp(0.0, 1.0));
}

@visibleForTesting
Offset gaugePointOnCircle(Offset center, double radius, double angleDeg) {
  final radians = angleDeg * math.pi / 180;
  return Offset(
    center.dx + math.cos(radians) * radius,
    center.dy + math.sin(radians) * radius,
  );
}

@visibleForTesting
GaugeChartGeometry computeGaugeChartGeometry(
  Size size,
  EqGaugeChartStyle style,
  EqGaugeChartBehavior behavior,
) {
  final bounds = style.padding.deflateRect(Offset.zero & size);
  final minMaxReserve = behavior.showMinMaxLabels
      ? (style.minMaxTextStyle.fontSize ?? 12) + 18
      : 10.0;
  final labelReserve = behavior.showCenterLabel
      ? (style.labelTextStyle.fontSize ?? 13) + 10
      : 0.0;
  final valueReserve = behavior.showValueText
      ? (style.valueTextStyle.fontSize ?? 24) + labelReserve + 20
      : labelReserve + 20;
  final center = Offset(bounds.center.dx, bounds.bottom - minMaxReserve);
  final radius = math.max(
    0.0,
    math.min(
      (bounds.width / 2) - (style.progressThickness / 2),
      center.dy - bounds.top - valueReserve - (style.progressThickness / 2),
    ),
  );

  return GaugeChartGeometry(
    center: center,
    radius: radius,
    arcRect: Rect.fromCircle(center: center, radius: radius),
    valueTop: center.dy - (radius * 0.42),
    labelTop:
        center.dy - (radius * 0.42) + (style.valueTextStyle.fontSize ?? 24),
    minMaxTopOffset: 6,
  );
}

class EqGaugeChart extends StatelessWidget {
  const EqGaugeChart({
    super.key,
    this.value,
    this.ranges = const <GaugeRange>[],
    this.style = const EqGaugeChartStyle(),
    this.behavior = const EqGaugeChartBehavior(),
  });

  final GaugeValue? value;
  final List<GaugeRange> ranges;
  final EqGaugeChartStyle style;
  final EqGaugeChartBehavior behavior;

  @override
  Widget build(BuildContext context) {
    final resolvedValue = resolveGaugeValue(value);
    final resolvedRanges = resolvedValue == null
        ? const <ResolvedGaugeRange>[]
        : resolveGaugeRanges(
            ranges, resolvedValue.minValue, resolvedValue.maxValue);
    final targetProgress = resolvedValue?.progress ?? 0.0;

    return RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: targetProgress),
        duration: behavior.animateOnValueChange
            ? behavior.animationDuration
            : Duration.zero,
        curve: Curves.easeOutCubic,
        builder: (context, renderedProgress, child) {
          return CustomPaint(
            painter: _EqGaugeChartPainter(
              style: style,
              behavior: behavior,
              resolvedValue: resolvedValue,
              resolvedRanges: resolvedRanges,
              renderedProgress: renderedProgress,
            ),
            child: child,
          );
        },
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _EqGaugeChartPainter extends CustomPainter {
  const _EqGaugeChartPainter({
    required this.style,
    required this.behavior,
    required this.resolvedValue,
    required this.resolvedRanges,
    required this.renderedProgress,
  });

  final EqGaugeChartStyle style;
  final EqGaugeChartBehavior behavior;
  final ResolvedGaugeValue? resolvedValue;
  final List<ResolvedGaugeRange> resolvedRanges;
  final double renderedProgress;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }

    if (style.backgroundColor.opacity > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = style.backgroundColor,
      );
    }

    final resolved = resolvedValue;
    if (resolved == null) {
      _drawCenteredText(
        canvas,
        size,
        behavior.emptyText,
        style.emptyTextStyle,
      );
      return;
    }

    final geometry = computeGaugeChartGeometry(size, style, behavior);
    if (geometry.radius <= 0) {
      return;
    }

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = style.progressThickness;

    arcPaint.color = style.trackColor;
    canvas.drawArc(
      geometry.arcRect,
      _degToRad(behavior.startAngleDeg),
      _degToRad(behavior.sweepAngleDeg),
      false,
      arcPaint,
    );

    for (final range in resolvedRanges) {
      final rangeStart = gaugeValueToAngle(
          range.startRatio, behavior.startAngleDeg, behavior.sweepAngleDeg);
      final rangeSweep =
          behavior.sweepAngleDeg * (range.endRatio - range.startRatio);
      if (rangeSweep <= 0) {
        continue;
      }
      arcPaint.color = range.color;
      canvas.drawArc(
        geometry.arcRect,
        _degToRad(rangeStart),
        _degToRad(rangeSweep),
        false,
        arcPaint,
      );
    }

    if (renderedProgress > 0) {
      arcPaint.color = style.progressColor;
      canvas.drawArc(
        geometry.arcRect,
        _degToRad(behavior.startAngleDeg),
        _degToRad(behavior.sweepAngleDeg * renderedProgress.clamp(0.0, 1.0)),
        false,
        arcPaint,
      );
    }

    if (behavior.showTicks) {
      final tickPaint = Paint()
        ..color = style.tickColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = style.tickThickness;
      final tickCount = math.max(1, behavior.tickCount);
      final outerRadius = geometry.radius + (style.progressThickness * 0.15);
      final innerRadius = outerRadius - style.tickLength;
      for (var index = 0; index <= tickCount; index++) {
        final ratio = index / tickCount;
        final angle = gaugeValueToAngle(
            ratio, behavior.startAngleDeg, behavior.sweepAngleDeg);
        final start = gaugePointOnCircle(geometry.center, outerRadius, angle);
        final end = gaugePointOnCircle(geometry.center, innerRadius, angle);
        canvas.drawLine(start, end, tickPaint);
      }
    }

    final indicatorAngle = gaugeValueToAngle(
        renderedProgress, behavior.startAngleDeg, behavior.sweepAngleDeg);
    final indicatorEnd = gaugePointOnCircle(
      geometry.center,
      math.max(0, geometry.radius - (style.progressThickness * 0.75)),
      indicatorAngle,
    );
    final indicatorPaint = Paint()
      ..color = style.indicatorColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = style.indicatorThickness;
    canvas.drawLine(geometry.center, indicatorEnd, indicatorPaint);
    canvas.drawCircle(
      geometry.center,
      style.indicatorCenterRadius,
      Paint()..color = style.indicatorCenterColor,
    );

    final formatter = fallbackValueFormatter(behavior.valueFormatter);
    if (behavior.showValueText) {
      _drawTopCenteredText(
        canvas,
        Offset(geometry.center.dx, geometry.valueTop),
        formatter(resolved.clampedValue),
        style.valueTextStyle,
      );
    }

    if (behavior.showCenterLabel &&
        resolved.label != null &&
        resolved.label!.trim().isNotEmpty) {
      _drawTopCenteredText(
        canvas,
        Offset(geometry.center.dx, geometry.labelTop),
        resolved.label!.trim(),
        style.labelTextStyle,
      );
    }

    if (behavior.showMinMaxLabels) {
      final radius = geometry.radius + (style.progressThickness * 0.7);
      final startPoint =
          gaugePointOnCircle(geometry.center, radius, behavior.startAngleDeg);
      final endPoint = gaugePointOnCircle(
        geometry.center,
        radius,
        behavior.startAngleDeg + behavior.sweepAngleDeg,
      );
      _drawTopCenteredText(
        canvas,
        Offset(startPoint.dx, startPoint.dy + geometry.minMaxTopOffset),
        formatter(resolved.minValue),
        style.minMaxTextStyle,
      );
      _drawTopCenteredText(
        canvas,
        Offset(endPoint.dx, endPoint.dy + geometry.minMaxTopOffset),
        formatter(resolved.maxValue),
        style.minMaxTextStyle,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EqGaugeChartPainter oldDelegate) {
    return oldDelegate.style != style ||
        oldDelegate.behavior != behavior ||
        oldDelegate.resolvedValue != resolvedValue ||
        oldDelegate.resolvedRanges != resolvedRanges ||
        oldDelegate.renderedProgress != renderedProgress;
  }

  void _drawCenteredText(
    Canvas canvas,
    Size size,
    String text,
    TextStyle style,
  ) {
    final painter = buildTextPainter(
      text,
      style,
      textAlign: TextAlign.center,
    );
    painter.paint(
      canvas,
      Offset(
        (size.width - painter.width) / 2,
        (size.height - painter.height) / 2,
      ),
    );
  }

  void _drawTopCenteredText(
    Canvas canvas,
    Offset position,
    String text,
    TextStyle textStyle,
  ) {
    final painter = buildTextPainter(
      text,
      textStyle,
      textAlign: TextAlign.center,
    );
    painter.paint(
      canvas,
      Offset(position.dx - (painter.width / 2), position.dy),
    );
  }

  double _degToRad(double degrees) => degrees * math.pi / 180;
}
