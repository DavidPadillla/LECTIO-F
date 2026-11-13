import 'dart:convert';

import 'package:app/features/analytics/data/lectio_ai_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('loads available predictions and sorts by forecast demand', () async {
    final client = _FakeClient(
      statusCode: 200,
      body: jsonEncode({
        'data_type': 'datos_reales',
        'horizon_days': 30,
        'books': [
          {
            'book_id': 'low',
            'titulo': 'Demanda baja',
            'category': 'Novelas',
            'status': 'PREDICCION_DISPONIBLE',
            'forecast_demand_30_days': 1.25,
          },
          {
            'book_id': 'missing',
            'titulo': 'Sin estimación',
            'category': 'Ciencia',
            'status': 'DATOS_INSUFICIENTES',
            'forecast_demand_30_days': null,
          },
          {
            'book_id': 'high',
            'titulo': 'Demanda alta',
            'category': 'Arte',
            'status': 'PREDICCION_DISPONIBLE',
            'forecast_demand_30_days': 5.9,
          },
          {
            'book_id': 'null-forecast',
            'titulo': 'Sin valor',
            'category': 'Historia',
            'status': 'PREDICCION_DISPONIBLE',
            'forecast_demand_30_days': null,
          },
        ],
      }),
    );
    final service = LectioAiService(
      client: client,
      baseUri: Uri.parse('https://ai.example.test'),
    );

    final predictions = await service.loadPredictions();

    expect(client.lastRequest.url.path, '/predictions');
    expect(client.lastRequest.headers['accept'], 'application/json');
    expect(predictions.horizonDays, 30);
    expect(predictions.availableBooks.map((book) => book.bookId), [
      'high',
      'low',
    ]);
    expect(predictions.availableBooks.first.title, 'Demanda alta');
    expect(predictions.availableBooks.first.demand30Days, 5.9);
    service.close();
  });

  test('keeps category analytics when monthly history is absent', () async {
    final client = _FakeClient(
      statusCode: 200,
      body: jsonEncode({
        'analytics': {
          'demand_by_category': [
            {'category': 'Novelas', 'demand': 20},
          ],
        },
      }),
    );
    final service = LectioAiService(
      client: client,
      baseUri: Uri.parse('https://ai.example.test'),
    );

    final analytics = await service.loadCategoryAnalytics();

    expect(analytics.categories, hasLength(1));
    expect(analytics.monthlyDemand, isEmpty);
    service.close();
  });

  test('preserves a missing real title without inventing one', () async {
    final client = _FakeClient(
      statusCode: 200,
      body: jsonEncode({
        'books': [
          {
            'book_id': 'book-id',
            'titulo': null,
            'category': 'Ciencia',
            'status': 'PREDICCION_DISPONIBLE',
            'forecast_demand_30_days': 2,
          },
        ],
      }),
    );
    final service = LectioAiService(
      client: client,
      baseUri: Uri.parse('https://ai.example.test'),
    );

    final predictions = await service.loadPredictions();

    expect(predictions.availableBooks.single.bookId, 'book-id');
    expect(predictions.availableBooks.single.title, isNull);
    service.close();
  });

  test(
    'loads only the real category demand and its historical period',
    () async {
      final client = _FakeClient(
        statusCode: 200,
        body: jsonEncode({
          'data_type': 'datos_reales',
          'analytics': {
            'period_start': '2024-11-11',
            'period_end': '2026-11-09',
            'demand_by_category': [
              {'category': 'Novelas', 'demand': 532},
              {'category': 'Fantasía', 'demand': 486},
            ],
            'monthly_demand': [
              {'month': '2026-09', 'demand': 100},
              {'month': '2026-10', 'demand': 95},
            ],
          },
        }),
      );
      final service = LectioAiService(
        client: client,
        baseUri: Uri.parse('https://ai.example.test'),
      );

      final analytics = await service.loadCategoryAnalytics();

      expect(client.lastRequest.url.path, '/analytics');
      expect(analytics.categories.map((item) => item.category), [
        'Novelas',
        'Fantasía',
      ]);
      expect(analytics.categories.map((item) => item.demand), [532, 486]);
      expect(analytics.monthlyDemand.map((item) => item.month), [
        '2026-09',
        '2026-10',
      ]);
      expect(analytics.monthlyDemand.map((item) => item.demand), [100, 95]);
      expect(analytics.periodStart, '2024-11-11');
      expect(analytics.periodEnd, '2026-11-09');
      service.close();
    },
  );

  test(
    'reports 503 from analytics as an unavailable analytics result',
    () async {
      final client = _FakeClient(
        statusCode: 503,
        body: '{"detail":"not ready"}',
      );
      final service = LectioAiService(
        client: client,
        baseUri: Uri.parse('https://ai.example.test'),
      );

      await expectLater(
        service.loadCategoryAnalytics(),
        throwsA(
          isA<LectioAiException>().having(
            (error) => error.message,
            'message',
            contains('no están disponibles'),
          ),
        ),
      );
      service.close();
    },
  );

  test('returns an empty category list when analytics has none', () async {
    final client = _FakeClient(
      statusCode: 200,
      body: jsonEncode({
        'analytics': {'demand_by_category': [], 'monthly_demand': []},
      }),
    );
    final service = LectioAiService(
      client: client,
      baseUri: Uri.parse('https://ai.example.test'),
    );

    final analytics = await service.loadCategoryAnalytics();

    expect(analytics.categories, isEmpty);
    service.close();
  });
}

class _FakeClient extends http.BaseClient {
  _FakeClient({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
  late http.Request lastRequest;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastRequest = request as http.Request;
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      statusCode,
      headers: const {'content-type': 'application/json'},
    );
  }
}
