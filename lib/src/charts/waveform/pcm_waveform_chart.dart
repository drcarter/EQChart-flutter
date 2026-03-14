import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../theme/chart_defaults.dart';

class EqPcmWaveformStyle {
  const EqPcmWaveformStyle({
    this.backgroundColor = const Color(0xFF101418),
    this.waveColor = const Color(0xFF6BD2FF),
    this.centerLineColor = const Color(0xFF2E3A46),
    this.strokeWidth = 1.5,
    this.contentPadding = 8,
    this.showCenterLine = true,
    this.amplitudeScale = 1,
  });

  final Color backgroundColor;
  final Color waveColor;
  final Color centerLineColor;
  final double strokeWidth;
  final double contentPadding;
  final bool showCenterLine;
  final double amplitudeScale;
}

class EqPcmWaveformController extends ChangeNotifier {
  EqPcmWaveformController({
    int sampleRateHz = 44100,
    int windowDurationMs = 2000,
  })  : _sampleRateHz = sampleRateHz.clamp(8000, 192000),
        _windowDurationMs = windowDurationMs.clamp(200, 60000),
        _ringBuffer = _EqPcmRingBuffer(
          _computeWaveformCapacity(
            sampleRateHz.clamp(8000, 192000),
            windowDurationMs.clamp(200, 60000),
          ),
        );

  int _sampleRateHz;
  int _windowDurationMs;
  final _EqPcmRingBuffer _ringBuffer;

  int get sampleRateHz => _sampleRateHz;
  int get windowDurationMs => _windowDurationMs;

  void setWindowDurationMs(int durationMs) {
    final target = durationMs.clamp(200, 60000);
    if (target == _windowDurationMs) {
      return;
    }
    _windowDurationMs = target;
    _ringBuffer.setCapacity(
        _computeWaveformCapacity(_sampleRateHz, _windowDurationMs));
    notifyListeners();
  }

  void setSampleRateHz(int hz) {
    final target = hz.clamp(8000, 192000);
    if (target == _sampleRateHz) {
      return;
    }
    _sampleRateHz = target;
    _ringBuffer.setCapacity(
        _computeWaveformCapacity(_sampleRateHz, _windowDurationMs));
    notifyListeners();
  }

  void clear() {
    _ringBuffer.clear();
    notifyListeners();
  }

  void setPcm16Mono(List<int> samples) {
    _ringBuffer.setAll(_normalizePcmSamples(samples));
    notifyListeners();
  }

  void appendPcm16Mono(List<int> samples) {
    if (samples.isEmpty) {
      return;
    }
    _ringBuffer.append(_normalizePcmSamples(samples));
    notifyListeners();
  }

  Int16List snapshot() => _ringBuffer.snapshot();
}

class EqPcmWaveformChart extends StatelessWidget {
  const EqPcmWaveformChart({
    super.key,
    required this.controller,
    this.style = const EqPcmWaveformStyle(),
    this.emptyText = 'No data',
  });

  final EqPcmWaveformController controller;
  final EqPcmWaveformStyle style;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: style.backgroundColor),
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final samples = controller.snapshot();
          return LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(
                constraints.maxWidth,
                constraints.maxHeight.isFinite ? constraints.maxHeight : 220,
              );
              return RepaintBoundary(
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    CustomPaint(
                      size: size,
                      painter: _PcmWaveformPainter(
                        samples: samples,
                        style: style,
                      ),
                    ),
                    if (samples.isEmpty)
                      Center(
                        child: Text(
                          emptyText,
                          style: EqChartDefaults.labelTextStyle.copyWith(
                            color: EqChartDefaults.softInk,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _PcmWaveformPainter extends CustomPainter {
  const _PcmWaveformPainter({
    required this.samples,
    required this.style,
  });

  final Int16List samples;
  final EqPcmWaveformStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = style.backgroundColor,
    );

    final left = style.contentPadding;
    final right = size.width - style.contentPadding;
    final top = style.contentPadding;
    final bottom = size.height - style.contentPadding;
    if (right <= left || bottom <= top) {
      return;
    }

    final centerY = (top + bottom) * 0.5;
    if (style.showCenterLine) {
      canvas.drawLine(
        Offset(left, centerY),
        Offset(right, centerY),
        Paint()
          ..color = style.centerLineColor
          ..strokeWidth = 1,
      );
    }

    if (samples.isEmpty) {
      return;
    }

    final plotWidth = right - left;
    final pixelWidth = plotWidth.floor().clamp(1, 1000000);
    final minMax = computePcmWaveformMinMaxPerPixel(samples, pixelWidth);
    if (minMax.isEmpty) {
      return;
    }

    final amplitudeScale = style.amplitudeScale.clamp(0.1, 3.0).toDouble();
    final amplitude = ((bottom - top) * 0.5) * amplitudeScale;
    final stepX = pixelWidth > 1 ? plotWidth / (pixelWidth - 1) : 0.0;
    final wavePaint = Paint()
      ..color = style.waveColor
      ..strokeWidth = math.max(0.5, style.strokeWidth)
      ..strokeCap = StrokeCap.round;

    for (var x = 0; x < pixelWidth; x++) {
      final minNorm = minMax[x * 2];
      final maxNorm = minMax[(x * 2) + 1];
      final yTop = centerY - (maxNorm * amplitude);
      final yBottom = centerY - (minNorm * amplitude);
      final xPos = left + (x * stepX);
      canvas.drawLine(
        Offset(xPos, yTop),
        Offset(xPos, yBottom),
        wavePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PcmWaveformPainter oldDelegate) {
    return oldDelegate.samples != samples || oldDelegate.style != style;
  }
}

@visibleForTesting
Float32List computePcmWaveformMinMaxPerPixel(
    List<int> samples, int pixelWidth) {
  if (samples.isEmpty || pixelWidth <= 0) {
    return Float32List(0);
  }

  const normalizer = 1 / 32767;
  final out = Float32List(pixelWidth * 2);
  for (var x = 0; x < pixelWidth; x++) {
    final start = (x * samples.length) ~/ pixelWidth;
    var end = ((x + 1) * samples.length) ~/ pixelWidth;
    if (end <= start) {
      end = math.min(start + 1, samples.length);
    }

    var minSample = 32767;
    var maxSample = -32768;
    for (var index = start; index < end; index++) {
      final value = samples[index];
      if (value < minSample) {
        minSample = value;
      }
      if (value > maxSample) {
        maxSample = value;
      }
    }

    out[x * 2] = (minSample * normalizer).clamp(-1, 1).toDouble();
    out[(x * 2) + 1] = (maxSample * normalizer).clamp(-1, 1).toDouble();
  }
  return out;
}

int _computeWaveformCapacity(int sampleRateHz, int windowDurationMs) {
  final value = (sampleRateHz * windowDurationMs) ~/ 1000;
  return math.max(1, value);
}

Int16List _normalizePcmSamples(List<int> samples) {
  final out = Int16List(samples.length);
  for (var index = 0; index < samples.length; index++) {
    out[index] = samples[index].clamp(-32768, 32767);
  }
  return out;
}

class _EqPcmRingBuffer {
  _EqPcmRingBuffer(int capacity) : _data = Int16List(math.max(1, capacity));

  Int16List _data;
  int _writeIndex = 0;
  int _size = 0;

  void clear() {
    _writeIndex = 0;
    _size = 0;
  }

  void setCapacity(int newCapacity) {
    final target = math.max(1, newCapacity);
    if (target == _data.length) {
      return;
    }
    final snapshot = this.snapshot();
    _data = Int16List(target);
    _writeIndex = 0;
    _size = 0;
    final from = math.max(0, snapshot.length - target);
    append(snapshot.sublist(from));
  }

  void setAll(Int16List samples) {
    clear();
    final from = math.max(0, samples.length - _data.length);
    append(samples.sublist(from));
  }

  void append(List<int> samples) {
    for (final sample in samples) {
      _data[_writeIndex] = sample;
      _writeIndex = (_writeIndex + 1) % _data.length;
      if (_size < _data.length) {
        _size++;
      }
    }
  }

  Int16List snapshot() {
    if (_size == 0) {
      return Int16List(0);
    }
    final out = Int16List(_size);
    final start = (_writeIndex - _size + _data.length) % _data.length;
    for (var index = 0; index < _size; index++) {
      out[index] = _data[(start + index) % _data.length];
    }
    return out;
  }
}
