import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../data/lectio_ai_service.dart';

class LectioPredictionExplorer extends StatefulWidget {
  const LectioPredictionExplorer({super.key, required this.books});

  final List<LectioPrediction> books;

  @override
  State<LectioPredictionExplorer> createState() =>
      _LectioPredictionExplorerState();
}

class _LectioPredictionExplorerState extends State<LectioPredictionExplorer> {
  String? _selectedBookId;

  @override
  Widget build(BuildContext context) {
    final books = widget.books.where((book) => book.isAvailable).toList();
    if (books.isEmpty) return const SizedBox.shrink();
    final selected = books.firstWhere(
      (book) => book.bookId == _selectedBookId,
      orElse: () => books.first,
    );
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 30),
        Text(
          'Pron\u00f3stico por libro',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontSize: 24, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 5),
        Text(
          'Elige un t\u00edtulo para comparar sus reservas reales y estimadas.',
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: colors.onSurfaceVariant, height: 1.45),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: selected.bookId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Selecciona un libro',
            border: OutlineInputBorder(),
          ),
          items: [
            for (var index = 0; index < books.length; index++)
              DropdownMenuItem(
                value: books[index].bookId,
                child: Text(
                  '#${index + 1} \u00b7 '
                  '${books[index].title?.isNotEmpty == true ? books[index].title! : 'Libro sin t\u00edtulo'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (value) => setState(() => _selectedBookId = value),
        ),
        const SizedBox(height: 12),
        _SummaryCard(book: selected),
        const SizedBox(height: 12),
        _HistoryForecastChart(book: selected),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.book});

  final LectioPrediction book;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 12,
        spacing: 20,
        children: [
          _SummaryValue(
            label: 'Demanda estimada \u00b7 30 d\u00edas',
            value: _formatDemand(book.demand30Days!),
          ),
          if (book.historicalDemand != null)
            _SummaryValue(
              label: 'Demanda hist\u00f3rica',
              value: _formatDemand(book.historicalDemand!),
            ),
          if (book.category?.isNotEmpty == true)
            _SummaryValue(label: 'Categor\u00eda', value: book.category!),
        ],
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 130, maxWidth: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryForecastChart extends StatelessWidget {
  const _HistoryForecastChart({required this.book});

  final LectioPrediction book;

  @override
  Widget build(BuildContext context) {
    final sortedHistory = [...book.weeklyHistory]
      ..sort((a, b) => a.periodStart.compareTo(b.periodStart));
    final history = sortedHistory
        .skip(math.max(0, sortedHistory.length - 5))
        .toList();
    final forecast = [...book.weeklyForecast]
      ..sort((a, b) => a.periodStart.compareTo(b.periodStart));
    final visibleForecast = forecast.take(5).toList();
    if (history.isEmpty && visibleForecast.isEmpty) {
      return const _ChartCard(
        title: 'Evoluci\u00f3n de reservas',
        subtitle:
            'No hay historial ni pron\u00f3stico semanal para este libro.',
        child: SizedBox(height: 24),
      );
    }

    final values = <double>[
      ...history.map((item) => item.demand),
      ...visibleForecast.map((item) => item.predictedDemand),
    ];
    final maxValue = values.reduce((a, b) => math.max(a, b).toDouble());
    final maxY = maxValue == 0 ? 1.0 : maxValue * 1.25;
    final interval = maxY / 4;
    final colors = Theme.of(context).colorScheme;
    final historySpots = history
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.demand))
        .toList(growable: false);
    final forecastSpots = visibleForecast
        .asMap()
        .entries
        .map(
          (entry) => FlSpot(entry.key.toDouble(), entry.value.predictedDemand),
        )
        .toList(growable: false);

    return _ChartCard(
      title: 'Evoluci\u00f3n de reservas',
      child: Column(
        children: [
          SizedBox(
            height: 238,
            child: Semantics(
              label:
                  'Evoluci\u00f3n de reservas de ${book.title ?? 'libro'}: '
                  'historial real ${history.asMap().entries.map((e) => 'Semana ${e.key + 1}, ${_formatDemand(e.value.demand)} reservas').join('; ')}. '
                  'pron\u00f3stico ${visibleForecast.asMap().entries.map((e) => 'Semana ${e.key + 1}, ${_formatDemand(e.value.predictedDemand)} estimadas').join('; ')}.',
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: 4,
                  minY: 0,
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: interval,
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 38,
                        interval: interval,
                        getTitlesWidget: (value, meta) => SideTitleWidget(
                          meta: meta,
                          child: Text(
                            _formatDemand(value),
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 38,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.round();
                          if (index < 0 || index >= 5) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            meta: meta,
                            child: SizedBox(
                              width: 44,
                              child: Text(
                                'Semana\n${index + 1}',
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                  fontSize: 9,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => spots.map((spot) {
                        final index = spot.x.round();
                        if (index < 0 || index >= 5) return null;
                        final isHistorySeries =
                            historySpots.isNotEmpty && spot.barIndex == 0;
                        if (isHistorySeries) {
                          if (index >= history.length) return null;
                          final item = history[index];
                          return LineTooltipItem(
                            'Semana ${index + 1} · ${_formatDate(item.periodStart)}\n${_formatDemand(item.demand)} reservas reales',
                            TextStyle(color: colors.onPrimary),
                          );
                        }
                        if (index >= visibleForecast.length) return null;
                        final item = visibleForecast[index];
                        final days = item.daysCovered == null
                            ? ''
                            : ' \u00b7 ${item.daysCovered} d\u00edas';
                        return LineTooltipItem(
                          'Semana ${index + 1} · ${_formatDate(item.periodStart)}$days\n${_formatDemand(item.predictedDemand)} estimadas',
                          TextStyle(color: colors.onPrimary),
                        );
                      }).toList(),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: historySpots,
                      color: Colors.blue,
                      barWidth: 3,
                      isCurved: false,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                    ),
                    LineChartBarData(
                      spots: forecastSpots,
                      color: Colors.green,
                      barWidth: 3,
                      isCurved: false,
                      isStrokeCapRound: true,
                      dashArray: const [8, 4],
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withValues(alpha: .08),
                      ),
                    ),
                  ],
                ),
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 22,
            runSpacing: 8,
            children: [
              _LegendItem(color: Colors.blue, label: 'Reservas reales'),
              _LegendItem(color: Colors.green, label: 'Pron\u00f3stico'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 7),
      Text(label, style: Theme.of(context).textTheme.labelMedium),
    ],
  );
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, this.subtitle, required this.child});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 10),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
          ] else
            const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

String _formatDemand(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
}

String _formatDate(String value) {
  final date = DateTime.tryParse(value);
  if (date == null) return value;
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}
