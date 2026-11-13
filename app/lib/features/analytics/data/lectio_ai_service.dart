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
    );
  }

  final String bookId;
  final String? title;
  final String? category;
  final String? status;
  final double? demand30Days;

  bool get isAvailable =>
      status == 'PREDICCION_DISPONIBLE' &&
      demand30Days != null &&
      demand30Days!.isFinite &&
      demand30Days! >= 0;
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

abstract interface class LectioAiDataSource {
  Future<LectioPredictions> loadPredictions();

  Future<LectioCategoryAnalytics> loadCategoryAnalytics();
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
