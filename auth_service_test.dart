import 'dart:convert';

import 'package:app/features/auth/data/lectio_auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test(
    'login posts form fields and returns the Spring session cookie',
    () async {
      final client = _FakeClient(
        statusCode: 302,
        headers: {
          'location': '/api/home',
          'set-cookie': 'JSESSIONID=abc123; Path=/; HttpOnly',
        },
      );
      final service = LectioAuthService(
        client: client,
        backendUri: Uri.parse('https://example.test'),
      );
      addTearDown(service.close);

      final session = await service.login(
        username: ' reader ',
        password: 'secret',
      );

      expect(session.username, 'reader');
      expect(session.cookie, 'JSESSIONID=abc123');
      expect(client.lastRequest.url.path, '/api/login');
      expect(client.lastRequest.bodyFields, {
        'username': 'reader',
        'password': 'secret',
      });
      expect(client.lastRequest.followRedirects, isFalse);
      expect(
        client.lastRequest.headers['content-type'],
        startsWith('application/x-www-form-urlencoded'),
      );
    },
  );

  test('registration accepts the backend success redirect', () async {
    final client = _FakeClient(
      statusCode: 302,
      headers: {'location': '/api/login?success=true'},
    );
    final service = LectioAuthService(
      client: client,
      backendUri: Uri.parse('https://example.test'),
    );
    addTearDown(service.close);

    await expectLater(
      service.register(username: 'reader', password: 'secret1'),
      completes,
    );
    expect(client.lastRequest.url.path, '/api/register');
  });

  test('registration reports a duplicate username from the backend', () async {
    final client = _FakeClient(
      statusCode: 302,
      headers: {'location': '/api/register?error=Username+already+exists'},
    );
    final service = LectioAuthService(
      client: client,
      backendUri: Uri.parse('https://example.test'),
    );
    addTearDown(service.close);

    await expectLater(
      service.register(username: 'reader', password: 'secret1'),
      throwsA(
        isA<AuthException>().having(
          (error) => error.message,
          'message',
          'Ese nombre de usuario ya está registrado.',
        ),
      ),
    );
  });

  for (final loginPath in ['/api/login?error', '/login?error']) {
    test('login rejects a redirect to $loginPath', () async {
      final client = _FakeClient(
        statusCode: 302,
        headers: {'location': loginPath},
      );
      final service = LectioAuthService(
        client: client,
        backendUri: Uri.parse('https://example.test'),
      );
      addTearDown(service.close);

      await expectLater(
        service.login(username: 'reader', password: 'wrong'),
        throwsA(isA<InvalidCredentialsException>()),
      );
    });
  }

  test(
    'login does not report success when no session cookie is returned',
    () async {
      final client = _FakeClient(
        statusCode: 302,
        headers: {'location': '/api/home'},
      );
      final service = LectioAuthService(
        client: client,
        backendUri: Uri.parse('https://example.test'),
      );
      addTearDown(service.close);

      await expectLater(
        service.login(username: 'reader', password: 'secret'),
        throwsA(isA<AuthException>()),
      );
    },
  );

  test('logout posts the authenticated session cookie', () async {
    final client = _FakeClient(statusCode: 302, headers: {});
    final service = LectioAuthService(
      client: client,
      backendUri: Uri.parse('https://example.test'),
    );
    addTearDown(service.close);

    await service.logout(
      session: const AuthSession(
        username: 'reader',
        cookie: 'JSESSIONID=abc123',
      ),
    );

    expect(client.lastRequest.url.path, '/api/logout');
    expect(client.lastRequest.method, 'POST');
    expect(client.lastRequest.headers['cookie'], 'JSESSIONID=abc123');
    expect(client.lastRequest.followRedirects, isFalse);
  });
}

class _FakeClient extends http.BaseClient {
  _FakeClient({required this.statusCode, required this.headers});

  final int statusCode;
  final Map<String, String> headers;
  late http.Request lastRequest;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastRequest = request as http.Request;
    return http.StreamedResponse(
      Stream.value(utf8.encode('')),
      statusCode,
      headers: headers,
    );
  }
}
