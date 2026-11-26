import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/lectio_ai_service.dart';
import 'lectio_prediction_explorer.dart';

/// Prediction dashboard for signed-in readers. Reservation book data comes
/// from the prediction API and is intentionally independent of local ebooks.
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
    _predictionsFuture = _dataSource.loadPredictions();
    _analyticsFuture = _dataSource.loadCategoryAnalytics();
  }

  @override
  void dispose() {
    _ownedService?.close();
    super.dispose();
  }

  void _retry() => setState(() {
    _predictionsFuture = _dataSource.loadPredictions();
  });

  void _retryAnalytics() => setState(() {
    _analyticsFuture = _dataSource.loadCategoryAnalytics();
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Demanda de reservas',
                style: GoogleFonts.instrumentSerif(
                  fontSize: 34,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Consulta los libros m\u00e1s solicitados y explora su historial y estimaci\u00f3n.',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: colors.onSurfaceVariant, height: 1.45),
              ),
              const SizedBox(height: 22),
              FutureBuilder<LectioPredictions>(
                future: _predictionsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const _DashboardMessage(
                      icon: Icons.auto_graph_rounded,
                      message: 'Cargando datos de reservas...',
                      loading: true,
                    );
                  }
                  if (snapshot.hasError) {
                    return _DashboardMessage(
                      icon: Icons.wifi_off_rounded,
                      message: snapshot.error is LectioAiException
                          ? (snapshot.error as LectioAiException).message
                          : 'No se pudieron cargar las predicciones.',
                      onRetry: _retry,
                    );
                  }

                  final books = snapshot.data!.availableBooks;
                  if (books.isEmpty) {
                    return const _DashboardMessage(
                      icon: Icons.menu_book_outlined,
                      message: 'Todav\u00eda no hay predicciones disponibles para los libros de reservas.',
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TopBooksList(books: books),
                      const SizedBox(height: 20),
                      LectioPredictionExplorer(books: books),
                    ],
                  );
                },
              ),
              const SizedBox(height: 30),
              FutureBuilder<LectioCategoryAnalytics>(
                future: _analyticsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const _DashboardMessage(
                      icon: Icons.bar_chart_rounded,
                      message: 'Cargando demanda histórica',
                      loading: true,
                    );
                  }
                  if (snapshot.hasError) {
                    return _DashboardMessage(
                      icon: Icons.query_stats_rounded,
                      message: snapshot.error is LectioAiException
                          ? (snapshot.error as LectioAiException).message
                          : 'No se pudo cargar la demanda histórica.',
                      onRetry: _retryAnalytics,
                    );
                  }
                  final analytics = snapshot.data!;
                  if (analytics.categories.isEmpty &&
                      analytics.monthlyDemand.isEmpty) {
                    return const _DashboardMessage(
                      icon: Icons.bar_chart_rounded,
                      message:
                          'No hay datos históricos mensuales o por categoría.',
                    );
                  }
                  return _HistoricalAnalyticsCharts(analytics: analytics);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LectioPredictionsPage extends StatelessWidget {
  const LectioPredictionsPage({super.key, this.dataSource});

  final LectioAiDataSource? dataSource;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: Text(
          'Predicciones',
          style: GoogleFonts.instrumentSerif(fontSize: 27),
        ),
        backgroundColor: colors.surface,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: LectioAiInsights(dataSource: dataSource),
        ),
      ),
    );
  }
}

class _TopBooksList extends StatelessWidget {
  const _TopBooksList({required this.books});

  final List<LectioPrediction> books;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final topBooks = books.where((book) => book.demand30Days != null).toList()
      ..sort((a, b) => b.demand30Days!.compareTo(a.demand30Days!));
    final visibleBooks = topBooks.take(5).toList(growable: false);

    return Container(
      padding: const EdgeInsets.fromLTRB(17, 17, 17, 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Top 5 libros con mayor demanda prevista',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 3),
          Text(
            'Reservas estimadas para los pr\u00f3ximos 30 d\u00edas',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 8),
          for (var i = 0; i < visibleBooks.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                color: colors.outlineVariant.withValues(alpha: .6),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 30,
                    child: Text(
                      '#${i + 1}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          topBooks[i].title?.trim().isNotEmpty == true
                              ? topBooks[i].title!
                              : 'T\u00edtulo no disponible',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (topBooks[i].category?.trim().isNotEmpty == true)
                          Text(
                            topBooks[i].category!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_format(topBooks[i].demand30Days!)} / 30 d\u00edas',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HistoricalAnalyticsCharts extends StatelessWidget {
  const _HistoricalAnalyticsCharts({required this.analytics});

  final LectioCategoryAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final months = [...analytics.monthlyDemand]
      ..sort((a, b) => a.month.compareTo(b.month));
    final categories = [...analytics.categories]
      ..sort((a, b) => b.demand.compareTo(a.demand));
    final period = analytics.periodStart != null && analytics.periodEnd != null
        ? 'Periodo: ${analytics.periodStart} al ${analytics.periodEnd}'
        : 'Reservas registradas en el periodo disponible';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Demanda histórica',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          period,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 14),
        if (months.isNotEmpty)
          _DemandBarChart(
            title: 'Demanda mensual',
            subtitle: 'Reservas registradas por mes para todos los libros',
            labels: months.map((item) => _monthLabel(item.month)).toList(),
            values: months.map((item) => item.demand).toList(),
            semanticLabel: 'Demanda mensual hist\u00f3rica',
          ),
        if (months.isNotEmpty && categories.isNotEmpty)
          const SizedBox(height: 14),
        if (categories.isNotEmpty) _CategoryRadarChart(categories: categories),
      ],
    );
  }
}

class _CategoryRadarChart extends StatefulWidget {
  const _CategoryRadarChart({required this.categories});

  final List<CategoryDemand> categories;

  @override
  State<_CategoryRadarChart> createState() => _CategoryRadarChartState();
}

class _CategoryRadarChartState extends State<_CategoryRadarChart> {
  int? _selectedCategoryIndex;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final categories = widget.categories;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Demanda por categor\u00eda',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            'Toca un punto del radar para consultar esa categor\u00eda',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          if (categories.length >= 3)
            SizedBox(
              height: 280,
              child: Semantics(
                label:
                    'Demanda hist\u00f3rica por categor\u00eda: ${categories.map((e) => '${e.category}, ${_format(e.demand)} reservas').join('; ')}',
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: .82, end: 1),
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 900),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) => Opacity(
                    opacity: scale.clamp(0.0, 1.0),
                    child: Transform.scale(scale: scale, child: child),
                  ),
                  child: RadarChart(
                    RadarChartData(
                      radarShape: RadarShape.polygon,
                      tickCount: 4,
                      ticksTextStyle: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 9,
                      ),
                      tickBorderData: BorderSide(
                        color: colors.outlineVariant.withValues(alpha: .5),
                      ),
                      gridBorderData: BorderSide(color: colors.outlineVariant),
                      radarBorderData: BorderSide(color: colors.outlineVariant),
                      titleTextStyle: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 10,
                      ),
                      titlePositionPercentageOffset: .18,
                      getTitle: (index, _) => RadarChartTitle(
                        text: categories[index].category,
                        positionPercentageOffset: .18,
                      ),
                      dataSets: [
                        RadarDataSet(
                          dataEntries: [
                            for (final item in categories)
                              RadarEntry(value: item.demand),
                          ],
                          borderColor: colors.primary,
                          fillColor: colors.primary.withValues(alpha: .2),
                          borderWidth: 2.5,
                          entryRadius: 4,
                        ),
                      ],
                      radarTouchData: RadarTouchData(
                        enabled: true,
                        touchCallback: (event, response) {
                          final index =
                              response?.touchedSpot?.touchedRadarEntryIndex;
                          if (index != null &&
                              index != _selectedCategoryIndex) {
                            setState(() => _selectedCategoryIndex = index);
                          }
                        },
                      ),
                    ),
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 850),
                    curve: Curves.easeOutCubic,
                  ),
                ),
              ),
            )
          else
            Text(
              'Se necesitan al menos tres categor\u00edas para construir el gr\u00e1fico de radar. Hay ${categories.length} disponibles.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
          if (_selectedCategoryIndex case final selectedIndex?)
            Padding(
              padding: const EdgeInsets.only(top: 5, bottom: 7),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Container(
                  key: ValueKey(selectedIndex),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withValues(alpha: .55),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${categories[selectedIndex].category}: ${_format(categories[selectedIndex].demand)} reservas registradas',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          for (var index = 0; index < categories.length; index++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: index == _selectedCategoryIndex
                      ? colors.primaryContainer.withValues(alpha: .45)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(child: Text(categories[index].category)),
                    Text(
                      '${_format(categories[index].demand)} reservas',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DemandBarChart extends StatelessWidget {
  const _DemandBarChart({
    required this.title,
    required this.subtitle,
    required this.labels,
    required this.values,
    required this.semanticLabel,
  });

  final String title;
  final String subtitle;
  final List<String> labels;
  final List<double> values;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final maxValue = values.reduce((a, b) => math.max(a, b).toDouble());
    final maxY = maxValue == 0 ? 1.0 : maxValue * 1.18;
    final interval = maxY / 4;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 225,
            child: Semantics(
              label:
                  '$semanticLabel: ${labels.asMap().entries.map((e) => '${e.value}, ${_format(values[e.key])} reservas').join('; ')}',
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: maxY,
                  alignment: BarChartAlignment.spaceAround,
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
                            _format(value),
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
                        reservedSize: 32,
                        interval: _labelStride(labels).toDouble(),
                        getTitlesWidget: (value, meta) {
                          final index = value.round();
                          final stride = _labelStride(labels);
                          if (index < 0 ||
                              index >= labels.length ||
                              (index % stride != 0 &&
                                  index != labels.length - 1)) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              labels[index],
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 9,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                          BarTooltipItem(
                            '${labels[groupIndex]}\n${_format(values[groupIndex])} reservas',
                            TextStyle(color: colors.onPrimary),
                          ),
                    ),
                  ),
                  barGroups: [
                    for (var index = 0; index < values.length; index++)
                      BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: values[index],
                            color: index == 0
                                ? colors.primary
                                : colors.tertiary,
                            width: math.min(24, 200 / values.length),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(5),
                            ),
                          ),
                        ],
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
        ],
      ),
    );
  }
}

String _monthLabel(String month) {
  final parts = month.split('-');
  if (parts.length != 2) return month;
  final monthNumber = int.tryParse(parts[1]);
  const monthNames = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];
  if (monthNumber == null || monthNumber < 1 || monthNumber > 12) return month;
  return '${monthNames[monthNumber - 1]}\n${parts[0]}';
}

int _labelStride(List<String> labels) =>
    math.max(1, (labels.length / 6).ceil());

class _DashboardMessage extends StatelessWidget {
  const _DashboardMessage({
    required this.icon,
    required this.message,
    this.loading = false,
    this.onRetry,
  });

  final IconData icon;
  final String message;
  final bool loading;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          if (loading)
            const CircularProgressIndicator()
          else
            Icon(icon, size: 30, color: colors.primary),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ],
      ),
    );
  }
}

String _format(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
