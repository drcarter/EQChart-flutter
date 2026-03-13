import 'package:flutter/material.dart';

import 'chart_types.dart';

String defaultNumericFormatter(double value) {
  if (value % 1 == 0) {
    return value.toInt().toString();
  }

  return value.toStringAsFixed(1);
}

({double min, double max}) includeZeroInRange(Iterable<double> values) {
  final list = values.toList(growable: false);
  if (list.isEmpty) {
    return (min: -1, max: 1);
  }

  var min = list.first;
  var max = list.first;
  for (final value in list.skip(1)) {
    if (value < min) {
      min = value;
    }
    if (value > max) {
      max = value;
    }
  }

  min = min > 0 ? 0 : min;
  max = max < 0 ? 0 : max;

  if ((max - min).abs() < 1e-9) {
    return (min: min - 1, max: max + 1);
  }

  return (min: min, max: max);
}

List<double> buildLinearTicks(
  double min,
  double max, {
  int count = 5,
}) {
  final safeCount = count < 2 ? 2 : count;
  if ((max - min).abs() < 1e-9) {
    return <double>[min, max];
  }

  return List<double>.generate(
    safeCount,
    (index) => min + ((max - min) * index) / (safeCount - 1),
    growable: false,
  );
}

double mapToRange({
  required double value,
  required double domainMin,
  required double domainMax,
  required double rangeMin,
  required double rangeMax,
}) {
  if ((domainMax - domainMin).abs() < 1e-9) {
    return (rangeMin + rangeMax) / 2;
  }

  final ratio = (value - domainMin) / (domainMax - domainMin);
  return rangeMin + (rangeMax - rangeMin) * ratio;
}

TextPainter buildTextPainter(
  String text,
  TextStyle style, {
  TextAlign textAlign = TextAlign.left,
  int? maxLines,
}) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textAlign: textAlign,
    maxLines: maxLines,
  )..layout();
  return painter;
}

Size measureText(
  String text,
  TextStyle style, {
  int? maxLines,
}) {
  final painter = buildTextPainter(
    text,
    style,
    maxLines: maxLines,
  );
  return painter.size;
}

String defaultCategoryFormatter(String value) => value;

EqValueFormatter fallbackValueFormatter(EqValueFormatter? formatter) {
  return formatter ?? defaultNumericFormatter;
}

EqCategoryFormatter fallbackCategoryFormatter(EqCategoryFormatter? formatter) {
  return formatter ?? defaultCategoryFormatter;
}
