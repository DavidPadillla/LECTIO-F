import 'dart:convert';

import 'package:app/features/auth/data/lectio_auth_service.dart';
import 'package:app/features/reservations/data/reservas_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  const session = AuthSession(username: 'lector', cookie: 'JSESSIONID=abc123');

  test('loads physical books and sends the session cookie', () async {
    final client = _FakeClient(
      statusCode: 200,
      body: jsonEncode([
        {
          'id': 'book-1',
          'titulo': 'El libro',
          'autor': 'Una autora',
          'categoria': 'Novelas',
          'stock': 3,
        },
      ]),
    );
    final service = ReservasService(
      session: session,
      client: client,
      backendUri: Uri.parse('https://example.test'),
    );

    final books = await service.loadBooks();

    expect(books, hasLength(1));
    expect(books.single.id, 'book-1');
    expect(books.single.titulo, 'El libro');
    expect(books.single.autor, 'Una autora');
    expect(books.single.categoria, 'Novelas');
    expect(books.single.stock, 3);
    expect(client.lastRequest.url.path, '/api/cargarTodosLosLibros');
    expect(client.lastRequest.headers['cookie'], session.cookie);
    service.close();
  });

  test('loads books for the selected category', () async {
    final client = _FakeClient(statusCode: 200, body: '[]');
    final service = ReservasService(
      session: session,
      client: client,
      backendUri: Uri.parse('https://example.test'),
    );

    await service.loadBooks(category: 'Ciencia ficción');

    expect(client.lastRequest.url.path, '/api/cargarLibrosPorCategoria');
    expect(client.lastRequest.url.queryParameters, {
      'categoria': 'Ciencia ficción',
    });
    service.close();
  });

  test(
    'creates a reservation with backend form fields and session cookie',
    () async {
      final client = _FakeClient(
        statusCode: 200,
        body: jsonEncode({'success': true, 'mensaje': 'Reserva realizada'}),
      );
      final service = ReservasService(
        session: session,
        client: client,
        backendUri: Uri.parse('https://example.test'),
      );

      await service.createReservation(
        bookId: 'book-1',
        title: 'El libro',
        category: 'Novelas',
        fullName: 'Lector de Prueba',
        email: 'lector@example.com',
        date: '2026-11-12',
      );

      expect(client.lastRequest.url.path, '/api/guardarReservaUsuario');
      expect(client.lastRequest.method, 'POST');
      expect(client.lastRequest.headers['cookie'], session.cookie);
      expect(client.lastRequest.bodyFields, {
        'libroId': 'book-1',
        'libro': 'El libro',
        'categoria': 'Novelas',
        'nombreCompleto': 'Lector de Prueba',
        'correo': 'lector@example.com',
        'fecha': '2026-11-12',
      });
      service.close();
    },
  );

  test(
    'shows the backend reservation error when stock is unavailable',
    () async {
      final client = _FakeClient(
        statusCode: 409,
        body: jsonEncode({
          'success': false,
          'error': 'No hay stock suficiente',
        }),
      );
      final service = ReservasService(
        session: session,
        client: client,
        backendUri: Uri.parse('https://example.test'),
      );

      await expectLater(
        service.createReservation(
          bookId: 'book-1',
          title: 'El libro',
          category: 'Novelas',
          fullName: 'Lector de Prueba',
          email: 'lector@example.com',
          date: '2026-11-12',
        ),
        throwsA(
          isA<ReservaApiException>().having(
            (error) => error.message,
            'message',
            'No hay stock suficiente',
          ),
        ),
      );
      service.close();
    },
  );
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
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }
}
