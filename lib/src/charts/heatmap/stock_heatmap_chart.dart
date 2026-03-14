import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../common/chart_types.dart';
import '../../theme/chart_defaults.dart';

class StockHeatmapItem {
  const StockHeatmapItem({
    required this.symbol,
    required this.name,
    required this.sector,
    required this.price,
    required this.changePct,
    required this.marketCap,
    this.sizeRatio,
  });

  final String symbol;
  final String name;
  final String sector;
  final double price;
  final double changePct;
  final double marketCap;
  final double? sizeRatio;
}

class StockHeatmapSection {
  const StockHeatmapSection({
    required this.name,
    required this.color,
    required this.stocks,
  });

  final String name;
  final Color color;
  final List<StockHeatmapItem> stocks;
}

class EqStockHeatmapChartStyle {
  const EqStockHeatmapChartStyle({
    this.backgroundColor = const Color(0xFF111316),
    this.padding = const EdgeInsets.all(6),
    this.sectionGap = 3,
    this.blockGap = 2,
    this.sectionHeaderHeight = 20,
    this.sectionHeaderOpacity = 0.67,
    this.borderColor = const Color(0x55000000),
    this.selectionBorderColor = Colors.white,
    this.sectionTitleTextStyle = const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w800,
      color: Color(0xFFE9EEF5),
    ),
    this.symbolTextStyle = const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w800,
      color: Colors.white,
    ),
    this.changeTextStyle = const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: Colors.white,
    ),
  });

  final Color backgroundColor;
  final EdgeInsets padding;
  final double sectionGap;
  final double blockGap;
  final double sectionHeaderHeight;
  final double sectionHeaderOpacity;
  final Color borderColor;
  final Color selectionBorderColor;
  final TextStyle sectionTitleTextStyle;
  final TextStyle symbolTextStyle;
  final TextStyle changeTextStyle;
}

class EqStockHeatmapChartBehavior {
  const EqStockHeatmapChartBehavior({
    this.showSectionHeaders = true,
    this.animateOnDataChange = true,
    this.selectionEnabled = true,
    this.animationDuration = const Duration(milliseconds: 720),
    this.emptyText = 'No data',
  });

  final bool showSectionHeaders;
  final bool animateOnDataChange;
  final bool selectionEnabled;
  final Duration animationDuration;
  final String emptyText;
}

@visibleForTesting
class StockHeatmapBlockLayout {
  const StockHeatmapBlockLayout({
    required this.item,
    required this.rect,
    required this.sectionIndex,
    required this.itemIndex,
  });

  final StockHeatmapItem item;
  final Rect rect;
  final int sectionIndex;
  final int itemIndex;
}

@visibleForTesting
class StockHeatmapSectionHeaderLayout {
  const StockHeatmapSectionHeaderLayout({
    required this.section,
    required this.rect,
    required this.sectionIndex,
  });

  final StockHeatmapSection section;
  final Rect rect;
  final int sectionIndex;
}

@visibleForTesting
class StockHeatmapLayout {
  const StockHeatmapLayout({
    required this.bounds,
    required this.blocks,
    required this.headers,
  });

  final Rect bounds;
  final List<StockHeatmapBlockLayout> blocks;
  final List<StockHeatmapSectionHeaderLayout> headers;
}

@visibleForTesting
StockHeatmapLayout computeStockHeatmapLayout(
  Size size,
  List<StockHeatmapSection> sections,
  EqStockHeatmapChartStyle style,
  EqStockHeatmapChartBehavior behavior,
) {
  final bounds = style.padding.deflateRect(Offset.zero & size);
  if (bounds.width <= 0 || bounds.height <= 0) {
    return const StockHeatmapLayout(
      bounds: Rect.zero,
      blocks: <StockHeatmapBlockLayout>[],
      headers: <StockHeatmapSectionHeaderLayout>[],
    );
  }

  final validSections = <_HeatmapSectionEntry>[
    for (var sectionIndex = 0; sectionIndex < sections.length; sectionIndex++)
      if (sections[sectionIndex].name.trim().isNotEmpty)
        _HeatmapSectionEntry(
          section: sections[sectionIndex],
          sectionIndex: sectionIndex,
          validStocks: <_HeatmapItemEntry>[
            for (var itemIndex = 0;
                itemIndex < sections[sectionIndex].stocks.length;
                itemIndex++)
              if (_heatmapItemWeight(sections[sectionIndex].stocks[itemIndex]) >
                  0)
                _HeatmapItemEntry(
                  item: sections[sectionIndex].stocks[itemIndex],
                  sectionIndex: sectionIndex,
                  itemIndex: itemIndex,
                ),
          ],
        ),
  ].where((entry) => entry.validStocks.isNotEmpty).toList(growable: false);

  if (validSections.isEmpty) {
    return StockHeatmapLayout(
      bounds: bounds,
      blocks: const <StockHeatmapBlockLayout>[],
      headers: const <StockHeatmapSectionHeaderLayout>[],
    );
  }

  final blocks = <StockHeatmapBlockLayout>[];
  final headers = <StockHeatmapSectionHeaderLayout>[];

  if (validSections.length <= 1 || !behavior.showSectionHeaders) {
    final flatItems = <_WeightedItem<_HeatmapItemEntry>>[
      for (final section in validSections)
        for (final stock in section.validStocks)
          _WeightedItem(stock, _heatmapItemWeight(stock.item)),
    ];
    for (final block in _layoutSquarified(flatItems, bounds)) {
      final inset = _insetRect(block.rect, style.blockGap);
      if (inset.width <= 0 || inset.height <= 0) {
        continue;
      }
      blocks.add(
        StockHeatmapBlockLayout(
          item: block.item.item,
          rect: inset,
          sectionIndex: block.item.sectionIndex,
          itemIndex: block.item.itemIndex,
        ),
      );
    }
    return StockHeatmapLayout(bounds: bounds, blocks: blocks, headers: headers);
  }

  final sectionBlocks = _layoutSquarified(
    <_WeightedItem<_HeatmapSectionEntry>>[
      for (final section in validSections)
        _WeightedItem(
          section,
          section.validStocks.fold<double>(
            0,
            (sum, item) => sum + _heatmapItemWeight(item.item),
          ),
        ),
    ],
    bounds,
  );

  for (final sectionBlock in sectionBlocks) {
    final section = sectionBlock.item;
    final fullRect = _insetRect(sectionBlock.rect, style.sectionGap);
    if (fullRect.width <= 0 || fullRect.height <= 0) {
      continue;
    }

    Rect contentRect = fullRect;
    if (fullRect.height > style.sectionHeaderHeight * 1.5) {
      final headerRect = Rect.fromLTRB(
        fullRect.left,
        fullRect.top,
        fullRect.right,
        fullRect.top + style.sectionHeaderHeight,
      );
      headers.add(
        StockHeatmapSectionHeaderLayout(
          section: section.section,
          rect: headerRect,
          sectionIndex: section.sectionIndex,
        ),
      );
      contentRect = Rect.fromLTRB(
        fullRect.left,
        headerRect.bottom,
        fullRect.right,
        fullRect.bottom,
      );
    }

    for (final block in _layoutSquarified(
      <_WeightedItem<_HeatmapItemEntry>>[
        for (final item in section.validStocks)
          _WeightedItem(item, _heatmapItemWeight(item.item)),
      ],
      contentRect,
    )) {
      final inset = _insetRect(block.rect, style.blockGap);
      if (inset.width <= 0 || inset.height <= 0) {
        continue;
      }
      blocks.add(
        StockHeatmapBlockLayout(
          item: block.item.item,
          rect: inset,
          sectionIndex: block.item.sectionIndex,
          itemIndex: block.item.itemIndex,
        ),
      );
    }
  }

  return StockHeatmapLayout(bounds: bounds, blocks: blocks, headers: headers);
}

class EqStockHeatmapChart extends StatefulWidget {
  const EqStockHeatmapChart({
    super.key,
    required this.sections,
    this.style = const EqStockHeatmapChartStyle(),
    this.behavior = const EqStockHeatmapChartBehavior(),
    this.onItemTap,
  }) : _items = null;

  const EqStockHeatmapChart.fromItems({
    super.key,
    required List<StockHeatmapItem> items,
    this.style = const EqStockHeatmapChartStyle(),
    this.behavior = const EqStockHeatmapChartBehavior(),
    this.onItemTap,
  })  : sections = null,
        _items = items;

  final List<StockHeatmapSection>? sections;
  final List<StockHeatmapItem>? _items;
  final EqStockHeatmapChartStyle style;
  final EqStockHeatmapChartBehavior behavior;
  final EqSelectionChanged<StockHeatmapItem>? onItemTap;

  List<StockHeatmapSection> get resolvedSections =>
      sections ?? _groupHeatmapItems(_items ?? const <StockHeatmapItem>[]);

  @override
  State<EqStockHeatmapChart> createState() => _EqStockHeatmapChartState();
}

class _EqStockHeatmapChartState extends State<EqStockHeatmapChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int? _selectedSectionIndex;
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
  void didUpdateWidget(covariant EqStockHeatmapChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.behavior.animationDuration !=
        widget.behavior.animationDuration) {
      _controller.duration = widget.behavior.animationDuration;
    }
    if (widget.behavior.animateOnDataChange &&
        (oldWidget.sections != widget.sections ||
            oldWidget._items != widget._items ||
            oldWidget.behavior.showSectionHeaders !=
                widget.behavior.showSectionHeaders)) {
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
    final layout = computeStockHeatmapLayout(
      size,
      widget.resolvedSections,
      widget.style,
      widget.behavior,
    );
    final hit = layout.blocks.cast<StockHeatmapBlockLayout?>().firstWhere(
          (block) => block?.rect.contains(details.localPosition) ?? false,
          orElse: () => null,
        );
    if (hit == null) {
      return;
    }

    if (widget.behavior.selectionEnabled) {
      setState(() {
        _selectedSectionIndex = hit.sectionIndex;
        _selectedItemIndex = hit.itemIndex;
      });
    }
    widget.onItemTap?.call(
      EqChartSelection<StockHeatmapItem>(
        seriesIndex: hit.sectionIndex,
        itemIndex: hit.itemIndex,
        datum: hit.item,
        localPosition: details.localPosition,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasData =
        widget.resolvedSections.any((section) => section.stocks.isNotEmpty);

    final chartBody = !hasData
        ? DecoratedBox(
            decoration: BoxDecoration(color: widget.style.backgroundColor),
            child: Center(
              child: Text(
                widget.behavior.emptyText,
                style: EqChartDefaults.labelTextStyle.copyWith(
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
                        : 420,
                  );
                  return GestureDetector(
                    onTapUp: widget.onItemTap != null ||
                            widget.behavior.selectionEnabled
                        ? (details) => _handleTap(details, size)
                        : null,
                    child: RepaintBoundary(
                      child: CustomPaint(
                        size: size,
                        painter: _StockHeatmapPainter(
                          sections: widget.resolvedSections,
                          style: widget.style,
                          behavior: widget.behavior,
                          progress: _controller.value,
                          selectedSectionIndex: _selectedSectionIndex,
                          selectedItemIndex: _selectedItemIndex,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );

    return DecoratedBox(
      decoration: BoxDecoration(color: widget.style.backgroundColor),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxHeight.isFinite) {
            return chartBody;
          }
          return SizedBox(height: 420, child: chartBody);
        },
      ),
    );
  }
}

class _StockHeatmapPainter extends CustomPainter {
  const _StockHeatmapPainter({
    required this.sections,
    required this.style,
    required this.behavior,
    required this.progress,
    required this.selectedSectionIndex,
    required this.selectedItemIndex,
  });

  final List<StockHeatmapSection> sections;
  final EqStockHeatmapChartStyle style;
  final EqStockHeatmapChartBehavior behavior;
  final double progress;
  final int? selectedSectionIndex;
  final int? selectedItemIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = computeStockHeatmapLayout(size, sections, style, behavior);
    if (layout.bounds == Rect.zero) {
      return;
    }

    final borderPaint = Paint()
      ..color = style.borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final block in layout.blocks) {
      final animatedRect = _animatedRect(block.rect, progress);
      final fillPaint = Paint()
        ..color = mapStockHeatmapChangeToColor(block.item.changePct);
      canvas.drawRect(animatedRect, fillPaint);
      canvas.drawRect(animatedRect, borderPaint);
      _paintBlockText(canvas, animatedRect, block.item);

      if (selectedSectionIndex == block.sectionIndex &&
          selectedItemIndex == block.itemIndex &&
          behavior.selectionEnabled) {
        canvas.drawRect(
          animatedRect,
          Paint()
            ..color = style.selectionBorderColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }

    for (final header in layout.headers) {
      final animatedRect = _animatedRect(header.rect, progress);
      final fillPaint = Paint()
        ..color = header.section.color.withOpacity(style.sectionHeaderOpacity);
      canvas.drawRect(animatedRect, fillPaint);
      canvas.drawRect(animatedRect, borderPaint);

      final painter = TextPainter(
        text: TextSpan(
          text: header.section.name,
          style: style.sectionTitleTextStyle,
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: math.max(0, animatedRect.width - 8));

      painter.paint(
        canvas,
        Offset(
          animatedRect.left + 4,
          animatedRect.top + ((animatedRect.height - painter.height) / 2),
        ),
      );
    }
  }

  void _paintBlockText(Canvas canvas, Rect rect, StockHeatmapItem item) {
    final width = rect.width;
    final height = rect.height;
    if (width < 42 || height < 22) {
      return;
    }

    const padding = 4.0;
    final textScale =
        (math.min(width, height) / 58).clamp(0.85, 1.45).toDouble();
    final symbolStyle = style.symbolTextStyle.copyWith(
      fontSize: (style.symbolTextStyle.fontSize ?? 12) * textScale,
    );
    final changeStyle = style.changeTextStyle.copyWith(
      fontSize: (style.changeTextStyle.fontSize ?? 10) * textScale,
    );

    final symbolPainter = TextPainter(
      text: TextSpan(text: item.symbol, style: symbolStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: math.max(0, width - (padding * 2)));
    symbolPainter.paint(
      canvas,
      Offset(rect.left + padding, rect.top + padding),
    );

    if (height >= 36) {
      final changePainter = TextPainter(
        text: TextSpan(
          text: formatStockHeatmapChange(item.changePct),
          style: changeStyle,
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: math.max(0, width - (padding * 2)));
      changePainter.paint(
        canvas,
        Offset(
          rect.left + padding,
          rect.top + padding + symbolPainter.height + 2,
        ),
      );
    }
  }

  Rect _animatedRect(Rect rect, double progress) {
    final width = rect.width * progress;
    final height = rect.height * progress;
    return Rect.fromCenter(
      center: rect.center,
      width: math.max(1, width),
      height: math.max(1, height),
    );
  }

  @override
  bool shouldRepaint(covariant _StockHeatmapPainter oldDelegate) {
    return oldDelegate.sections != sections ||
        oldDelegate.style != style ||
        oldDelegate.behavior != behavior ||
        oldDelegate.progress != progress ||
        oldDelegate.selectedSectionIndex != selectedSectionIndex ||
        oldDelegate.selectedItemIndex != selectedItemIndex;
  }
}

class _HeatmapSectionEntry {
  const _HeatmapSectionEntry({
    required this.section,
    required this.sectionIndex,
    required this.validStocks,
  });

  final StockHeatmapSection section;
  final int sectionIndex;
  final List<_HeatmapItemEntry> validStocks;
}

class _HeatmapItemEntry {
  const _HeatmapItemEntry({
    required this.item,
    required this.sectionIndex,
    required this.itemIndex,
  });

  final StockHeatmapItem item;
  final int sectionIndex;
  final int itemIndex;
}

class _WeightedItem<T> {
  const _WeightedItem(this.item, this.weight);

  final T item;
  final double weight;
}

class _LayoutBlock<T> {
  const _LayoutBlock(this.item, this.rect);

  final T item;
  final Rect rect;
}

double _heatmapItemWeight(StockHeatmapItem item) {
  final ratio = item.sizeRatio ?? 0;
  if (ratio > 0) {
    return ratio;
  }
  return math.max(0, item.marketCap);
}

Rect _insetRect(Rect rect, double inset) {
  return Rect.fromLTRB(
    rect.left + inset,
    rect.top + inset,
    rect.right - inset,
    rect.bottom - inset,
  );
}

List<_LayoutBlock<T>> _layoutSquarified<T>(
  List<_WeightedItem<T>> items,
  Rect bounds,
) {
  if (items.isEmpty || bounds.width <= 0 || bounds.height <= 0) {
    return <_LayoutBlock<T>>[];
  }

  final totalWeight = items.fold<double>(0, (sum, item) => sum + item.weight);
  if (totalWeight <= 0) {
    return <_LayoutBlock<T>>[];
  }

  final scale = (bounds.width * bounds.height) / totalWeight;
  final scaled = items
      .where((item) => item.weight > 0)
      .map((item) => _WeightedItem(item.item, math.max(item.weight * scale, 1)))
      .toList(growable: false)
    ..sort((a, b) => b.weight.compareTo(a.weight));

  if (scaled.isEmpty) {
    return <_LayoutBlock<T>>[];
  }

  final output = <_LayoutBlock<T>>[];
  _squarify(
    remaining: scaled,
    currentRow: <_WeightedItem<T>>[],
    rect: bounds,
    output: output,
  );
  return output;
}

void _squarify<T>({
  required List<_WeightedItem<T>> remaining,
  required List<_WeightedItem<T>> currentRow,
  required Rect rect,
  required List<_LayoutBlock<T>> output,
}) {
  if (remaining.isEmpty) {
    if (currentRow.isNotEmpty) {
      _layoutHeatmapRow(currentRow, rect, output);
    }
    return;
  }

  final nextItem = remaining.first;
  final nextRemaining = remaining.sublist(1);

  if (currentRow.isEmpty) {
    _squarify(
      remaining: nextRemaining,
      currentRow: <_WeightedItem<T>>[nextItem],
      rect: rect,
      output: output,
    );
    return;
  }

  final widthConstraint = math.min(rect.width, rect.height);
  final currentWorst = _worstAspectRatio(currentRow, widthConstraint);
  final newRow = <_WeightedItem<T>>[...currentRow, nextItem];
  final newWorst = _worstAspectRatio(newRow, widthConstraint);

  if (newWorst <= currentWorst) {
    _squarify(
      remaining: nextRemaining,
      currentRow: newRow,
      rect: rect,
      output: output,
    );
  } else {
    final nextRect = _layoutHeatmapRow(currentRow, rect, output);
    _squarify(
      remaining: remaining,
      currentRow: <_WeightedItem<T>>[],
      rect: nextRect,
      output: output,
    );
  }
}

Rect _layoutHeatmapRow<T>(
  List<_WeightedItem<T>> row,
  Rect rect,
  List<_LayoutBlock<T>> output,
) {
  final totalArea = row.fold<double>(0, (sum, item) => sum + item.weight);
  final horizontal = rect.width >= rect.height;

  if (horizontal) {
    final rowHeight = totalArea / rect.width;
    var x = rect.left;
    for (final item in row) {
      final itemWidth = item.weight / rowHeight;
      output.add(
        _LayoutBlock(
          item.item,
          Rect.fromLTRB(
            x,
            rect.top,
            math.min(x + itemWidth, rect.right),
            math.min(rect.top + rowHeight, rect.bottom),
          ),
        ),
      );
      x += itemWidth;
    }
    return Rect.fromLTRB(
      rect.left,
      rect.top + rowHeight,
      rect.right,
      rect.bottom,
    );
  }

  final columnWidth = totalArea / rect.height;
  var y = rect.top;
  for (final item in row) {
    final itemHeight = item.weight / columnWidth;
    output.add(
      _LayoutBlock(
        item.item,
        Rect.fromLTRB(
          rect.left,
          y,
          math.min(rect.left + columnWidth, rect.right),
          math.min(y + itemHeight, rect.bottom),
        ),
      ),
    );
    y += itemHeight;
  }
  return Rect.fromLTRB(
    rect.left + columnWidth,
    rect.top,
    rect.right,
    rect.bottom,
  );
}

double _worstAspectRatio(List<_WeightedItem<Object?>> row, double width) {
  if (row.isEmpty || width <= 0) {
    return double.infinity;
  }
  final sumArea = row.fold<double>(0, (sum, item) => sum + item.weight);
  final sideShort = math.min(width, sumArea / width);
  var worst = 0.0;
  for (final item in row) {
    if (item.weight <= 0) {
      continue;
    }
    final side1 = item.weight / sideShort;
    final side2 = sideShort;
    final ratio = math.max(side1 / side2, side2 / side1);
    worst = math.max(worst, ratio);
  }
  return worst == 0 ? double.infinity : worst;
}

Color mapStockHeatmapSectorToColor(String sector) {
  const palette = <Color>[
    Color(0xFF1E88E5),
    Color(0xFF00897B),
    Color(0xFFF4511E),
    Color(0xFF6D4C41),
    Color(0xFF8E24AA),
    Color(0xFF3949AB),
    Color(0xFF43A047),
    Color(0xFFFB8C00),
  ];
  final index = sector.hashCode.abs() % palette.length;
  return palette[index];
}

Color mapStockHeatmapChangeToColor(double changePct) {
  const maxAbs = 6.0;
  final clamped = changePct.clamp(-maxAbs, maxAbs).toDouble();
  final ratio = clamped / maxAbs;

  const neutral = Color(0xFF2A2F36);
  const up = Color(0xFF1F8F55);
  const down = Color(0xFFB23A3A);

  if (ratio > 0) {
    return Color.lerp(neutral, up, ratio)!;
  }
  if (ratio < 0) {
    return Color.lerp(neutral, down, ratio.abs())!;
  }
  return neutral;
}

String formatStockHeatmapChange(double changePct) {
  final sign = changePct >= 0 ? '+' : '';
  return '$sign${changePct.toStringAsFixed(2)}%';
}

String formatStockHeatmapMarketCap(double marketCap) {
  if (marketCap >= 1000000000000) {
    return '${(marketCap / 1000000000000).toStringAsFixed(1)}T';
  }
  if (marketCap >= 1000000000) {
    return '${(marketCap / 1000000000).toStringAsFixed(1)}B';
  }
  if (marketCap >= 1000000) {
    return '${(marketCap / 1000000).toStringAsFixed(1)}M';
  }
  return marketCap.toStringAsFixed(0);
}

List<StockHeatmapSection> _groupHeatmapItems(List<StockHeatmapItem> items) {
  final grouped = <String, List<StockHeatmapItem>>{};
  for (final item in items) {
    grouped.putIfAbsent(item.sector, () => <StockHeatmapItem>[]).add(item);
  }
  return grouped.entries
      .map(
        (entry) => StockHeatmapSection(
          name: entry.key,
          color: mapStockHeatmapSectorToColor(entry.key),
          stocks: entry.value,
        ),
      )
      .toList(growable: false);
}
