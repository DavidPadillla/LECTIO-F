import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/lectio_ai_service.dart';

const _ink = Color(0xFF0D2B1D);
const _inkSoft = Color(0xFF2D4A3A);
const _muted = Color(0xFF6B8377);
const _line = Color(0xFFD4E5D9);
const _green = Color(0xFF1A6B45);
const _greenBright = Color(0xFF34A06C);
const _paper = Color(0xFFF7FAF8);

class LectioAiInsights extends StatefulWidget {
  const LectioAiInsights({super.key, this.dataSource});

  final LectioAiDataSource? dataSource;

  @override
  State<LectioAiInsights> createState() => _LectioAiInsightsState();
}

class _LectioAiInsightsState extends State<LectioAiInsights> {
  late final LectioAiService? _ownedService = widget.dataSource == null
      ? LectioAiService()
      : null;
  late final LectioAiDataSource _dataSource =
      widget.dataSource ?? _ownedService!;
  late Future<LectioPredictions> _predictionsFuture;
  late Future<LectioCategoryAnalytics> _analyticsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _ownedService?.close();
    super.dispose();
  }

  void _reload() {
    _predictionsFuture = _dataSource.loadPredictions();
    _analyticsFuture = _dataSource.loadCategoryAnalytics();
  }

  void _refresh() {
    setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _paper,
      width: double.infinity,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 46, 22, 54),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: _green),
                    const SizedBox(width: 10),
                    Text(
                      'LECTIO-AI',
                      style: GoogleFonts.jetBrainsMono(
                        color: _green,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Actualizar información predictiva',
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh_rounded),
                      color: _green,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Decisiones con datos.',
                  style: GoogleFonts.instrumentSerif(color: _ink, fontSize: 38),
                ),
                const SizedBox(height: 26),
                _SectionHeading(
                  icon: Icons.trending_up_rounded,
                  title: 'Más solicitados próximamente',
                  subtitle: 'Estimación de demanda para los próximos 30 días.',
                ),
                const SizedBox(height: 14),
                FutureBuilder<LectioPredictions>(
                  future: _predictionsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const _InsightLoading(
                        label: 'Cargando predicciones...',
                      );
                    }
                    if (snapshot.hasError) {
                      return _InsightError(
                        message: _errorMessage(
                          snapshot.error,
                          'No se pudieron cargar las predicciones.',
                        ),
                        onRetry: _refresh,
                      );
                    }

                    final predictions = snapshot.data!.availableBooks
                        .take(5)
                        .toList(growable: false);
                    if (predictions.isEmpty) {
                      return const _InsightEmpty(
                        message: 'Aún no hay libros con una predicción de demanda disponible.',
                      );
                    }

                    return _PredictionList(
                      predictions: predictions,
                      horizonDays: snapshot.data!.horizonDays,
                    );
                  },
                ),
                const SizedBox(height: 34),
                _SectionHeading(
                  icon: Icons.insert_chart_outlined_rounded,
                  title: 'Gráficas de demanda',
                  subtitle:
                      'Explora el historial con dos gráficas desplegables.',
                ),
                const SizedBox(height: 14),
                FutureBuilder<LectioCategoryAnalytics>(
                  future: _analyticsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const _InsightLoading(
                        label: 'Cargando tendencias...',
                      );
                    }
                    if (snapshot.hasError) {
                      return _InsightError(
                        message: _errorMessage(
                          snapshot.error,
                          'No se pudieron cargar las tendencias por categoría.',
                        ),
                        onRetry: _refresh,
                      );
                    }

                    final analytics = snapshot.data!;
                    if (analytics.categories.isEmpty &&
                        analytics.monthlyDemand.isEmpty) {
                      return const _InsightEmpty(
                        message: 'LECTIO-AI no tiene estadísticas históricas disponibles.',
                      );
                    }
                    return _AnalyticsAccordion(analytics: analytics);
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Las predicciones son estimaciones, se actualizan periódicamente '
                  'y no garantizan la demanda futura.',
                  style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFE6F3EB),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: _green),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.instrumentSerif(
                  color: _ink,
                  fontSize: 25,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PredictionList extends StatelessWidget {
  const _PredictionList({required this.predictions, required this.horizonDays});

  final List<LectioPrediction> predictions;
  final int? horizonDays;

  @override
  Widget build(BuildContext context) {
    final horizon = horizonDays == null ? 'Próximamente' : '$horizonDays días';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          for (var index = 0; index < predictions.length; index++)
            _PredictionRow(
              key: ValueKey(predictions[index].bookId),
              rank: index + 1,
              prediction: predictions[index],
              horizon: horizon,
              isLast: index == predictions.length - 1,
            ),
        ],
      ),
    );
  }
}

class _PredictionRow extends StatelessWidget {
  const _PredictionRow({
    super.key,
    required this.rank,
    required this.prediction,
    required this.horizon,
    required this.isLast,
  });

  final int rank;
  final LectioPrediction prediction;
  final String horizon;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: _line)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 35,
            child: Text(
              rank.toString().padLeft(2, '0'),
              style: GoogleFonts.jetBrainsMono(
                color: _green,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Icon(Icons.menu_book_outlined, color: _green, size: 20),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prediction.title?.isNotEmpty == true
                      ? prediction.title!
                      : 'Título no disponible',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  prediction.category?.isNotEmpty == true
                      ? prediction.category!
                      : 'Categoría no disponible',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(horizon, style: const TextStyle(color: _muted, fontSize: 11)),
        ],
      ),
    );
  }
}

class _AnalyticsAccordion extends StatelessWidget {
  const _AnalyticsAccordion({required this.analytics});

  final LectioCategoryAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.white,
            child: ExpansionTile(
              key: const ValueKey('category-demand-accordion'),
              leading: const Icon(Icons.radar_rounded, color: _green),
              title: const Text('Demanda histórica por categoría'),
              subtitle: const Text('Comparación entre categorías'),
              childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              children: [
                if (analytics.categories.isEmpty)
                  const _InsightEmpty(
                    message: 'No hay estadísticas históricas por categoría.',
                  )
                else
                  _CategoryRadar(analytics: analytics),
              ],
            ),
          ),
          const Divider(height: 1, color: _line),
          Material(
            color: Colors.white,
            child: ExpansionTile(
              key: const ValueKey('monthly-demand-accordion'),
              leading: const Icon(Icons.show_chart_rounded, color: _green),
              title: const Text('Demanda histórica por mes'),
              subtitle: const Text('Evolución mensual registrada'),
              childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              children: [
                if (analytics.monthlyDemand.isEmpty)
                  const _InsightEmpty(
                    message: 'No hay estadísticas históricas por mes.',
                  )
                else
                  _MonthlyDemandChart(months: analytics.monthlyDemand),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRadar extends StatelessWidget {
  const _CategoryRadar({required this.analytics});

  final LectioCategoryAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final period = analytics.periodStart != null && analytics.periodEnd != null
        ? 'Periodo histórico: ${analytics.periodStart} al ${analytics.periodEnd}'
        : 'Periodo histórico informado por LECTIO-AI';

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            period,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 300,
            width: double.infinity,
            child: Semantics(
              label:
                  'Gráfica radar de demanda histórica. ${analytics.categories.map((item) => '${item.category}: ${_formatDemand(item.demand)}').join('; ')}',
              child: analytics.categories.length < 3
                  ? const Center(
                      child: Text(
                        'Se necesitan al menos tres categorías para mostrar la gráfica radar.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _muted, fontSize: 12),
                      ),
                    )
                  : RadarChart(
                      RadarChartData(
                        dataSets: [
                          RadarDataSet(
                            dataEntries: analytics.categories
                                .map((item) => RadarEntry(value: item.demand))
                                .toList(growable: false),
                            fillColor: _greenBright.withValues(alpha: .18),
                            borderColor: _green,
                            borderWidth: 2,
                            entryRadius: 3,
                          ),
                        ],
                        radarBackgroundColor: Colors.transparent,
                        radarBorderData: const BorderSide(
                          color: _line,
                          width: 1,
                        ),
                        gridBorderData: const BorderSide(
                          color: _line,
                          width: 1,
                        ),
                        tickBorderData: const BorderSide(
                          color: _line,
                          width: 1,
                        ),
                        tickCount: 4,
                        ticksTextStyle: const TextStyle(
                          color: _muted,
                          fontSize: 9,
                        ),
                        titleTextStyle: const TextStyle(
                          color: _inkSoft,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        titlePositionPercentageOffset: .15,
                        getTitle: (index, angle) => RadarChartTitle(
                          text: analytics.categories[index].category,
                          angle: angle,
                        ),
                        radarTouchData: RadarTouchData(enabled: true),
                      ),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 9,
            runSpacing: 9,
            children: analytics.categories.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _paper,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _line),
                ),
                child: Text(
                  '${item.category} · ${_formatDemand(item.demand)}',
                  style: const TextStyle(
                    color: _inkSoft,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          const Text(
            'La gráfica compara la demanda histórica reportada por categoría; '
            'no representa una predicción futura.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 11, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _MonthlyDemandChart extends StatelessWidget {
  const _MonthlyDemandChart({required this.months});

  final List<MonthlyDemand> months;

  @override
  Widget build(BuildContext context) {
    final orderedMonths = [...months]
      ..sort((a, b) => a.month.compareTo(b.month));
    final values = orderedMonths
        .map((item) => '${item.month}: ${_formatDemand(item.demand)}')
        .join('; ');
    final maxDemand = orderedMonths
        .map((item) => item.demand)
        .reduce((a, b) => math.max(a, b).toDouble());
    final chartMaxY = maxDemand == 0 ? 1.0 : maxDemand * 1.15;
    final labelInterval = math.max(1, (orderedMonths.length / 4).ceil());

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Text(
            'Demanda registrada por mes',
            style: TextStyle(
              color: _inkSoft,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 230,
            width: double.infinity,
            child: Semantics(
              label: 'Gráfica de demanda histórica mensual: $values',
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: math.max(1, orderedMonths.length - 1).toDouble(),
                  minY: 0,
                  maxY: chartMaxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: chartMaxY / 4,
                    getDrawingHorizontalLine: (_) =>
                        const FlLine(color: _line, strokeWidth: 1),
                  ),
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
                        interval: chartMaxY / 4,
                        getTitlesWidget: (value, meta) => SideTitleWidget(
                          meta: meta,
                          child: Text(
                            _formatDemand(value),
                            style: const TextStyle(color: _muted, fontSize: 9),
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: labelInterval.toDouble(),
                        getTitlesWidget: (value, meta) {
                          final index = value.round();
                          if (index < 0 ||
                              index >= orderedMonths.length ||
                              (index != orderedMonths.length - 1 &&
                                  index % labelInterval != 0)) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            meta: meta,
                            space: 6,
                            child: Text(
                              _shortMonth(orderedMonths[index].month),
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 9,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: const Border(
                      bottom: BorderSide(color: _line),
                      left: BorderSide(color: _line),
                    ),
                  ),
                  lineTouchData: const LineTouchData(enabled: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (
                          var index = 0;
                          index < orderedMonths.length;
                          index++
                        )
                          FlSpot(index.toDouble(), orderedMonths[index].demand),
                      ],
                      color: _green,
                      barWidth: 2.5,
                      isCurved: true,
                      isStrokeCapRound: true,
                      isStrokeJoinRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: _greenBright.withValues(alpha: .12),
                      ),
                    ),
                  ],
                ),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
            ),
          ),
          const Text(
            'Los valores muestran la demanda histórica reportada cada mes.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 11, height: 1.4),
          ),
        ],
      ),
    );
  }
}

String _shortMonth(String value) {
  final parts = value.split('-');
  if (parts.length != 2) return value;
  return '${parts[1]}/${parts[0].substring(parts[0].length - 2)}';
}

class _InsightLoading extends StatelessWidget {
  const _InsightLoading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: _green),
          ),
          const SizedBox(width: 14),
          Text(label, style: const TextStyle(color: _muted)),
        ],
      ),
    );
  }
}

class _InsightError extends StatelessWidget {
  const _InsightError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF0D5D5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFFC8464A)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: _inkSoft, height: 1.4),
            ),
          ),
          IconButton(
            tooltip: 'Reintentar',
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            color: _green,
          ),
        ],
      ),
    );
  }
}

class _InsightEmpty extends StatelessWidget {
  const _InsightEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.hourglass_empty_rounded, color: _muted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: _inkSoft, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

String _errorMessage(Object? error, String fallback) {
  if (error is LectioAiException) return error.message;
  return fallback;
}

String _formatDemand(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
}
