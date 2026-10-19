import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'auth_http_client.dart';

const _defaultBackendUri = 'https://lectio-biblioteca.onrender.com';

class AuthSession {
  const AuthSession({required this.username, required this.cookie});

  final String username;
  final String cookie;
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LectioAuthService {
  LectioAuthService({http.Client? client, Uri? backendUri})
    : _client = client ?? createAuthHttpClient(),
      _backendUri = backendUri ?? Uri.parse(_defaultBackendUri);

  final http.Client _client;
  final Uri _backendUri;

  Future<void> register({
    required String username,
    required String password,
  }) async {
    final response = await _postForm('/api/register', {
      'username': username.trim(),
      'password': password,
    });
    final location = _redirectLocation(response);
    if (location == null) {
      throw AuthException(
        'El servidor no confirmó el registro. Inténtalo de nuevo.',
      );
    }

    final error = location.queryParameters['error'];
    if (error != null) {
      throw AuthException(_registrationError(error));
    }
    if (location.path != '/api/login' ||
        location.queryParameters['success'] != 'true') {
      throw AuthException(
        'El servidor respondió con un destino de registro inesperado.',
      );
    }
  }

  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    final response = await _postForm('/api/login', {
      'username': username.trim(),
      'password': password,
    });
    final location = _redirectLocation(response);
    if (location == null) {
      throw AuthException(
        'El servidor no confirmó el inicio de sesión. Revisa tus datos e inténtalo de nuevo.',
      );
    }

    if (location.path == '/api/login' ||
        location.path == '/api/register' ||
        location.queryParameters.containsKey('error')) {
      throw const AuthException('Usuario o contraseña incorrectos.');
    }

    final cookie = _sessionCookie(response.headers['set-cookie']);
    if (!kIsWeb && cookie == null) {
      throw AuthException(
        'El servidor aceptó el acceso, pero no creó una sesión. Inténtalo de nuevo.',
      );
    }
    // Web browsers retain HttpOnly cookies but do not expose Set-Cookie to Dart.
    return AuthSession(username: username.trim(), cookie: cookie ?? '');
  }

  Future<http.Response> _postForm(
    String path,
    Map<String, String> fields,
  ) async {
    final request = http.Request('POST', _backendUri.resolve(path))
      ..followRedirects = false
      ..headers['Accept'] = 'text/html'
      ..bodyFields = fields;

    try {
      final streamedResponse = await _client
          .send(request)
          .timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode < 200 || response.statusCode >= 400) {
        throw AuthException(
          'El servidor no pudo completar la solicitud (${response.statusCode}).',
        );
      }
      return response;
    } on AuthException {
      rethrow;
    } on TimeoutException {
      throw const AuthException(
        'El servidor está tardando demasiado. Inténtalo de nuevo.',
      );
    } on http.ClientException catch (error) {
      if (kIsWeb) {
        throw const AuthException(
          'El navegador bloqueó la conexión. Para usar Flutter Web, el backend debe habilitar CORS y permitir credenciales para esta aplicación.',
        );
      }
      throw AuthException(
        'No se pudo conectar con el servidor de Lectio: ${error.message}',
      );
    }
  }

  Uri? _redirectLocation(http.Response response) {
    final rawLocation = response.headers['location'];
    if (rawLocation == null ||
        response.statusCode < 300 ||
        response.statusCode >= 400) {
      return null;
    }
    return _backendUri.resolve(rawLocation);
  }

  String? _sessionCookie(String? setCookie) {
    if (setCookie == null) return null;
    final cookies = RegExp(r'(?:^|,\s*)([^=;,\s]+)=([^;,\s]+)')
        .allMatches(setCookie);
    for (final match in cookies) {
      final name = match.group(1)!;
      if (name.toLowerCase() == 'jsessionid' ||
          name.toLowerCase() == 'session') {
        return '$name=${match.group(2)}';
      }
    }
    return null;
  }

  String _registrationError(String error) {
    final normalized = error.toLowerCase();
    if (normalized.contains('usuario') ||
        normalized.contains('existe') ||
        normalized.contains('exists')) {
      return 'Ese nombre de usuario ya está registrado.';
    }
    if (normalized.contains('contraseña') || normalized.contains('password')) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    return error;
  }

  void close() => _client.close();
}
