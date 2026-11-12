import 'dart:convert';

import 'package:app/features/auth/data/lectio_auth_service.dart';
import 'package:app/features/virtual_books/data/libros_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test(
    'loads and parses virtual books from the authenticated Thymeleaf page',
    () async {
      final client = _FakeClient(
        statusCode: 200,
        body: '''
        <main id="booksGrid">
          <div class="book-card" data-category="Fantasía">
            <div class="card-content">
              <span class="category">Fantasía</span>
              <h3>El principito</h3>
              <p class="author">Antoine de Saint-Exupéry</p>
              <p class="desc">Una historia para lectores de todas las edades.</p>
              <a class="read-btn" href="https://example.test/libro">Leer</a>
            </div>
          </div>
        </main>
      ''',
      );
      final service = LibrosVirtualesService(
        session: const AuthSession(
          username: 'lector',
          cookie: 'JSESSIONID=abc123',
        ),
        client: client,
        backendUri: Uri.parse('https://example.test'),
      );

      final books = await service.loadBooks();

      expect(client.lastRequest.url.path, '/api/libroVirtualesLog');
      expect(client.lastRequest.headers['cookie'], 'JSESSIONID=abc123');
      expect(books, hasLength(1));
      expect(books.single.titulo, 'El principito');
      expect(books.single.categoria, 'Fantasía');
      expect(books.single.autor, 'Antoine de Saint-Exupéry');
      expect(
        books.single.descripcion,
        'Una historia para lectores de todas las edades.',
      );
      expect(books.single.url, Uri.parse('https://example.test/libro'));
      service.close();
    },
  );

  test(
    'reports an expired session instead of treating login as an empty catalog',
    () async {
      final client = _FakeClient(
        statusCode: 302,
        body: '',
        headers: {'location': '/login'},
      );
      final service = LibrosVirtualesService(
        session: const AuthSession(
          username: 'lector',
          cookie: 'JSESSIONID=old',
        ),
        client: client,
        backendUri: Uri.parse('https://example.test'),
      );

      await expectLater(
        service.loadBooks(),
        throwsA(
          isA<LibrosVirtualesException>().having(
            (error) => error.message,
            'message',
            contains('redirigió al inicio de sesión'),
          ),
        ),
      );
      service.close();
    },
  );

  test(
    'rejects a response that does not contain the virtual books grid',
    () async {
      final client = _FakeClient(
        statusCode: 200,
        body: '<html><body><form action="/login"></form></body></html>',
      );
      final service = LibrosVirtualesService(
        session: const AuthSession(
          username: 'lector',
          cookie: 'JSESSIONID=old',
        ),
        client: client,
        backendUri: Uri.parse('https://example.test'),
      );

      await expectLater(
        service.loadBooks(),
        throwsA(isA<LibrosVirtualesException>()),
      );
      service.close();
    },
  );

  test('rejects books with unsupported read URLs', () async {
    final client = _FakeClient(
      statusCode: 200,
      body: '''
        <main id="booksGrid">
          <div class="book-card">
            <span class="category">Novelas</span>
            <h3>Libro de prueba</h3>
            <a class="read-btn" href="javascript:alert(1)">Leer</a>
          </div>
        </main>
      ''',
    );
    final service = LibrosVirtualesService(
      session: const AuthSession(username: 'lector', cookie: 'JSESSIONID=test'),
      client: client,
      backendUri: Uri.parse('https://example.test'),
    );

    await expectLater(
      service.loadBooks(),
      throwsA(isA<LibrosVirtualesException>()),
    );
    service.close();
  });
}

class _FakeClient extends http.BaseClient {
  _FakeClient({
    required this.statusCode,
    required this.body,
    this.headers = const {},
  });

  final int statusCode;
  final String body;
  final Map<String, String> headers;
  late http.Request lastRequest;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastRequest = request as http.Request;
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      statusCode,
      headers: {'content-type': 'text/html; charset=utf-8', ...headers},
    );
  }
}
