import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

const _lectioAiBaseUrl = 'https://lectio-ai-production.up.railway.app';

class LectioAiException implements Exception {
  const LectioAiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LectioPrediction {
  const LectioPrediction({
    required this.bookId,
    required this.title,
    required this.category,
    required this.status,
    required this.demand30Days,
    this.weeklyHistory = const [],
    this.weeklyForecast = const [],
    this.historicalDemand,
  });

  factory LectioPrediction.fromJson(Map<String, dynamic> json) {
    final bookId = json['book_id'];
    if (bookId is! String || bookId.trim().isEmpty) {
      throw const LectioAiException(
        'LECTIO-AI devolvió una predicción sin identificador de libro.',
      );
    }

    return LectioPrediction(
      bookId: bookId,
      title: _optionalString(json['titulo']),
      category: _optionalString(json['category']),
      status: _optionalString(json['status']),
      demand30Days: _optionalNumber(json['forecast_demand_30_days']),
      weeklyHistory: _parseWeeklyHistory(json['weekly_history']),
      weeklyForecast: _parseWeeklyForecast(json['weekly_forecast']),
      historicalDemand: _optionalNumber(json['historical_demand']),
    );
  }

  final String bookId;
  final String? title;
  final String? category;
  final String? status;
  final double? demand30Days;
  final List<WeeklyDemand> weeklyHistory;
  final List<WeeklyForecast> weeklyForecast;
  final double? historicalDemand;

  bool get isAvailable =>
      status == 'PREDICCION_DISPONIBLE' &&
      demand30Days != null &&
      demand30Days!.isFinite &&
      demand30Days! >= 0;
}

class WeeklyDemand {
  const WeeklyDemand({required this.periodStart, required this.demand});

  final String periodStart;
  final double demand;
}

class WeeklyForecast {
  const WeeklyForecast({
    required this.periodStart,
    required this.daysCovered,
    required this.predictedDemand,
  });

  final String periodStart;
  final int? daysCovered;
  final double predictedDemand;
}

List<WeeklyDemand> _parseWeeklyHistory(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map<String, dynamic>>()
      .map((item) {
        return WeeklyDemand(
          periodStart: _optionalString(item['period_start']) ?? '',
          demand: _optionalNumber(item['demand']) ?? double.nan,
        );
      })
      .where(
        (item) =>
            item.periodStart.isNotEmpty &&
            item.demand.isFinite &&
            item.demand >= 0,
      )
      .toList(growable: false);
}

List<WeeklyForecast> _parseWeeklyForecast(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map<String, dynamic>>()
      .map((item) {
        final rawDays = item['days_covered'];
        return WeeklyForecast(
          periodStart: _optionalString(item['period_start']) ?? '',
          daysCovered: rawDays is num ? rawDays.toInt() : null,
          predictedDemand:
              _optionalNumber(item['predicted_demand']) ?? double.nan,
        );
      })
      .where(
        (item) =>
            item.periodStart.isNotEmpty &&
            item.predictedDemand.isFinite &&
            item.predictedDemand >= 0 &&
            (item.daysCovered == null || item.daysCovered! > 0),
      )
      .toList(growable: false);
}

class LectioPredictions {
  const LectioPredictions({required this.horizonDays, required this.books});

  factory LectioPredictions.fromJson(Map<String, dynamic> json) {
    final rawBooks = json['books'];
    if (rawBooks is! List) {
      throw const LectioAiException(
        'LECTIO-AI devolvió un formato inesperado para las predicciones.',
      );
    }
    final rawHorizon = json['horizon_days'];
    return LectioPredictions(
      horizonDays: rawHorizon is num ? rawHorizon.toInt() : null,
      books: rawBooks
          .map((rawBook) {
            if (rawBook is! Map<String, dynamic>) {
              throw const LectioAiException(
                'LECTIO-AI devolvió una predicción con formato inválido.',
              );
            }
            return LectioPrediction.fromJson(rawBook);
          })
          .toList(growable: false),
    );
  }

  final int? horizonDays;
  final List<LectioPrediction> books;

  List<LectioPrediction> get availableBooks {
    final available = books.where((book) => book.isAvailable).toList();
    available.sort((a, b) => b.demand30Days!.compareTo(a.demand30Days!));
    return available;
  }
}

class CategoryDemand {
  const CategoryDemand({required this.category, required this.demand});

  final String category;
  final double demand;
}

class MonthlyDemand {
  const MonthlyDemand({required this.month, required this.demand});

  final String month;
  final double demand;
}

class LectioCategoryAnalytics {
  const LectioCategoryAnalytics({
    required this.categories,
    required this.monthlyDemand,
    required this.periodStart,
    required this.periodEnd,
  });

  factory LectioCategoryAnalytics.fromJson(Map<String, dynamic> json) {
    final analytics = json['analytics'];
    if (analytics is! Map<String, dynamic>) {
      throw const LectioAiException(
        'LECTIO-AI devolvió un formato inesperado para las tendencias.',
      );
    }
    final rawCategories = analytics['demand_by_category'];
    final categories = <CategoryDemand>[];
    if (rawCategories is List) {
      for (final rawCategory in rawCategories) {
        if (rawCategory is! Map<String, dynamic>) continue;
        final category = _optionalString(rawCategory['category']);
        final demand = _optionalNumber(rawCategory['demand']);
        if (category == null ||
            category.isEmpty ||
            demand == null ||
            !demand.isFinite ||
            demand < 0) {
          continue;
        }
        categories.add(CategoryDemand(category: category, demand: demand));
      }
    }

    final rawMonthlyDemand = analytics['monthly_demand'];
    final monthlyDemand = <MonthlyDemand>[];
    if (rawMonthlyDemand is List) {
      for (final rawMonth in rawMonthlyDemand) {
        if (rawMonth is! Map<String, dynamic>) continue;
        final month = _optionalString(rawMonth['month']);
        final demand = _optionalNumber(rawMonth['demand']);
        if (month == null ||
            month.isEmpty ||
            demand == null ||
            !demand.isFinite ||
            demand < 0) {
          continue;
        }
        monthlyDemand.add(MonthlyDemand(month: month, demand: demand));
      }
    }

    return LectioCategoryAnalytics(
      categories: categories,
      monthlyDemand: monthlyDemand,
      periodStart: _optionalString(analytics['period_start']),
      periodEnd: _optionalString(analytics['period_end']),
    );
  }

  final List<CategoryDemand> categories;
  final List<MonthlyDemand> monthlyDemand;
  final String? periodStart;
  final String? periodEnd;
}

class LectioInventoryRecommendation {
  const LectioInventoryRecommendation({
    required this.bookId,
    required this.category,
    required this.risk,
    required this.suggestedUnits,
    this.title,
    this.demand30Days,
    this.availableStock,
    this.reservedUnits,
  });

  factory LectioInventoryRecommendation.fromJson(Map<String, dynamic> json) {
    Object? first(Iterable<String> keys) {
      for (final key in keys) {
        if (json[key] != null) return json[key];
      }
      return null;
    }

    final id = first(const [
      'book_id',
      'libro_id',
      'id_book',
      'libro_fisico_id',
      'id',
    ]);
    final suggested = _optionalNumber(
      first(const [
        'recommended_replenishment',
        'recommended_restock',
        'restock_quantity',
        'reorder_quantity',
        'units_to_restock',
        'replenishment',
        'reorder',
        'suggested_quantity',
      ]),
    );
    return LectioInventoryRecommendation(
      bookId: id?.toString() ?? '',
      title: _optionalString(
        first(const [
          'titulo',
          'title',
          'libro',
          'book_title',
          'book_name',
          'nombre_libro',
          'name',
        ]),
      ),
      category: _optionalString(first(const ['category', 'categoria'])),
      demand30Days: _optionalNumber(
        first(const [
          'forecast_demand_30_days',
          'predicted_demand',
          'estimated_demand',
          'demand_30d',
          'forecast',
          'predicted_value',
          'demand',
        ]),
      ),
      availableStock: _optionalNumber(
        first(const [
          'available_stock',
          'stock_available',
          'stock',
          'available',
        ]),
      ),
      reservedUnits: _optionalNumber(
        first(const [
          'reserved',
          'reserved_stock',
          'reservadas',
          'reserved_units',
        ]),
      ),
      risk: _optionalString(
        first(const ['risk_level', 'risk', 'riesgo', 'status']),
      ),
      suggestedUnits: suggested != null && suggested.isFinite && suggested > 0
          ? suggested
          : 0,
    );
  }

  final String bookId;
  final String? title;
  final String? category;
  final double? demand30Days;
  final double? availableStock;
  final double? reservedUnits;
  final String? risk;
  final double suggestedUnits;
}

class LectioRecommendations {
  const LectioRecommendations({required this.items});

  factory LectioRecommendations.fromJson(Map<String, dynamic> json) {
    Object? raw =
        json['recommendations'] ??
        json['items'] ??
        json['results'] ??
        json['data'];
    if (raw is Map<String, dynamic>) {
      raw = raw['recommendations'] ?? raw['items'] ?? raw['results'];
    }
    if (raw is! List) {
      throw const LectioAiException(
        'LECTIO-AI devolvió un formato inesperado para las recomendaciones.',
      );
    }
    return LectioRecommendations(
      items: raw
          .whereType<Map<String, dynamic>>()
          .map(LectioInventoryRecommendation.fromJson)
          .where((item) => item.bookId.trim().isNotEmpty)
          .toList(growable: false),
    );
  }

  final List<LectioInventoryRecommendation> items;
}

abstract interface class LectioAiDataSource {
  Future<LectioPredictions> loadPredictions();

  Future<LectioCategoryAnalytics> loadCategoryAnalytics();

  Future<LectioRecommendations> loadRecommendations();
}

class LectioAiService implements LectioAiDataSource {
  LectioAiService({http.Client? client, Uri? baseUri})
    : _client = client ?? http.Client(),
      _baseUri = baseUri ?? Uri.parse(_lectioAiBaseUrl),
      _ownsClient = client == null;

  final http.Client _client;
  final Uri _baseUri;
  final bool _ownsClient;

  @override
  Future<LectioPredictions> loadPredictions() async {
    final response = await _get('/predictions', 'las predicciones');
    final json = _decodeObject(response.body, 'las predicciones');
    return LectioPredictions.fromJson(json);
  }

  @override
  Future<LectioCategoryAnalytics> loadCategoryAnalytics() async {
    final response = await _get('/analytics', 'las tendencias');
    final json = _decodeObject(response.body, 'las tendencias');
    return LectioCategoryAnalytics.fromJson(json);
  }

  @override
  Future<LectioRecommendations> loadRecommendations() async {
    final response = await _get(
      '/recommendations?limit=200',
      'las recomendaciones de inventario',
    );
    final json = _decodeObject(response.body, 'las recomendaciones');
    return LectioRecommendations.fromJson(json);
  }

  Future<http.Response> _get(String path, String dataName) async {
    try {
      final response = await _client
          .get(
            _baseUri.resolve(path),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      }
      if (path == '/analytics' && response.statusCode == 503) {
        throw const LectioAiException(
          'Las tendencias por categoría no están disponibles por ahora. '
          'El catálogo y las predicciones siguen funcionando.',
        );
      }
      throw LectioAiException(
        'No se pudieron cargar $dataName de LECTIO-AI '
        '(HTTP ${response.statusCode}).',
      );
    } on LectioAiException {
      rethrow;
    } on TimeoutException {
      throw LectioAiException(
        'LECTIO-AI tardó demasiado en responder al solicitar $dataName.',
      );
    } on http.ClientException catch (error) {
      throw LectioAiException(
        'No se pudo conectar con LECTIO-AI: ${error.message}',
      );
    }
  }

  Map<String, dynamic> _decodeObject(String body, String dataName) {
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      throw LectioAiException(
        'LECTIO-AI devolvió una respuesta inválida para $dataName.',
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw LectioAiException(
        'LECTIO-AI devolvió un formato inesperado para $dataName.',
      );
    }
    return decoded;
  }

  void close() {
    if (_ownsClient) _client.close();
  }
}

String? _optionalString(Object? value) {
  if (value == null) return null;
  if (value is String) return value;
  return value is num ? value.toString() : null;
}

double? _optionalNumber(Object? value) =>
    value is num ? value.toDouble() : null;
