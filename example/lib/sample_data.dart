import 'dart:math' as math;

import 'package:eqchart_flutter/eqchart_flutter.dart';
import 'package:flutter/material.dart';

class ExampleChartData {
  static List<PieSlice> pieSlices() {
    return const <PieSlice>[
      PieSlice('Direct', 43, Color(0xFF2B80FF)),
      PieSlice('Social', 18, Color(0xFF13C3A3)),
      PieSlice('Search', 26, Color(0xFFFF9F1C)),
      PieSlice('Referral', 13, Color(0xFFEF476F)),
    ];
  }

  static List<PieSlice> donutSlices() {
    return const <PieSlice>[
      PieSlice('Engineering', 38, Color(0xFF2A9D8F)),
      PieSlice('Marketing', 22, Color(0xFF3A86FF)),
      PieSlice('Sales', 27, Color(0xFFFFBE0B)),
      PieSlice('Ops', 13, Color(0xFFFB5607)),
    ];
  }

  static List<BarSeries> barSeries() {
    const labels = <String>['Q1', 'Q2', 'Q3', 'Q4', 'Q5'];
    return <BarSeries>[
      BarSeries(
        name: 'Desktop',
        color: const Color(0xFF2B80FF),
        points: List<BarDatum>.generate(
          labels.length,
          (index) => BarDatum(
            labels[index],
            10 + (index * 4.0) + _stableJitter(index, 1.8),
          ),
          growable: false,
        ),
      ),
      BarSeries(
        name: 'Mobile',
        color: const Color(0xFF13C3A3),
        points: List<BarDatum>.generate(
          labels.length,
          (index) => BarDatum(
            labels[index],
            7 + (index * 3.0) + _stableJitter(index + 33, 1.4),
          ),
          growable: false,
        ),
      ),
      BarSeries(
        name: 'Tablet',
        color: const Color(0xFFFF9F1C),
        points: List<BarDatum>.generate(
          labels.length,
          (index) => BarDatum(
            labels[index],
            index == 0
                ? -2.4
                : 3 + (index * 2.4) + _stableJitter(index + 99, 1.1),
          ),
          growable: false,
        ),
      ),
    ];
  }

  static List<LineSeries> lineSeries() {
    final traffic = List<LineDatum>.generate(
      12,
      (month) {
        final base = switch (month % 4) {
          0 => 10.0,
          1 => 16.0,
          2 => 12.0,
          _ => 22.0,
        };
        final jitter = (month % 3) * 1.25;
        return LineDatum(
          month.toDouble(),
          base + jitter + (month * 0.7),
          label: monthLabel(month),
        );
      },
      growable: false,
    );

    final conversion = List<LineDatum>.generate(
      12,
      (month) {
        final base = 12.0 + math.sin(month * 0.75) * 4.0;
        final jitter = month.isEven ? 2.0 : 0.0;
        return LineDatum(
          month.toDouble(),
          base + jitter + (month * 0.4),
          label: monthLabel(month),
        );
      },
      growable: false,
    );

    return <LineSeries>[
      LineSeries(
        name: 'Traffic',
        color: const Color(0xFF2B80FF),
        points: traffic,
        areaFillColor: const Color(0xFF2B80FF),
      ),
      LineSeries(
        name: 'Conversion',
        color: const Color(0xFF13C3A3),
        points: conversion,
        areaFillColor: const Color(0xFF13C3A3),
      ),
    ];
  }

  static List<LineSeries> areaSeries() {
    final projected = List<LineDatum>.generate(
      12,
      (month) => LineDatum(
        month.toDouble(),
        50 + math.sin(month * 0.6) * 9 + (month * 0.45),
        label: monthLabel(month),
      ),
      growable: false,
    );
    final baseline = List<LineDatum>.generate(
      12,
      (month) => LineDatum(
        month.toDouble(),
        30 + math.sin(month * 0.55) * 7 + (month * 0.35),
        label: monthLabel(month),
      ),
      growable: false,
    );

    return <LineSeries>[
      LineSeries(
        name: 'Projected',
        color: const Color(0xFFFF9F1C),
        points: projected,
        areaFillColor: const Color(0xFFFF9F1C),
      ),
      LineSeries(
        name: 'Baseline',
        color: const Color(0xFF8A79FF),
        points: baseline,
        areaFillColor: const Color(0xFF8A79FF),
      ),
    ];
  }

  static List<RadarAxis> radarAxes() {
    return const <RadarAxis>[
      RadarAxis('sweet'),
      RadarAxis('price'),
      RadarAxis('color'),
      RadarAxis('fresh'),
      RadarAxis('good'),
    ];
  }

  static List<RadarSeries> radarSeries() {
    return const <RadarSeries>[
      RadarSeries('Apple', Color(0xFFB899FF), <double>[48, 80, 84, 34, 40]),
      RadarSeries('Banana', Color(0xFF6F8695), <double>[30, 40, 90, 82, 62]),
    ];
  }

  static String monthLabel(int index) {
    const labels = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return labels[index % labels.length];
  }

  static double _stableJitter(int seed, double amplitude) {
    final normalized = ((seed * 37) % 100) / 100;
    return normalized * amplitude;
  }
}
