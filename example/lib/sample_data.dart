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

  static List<BubbleDatum> bubbleScatterData() {
    return const <BubbleDatum>[
      BubbleDatum(
        x: 18,
        y: 82,
        size: 129087,
        color: Color(0xFF4A7FB1),
        label: 'Food',
        legendGroup: 'Arts',
      ),
      BubbleDatum(
        x: 34,
        y: 63,
        size: 113576,
        color: Color(0xFFFF9100),
        label: 'Retail',
        legendGroup: 'Goods',
      ),
      BubbleDatum(
        x: 42,
        y: 51,
        size: 102304,
        color: Color(0xFFF84C5A),
        label: 'Agriculture',
        legendGroup: 'Labor',
      ),
      BubbleDatum(
        x: 58,
        y: 35,
        size: 38822,
        color: Color(0xFF62B8B4),
        label: 'Services',
        legendGroup: 'Services',
      ),
      BubbleDatum(
        x: 72,
        y: 26,
        size: 34262,
        color: Color(0xFFFF9100),
        label: 'Clothing',
        legendGroup: 'Goods',
      ),
      BubbleDatum(
        x: 84,
        y: 18,
        size: 13854,
        color: Color(0xFFF84C5A),
        label: 'Housing',
        legendGroup: 'Labor',
      ),
    ];
  }

  static List<BubbleDatum> bubblePackedData() {
    return const <BubbleDatum>[
      BubbleDatum(
        x: 0,
        y: 0,
        size: 129087,
        color: Color(0xFF4A7FB1),
        label: 'Food',
        legendGroup: 'Arts',
      ),
      BubbleDatum(
        x: 0,
        y: 0,
        size: 113576,
        color: Color(0xFFFF9100),
        label: 'Retail',
        legendGroup: 'Goods',
      ),
      BubbleDatum(
        x: 0,
        y: 0,
        size: 102304,
        color: Color(0xFFF84C5A),
        label: 'Agriculture',
        legendGroup: 'Labor',
      ),
      BubbleDatum(
        x: 0,
        y: 0,
        size: 38822,
        color: Color(0xFF62B8B4),
        label: 'Services',
        legendGroup: 'Services',
      ),
      BubbleDatum(
        x: 0,
        y: 0,
        size: 34262,
        color: Color(0xFFFF9100),
        label: 'Clothing',
        legendGroup: 'Goods',
      ),
      BubbleDatum(
        x: 0,
        y: 0,
        size: 13854,
        color: Color(0xFFF84C5A),
        label: 'Housing',
        legendGroup: 'Labor',
      ),
    ];
  }

  static List<BoxPlotEntry> boxPlotEntries() {
    return const <BoxPlotEntry>[
      BoxPlotEntry(
        label: 'API',
        min: 92,
        q1: 118,
        median: 142,
        q3: 181,
        max: 226,
        outliers: <double>[248],
        color: Color(0xFF2563EB),
        title: 'Median 142ms',
        payload: 'API',
      ),
      BoxPlotEntry(
        label: 'Worker',
        min: 74,
        q1: 96,
        median: 126,
        q3: 164,
        max: 209,
        outliers: <double>[58, 228],
        color: Color(0xFF14B8A6),
        title: 'Median 126ms',
        payload: 'Worker',
      ),
      BoxPlotEntry(
        label: 'Cache',
        min: 38,
        q1: 51,
        median: 63,
        q3: 79,
        max: 101,
        outliers: <double>[112],
        color: Color(0xFF7C3AED),
        title: 'Median 63ms',
        payload: 'Cache',
      ),
      BoxPlotEntry(
        label: 'Search',
        min: 112,
        q1: 148,
        median: 188,
        q3: 236,
        max: 294,
        outliers: <double>[324],
        color: Color(0xFFF59E0B),
        title: 'Median 188ms',
        payload: 'Search',
      ),
    ];
  }

  static List<HistogramBin> histogramBins() {
    return const <HistogramBin>[
      HistogramBin(start: 0, end: 10, value: 4, payload: '0-10'),
      HistogramBin(start: 10, end: 20, value: 9, payload: '10-20'),
      HistogramBin(start: 20, end: 30, value: 13, payload: '20-30'),
      HistogramBin(start: 30, end: 40, value: 8, payload: '30-40'),
      HistogramBin(start: 40, end: 50, value: 3, payload: '40-50'),
    ];
  }

  static List<RangeBarEntry> rangeBarEntries() {
    return const <RangeBarEntry>[
      RangeBarEntry(
        label: 'Discovery',
        start: 0,
        end: 2,
        color: Color(0xFF2563EB),
        payload: 'Discovery',
      ),
      RangeBarEntry(
        label: 'Design',
        start: 1,
        end: 4,
        color: Color(0xFF14B8A6),
        payload: 'Design',
      ),
      RangeBarEntry(
        label: 'Platform',
        start: 3,
        end: 7,
        color: Color(0xFF7C3AED),
        payload: 'Platform',
      ),
      RangeBarEntry(
        label: 'QA',
        start: 6,
        end: 8,
        color: Color(0xFFF59E0B),
        payload: 'QA',
      ),
      RangeBarEntry(
        label: 'Launch',
        start: 8,
        end: 9,
        color: Color(0xFFEF4444),
        payload: 'Launch',
      ),
    ];
  }

  static List<StockHeatmapSection> heatmapSections() {
    return const <StockHeatmapSection>[
      StockHeatmapSection(
        name: 'Technology',
        color: Color(0xFF1E88E5),
        stocks: <StockHeatmapItem>[
          StockHeatmapItem(
            symbol: 'AAPL',
            name: 'Apple Inc.',
            sector: 'Technology',
            price: 200,
            changePct: 1.2,
            marketCap: 3000000000000,
            sizeRatio: 24,
          ),
          StockHeatmapItem(
            symbol: 'MSFT',
            name: 'Microsoft Corp.',
            sector: 'Technology',
            price: 380,
            changePct: -0.8,
            marketCap: 2800000000000,
            sizeRatio: 22,
          ),
          StockHeatmapItem(
            symbol: 'NVDA',
            name: 'NVIDIA Corp.',
            sector: 'Technology',
            price: 900,
            changePct: 4.2,
            marketCap: 2200000000000,
            sizeRatio: 18,
          ),
          StockHeatmapItem(
            symbol: 'ORCL',
            name: 'Oracle Corp.',
            sector: 'Technology',
            price: 122,
            changePct: 0.6,
            marketCap: 350000000000,
            sizeRatio: 8,
          ),
          StockHeatmapItem(
            symbol: 'ADBE',
            name: 'Adobe Inc.',
            sector: 'Technology',
            price: 590,
            changePct: -1.1,
            marketCap: 280000000000,
            sizeRatio: 6,
          ),
        ],
      ),
      StockHeatmapSection(
        name: 'Communication Services',
        color: Color(0xFF00897B),
        stocks: <StockHeatmapItem>[
          StockHeatmapItem(
            symbol: 'GOOGL',
            name: 'Alphabet Inc.',
            sector: 'Communication Services',
            price: 140,
            changePct: 0.5,
            marketCap: 1800000000000,
            sizeRatio: 20,
          ),
          StockHeatmapItem(
            symbol: 'META',
            name: 'Meta Platforms Inc.',
            sector: 'Communication Services',
            price: 450,
            changePct: -3.1,
            marketCap: 1100000000000,
            sizeRatio: 14,
          ),
          StockHeatmapItem(
            symbol: 'NFLX',
            name: 'Netflix Inc.',
            sector: 'Communication Services',
            price: 610,
            changePct: 1.8,
            marketCap: 260000000000,
            sizeRatio: 7,
          ),
          StockHeatmapItem(
            symbol: 'DIS',
            name: 'Walt Disney Co.',
            sector: 'Communication Services',
            price: 101,
            changePct: -0.4,
            marketCap: 190000000000,
            sizeRatio: 5,
          ),
          StockHeatmapItem(
            symbol: 'TMUS',
            name: 'T-Mobile US Inc.',
            sector: 'Communication Services',
            price: 162,
            changePct: 0.7,
            marketCap: 195000000000,
            sizeRatio: 6,
          ),
        ],
      ),
      StockHeatmapSection(
        name: 'Consumer Discretionary',
        color: Color(0xFFF4511E),
        stocks: <StockHeatmapItem>[
          StockHeatmapItem(
            symbol: 'AMZN',
            name: 'Amazon.com Inc.',
            sector: 'Consumer Discretionary',
            price: 160,
            changePct: 2.3,
            marketCap: 1700000000000,
            sizeRatio: 19,
          ),
          StockHeatmapItem(
            symbol: 'TSLA',
            name: 'Tesla Inc.',
            sector: 'Consumer Discretionary',
            price: 230,
            changePct: -2.5,
            marketCap: 700000000000,
            sizeRatio: 11,
          ),
          StockHeatmapItem(
            symbol: 'HD',
            name: 'Home Depot Inc.',
            sector: 'Consumer Discretionary',
            price: 360,
            changePct: -0.2,
            marketCap: 360000000000,
            sizeRatio: 8,
          ),
          StockHeatmapItem(
            symbol: 'MCD',
            name: "McDonald's Corp.",
            sector: 'Consumer Discretionary',
            price: 295,
            changePct: 0.9,
            marketCap: 220000000000,
            sizeRatio: 6,
          ),
          StockHeatmapItem(
            symbol: 'NKE',
            name: 'Nike Inc.',
            sector: 'Consumer Discretionary',
            price: 105,
            changePct: -1.6,
            marketCap: 160000000000,
            sizeRatio: 5,
          ),
        ],
      ),
      StockHeatmapSection(
        name: 'Financials',
        color: Color(0xFF6D4C41),
        stocks: <StockHeatmapItem>[
          StockHeatmapItem(
            symbol: 'JPM',
            name: 'JPMorgan Chase & Co.',
            sector: 'Financials',
            price: 180,
            changePct: 0.3,
            marketCap: 550000000000,
            sizeRatio: 12,
          ),
          StockHeatmapItem(
            symbol: 'BAC',
            name: 'Bank of America Corp.',
            sector: 'Financials',
            price: 33,
            changePct: -0.9,
            marketCap: 280000000000,
            sizeRatio: 8,
          ),
          StockHeatmapItem(
            symbol: 'WFC',
            name: 'Wells Fargo & Co.',
            sector: 'Financials',
            price: 58,
            changePct: 0.5,
            marketCap: 210000000000,
            sizeRatio: 6,
          ),
          StockHeatmapItem(
            symbol: 'GS',
            name: 'Goldman Sachs Group Inc.',
            sector: 'Financials',
            price: 410,
            changePct: 1.1,
            marketCap: 140000000000,
            sizeRatio: 4,
          ),
          StockHeatmapItem(
            symbol: 'MS',
            name: 'Morgan Stanley',
            sector: 'Financials',
            price: 92,
            changePct: -0.3,
            marketCap: 150000000000,
            sizeRatio: 5,
          ),
        ],
      ),
      StockHeatmapSection(
        name: 'Health Care',
        color: Color(0xFF8E24AA),
        stocks: <StockHeatmapItem>[
          StockHeatmapItem(
            symbol: 'UNH',
            name: 'UnitedHealth Group Inc.',
            sector: 'Health Care',
            price: 550,
            changePct: 0.9,
            marketCap: 480000000000,
            sizeRatio: 10,
          ),
          StockHeatmapItem(
            symbol: 'LLY',
            name: 'Eli Lilly and Co.',
            sector: 'Health Care',
            price: 760,
            changePct: 1.7,
            marketCap: 720000000000,
            sizeRatio: 13,
          ),
          StockHeatmapItem(
            symbol: 'JNJ',
            name: 'Johnson & Johnson',
            sector: 'Health Care',
            price: 157,
            changePct: -0.6,
            marketCap: 390000000000,
            sizeRatio: 7,
          ),
          StockHeatmapItem(
            symbol: 'PFE',
            name: 'Pfizer Inc.',
            sector: 'Health Care',
            price: 31,
            changePct: -1.2,
            marketCap: 180000000000,
            sizeRatio: 4,
          ),
          StockHeatmapItem(
            symbol: 'MRK',
            name: 'Merck & Co.',
            sector: 'Health Care',
            price: 122,
            changePct: 0.4,
            marketCap: 310000000000,
            sizeRatio: 6,
          ),
        ],
      ),
    ];
  }

  static List<GaugeRange> gaugeRanges() {
    return const <GaugeRange>[
      GaugeRange(
        startValue: 0,
        endValue: 55,
        color: Color(0xFF13C3A3),
        label: 'Healthy',
      ),
      GaugeRange(
        startValue: 55,
        endValue: 80,
        color: Color(0xFFFFB703),
        label: 'Warning',
      ),
      GaugeRange(
        startValue: 80,
        endValue: 100,
        color: Color(0xFFEF476F),
        label: 'Critical',
      ),
    ];
  }

  static List<int> waveformSamples({
    int sampleRateHz = 44100,
    int durationMs = 1600,
    double frequencyHz = 220,
  }) {
    final totalSamples = ((sampleRateHz.toDouble() * durationMs) / 1000)
        .round()
        .clamp(1, 1 << 30);
    return List<int>.generate(
      totalSamples,
      (index) {
        final t = index / sampleRateHz;
        final carrier = math.sin(2 * math.pi * frequencyHz * t);
        final overtone = math.sin(2 * math.pi * frequencyHz * 2.4 * t) * 0.28;
        final modulator = 0.65 + (math.sin(2 * math.pi * 1.2 * t) * 0.25);
        final value = (carrier + overtone) * modulator;
        return (value * 32767 * 0.58).round().clamp(-32768, 32767);
      },
      growable: false,
    );
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
