import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../auth/data/auth_http_client.dart';
import '../../auth/data/lectio_auth_service.dart';

const _defaultBackendUri = 'https://lectio-biblioteca.onrender.com';

class ReservaBook {
  const ReservaBook({
    required this.id,
    required this.titulo,
    required this.stock,
    this.autor = '',
    this.categoria = '',
  });

  factory ReservaBook.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['_id'];
    final titulo = json['titulo']?.toString().trim() ?? '';
    if (rawId == null || rawId.toString().trim().isEmpty || titulo.isEmpty) {
      throw const ReservaApiException(
        'El servidor devolvió un libro sin identificador o título.',
      );
    }

    final rawStock = json['stock'];
    final stock = rawStock is num
        ? rawStock.toInt()
        : int.tryParse(rawStock?.toString() ?? '') ?? 0;

    return ReservaBook(
      id: rawId.toString(),
      titulo: titulo,
      autor: json['autor']?.toString() ?? '',
      categoria: json['categoria']?.toString() ?? '',
      stock: stock,
    );
  }

  final String id;
  final String titulo;
  final String autor;
  final String categoria;
  final int stock;
}

class ReservaApiException implements Exception {
  const ReservaApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class ReservaDataSource {
  Future<List<ReservaBook>> loadBooks({String? category});

  Future<void> createReservation({
    required String bookId,
    required String title,
    required String category,
    required String fullName,
    required String email,
    required String date,
  });
}

class ReservasService implements ReservaDataSource {
  ReservasService({required this.session, http.Client? client, Uri? backendUri})
    : _client = client ?? createAuthHttpClient(),
      _backendUri = backendUri ?? Uri.parse(_defaultBackendUri),
      _ownsClient = client == null;

  final AuthSession session;
  final http.Client _client;
  final Uri _backendUri;
  final bool _ownsClient;

  @override
  Future<List<ReservaBook>> loadBooks({String? category}) async {
    final uri = category == null || category.isEmpty
        ? _backendUri.resolve('/api/cargarTodosLosLibros')
        : _backendUri.replace(
            path: '/api/cargarLibrosPorCategoria',
            queryParameters: {'categoria': category},
          );
    final response = await _send(
      http.Request('GET', uri)..headers['Accept'] = 'application/json',
    );
    _requireSuccess(response);

    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const ReservaApiException(
        'El servidor devolvió una respuesta inválida al cargar los libros.',
      );
    }
    if (decoded is! List) {
      throw const ReservaApiException(
        'El servidor devolvió un formato inesperado para el catálogo.',
      );
    }

    return decoded
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const ReservaApiException(
              'El servidor devolvió un libro con formato inválido.',
            );
          }
          return ReservaBook.fromJson(item);
        })
        .toList(growable: false);
  }

  @override
  Future<void> createReservation({
    required String bookId,
    required String title,
    required String category,
    required String fullName,
    required String email,
    required String date,
  }) async {
    final request =
        http.Request('POST', _backendUri.resolve('/api/guardarReservaUsuario'))
          ..headers['Accept'] = 'application/json'
          ..bodyFields = {
            'libroId': bookId,
            'libro': title,
            'categoria': category,
            'nombreCompleto': fullName,
            'correo': email,
            'fecha': date,
          };

    final response = await _send(request);
    _requireSuccess(response);

    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const ReservaApiException(
        'El servidor devolvió una respuesta inválida al guardar la reserva.',
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw const ReservaApiException(
        'El servidor devolvió un formato inesperado al guardar la reserva.',
      );
    }
    if (decoded['success'] != true) {
      throw ReservaApiException(
        decoded['error']?.toString() ?? 'No se pudo completar la reserva.',
      );
    }
  }

  Future<http.Response> _send(http.Request request) async {
    request.followRedirects = false;
    if (!kIsWeb && session.cookie.isNotEmpty) {
      request.headers['Cookie'] = session.cookie;
    }

    try {
      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 60));
      return await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw const ReservaApiException(
        'El servidor está tardando demasiado. Inténtalo de nuevo.',
      );
    } on http.ClientException catch (error) {
      if (kIsWeb) {
        throw const ReservaApiException(
          'No se pudo conectar con el servidor. Revisa la conexión y la configuración CORS del backend.',
        );
      }
      throw ReservaApiException(
        'No se pudo conectar con Lectio: ${error.message}',
      );
    }
  }

  void _requireSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const ReservaApiException(
        'Tu sesión ya no es válida. Inicia sesión nuevamente para reservar.',
      );
    }

    String? serverMessage;
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        serverMessage = body['error']?.toString();
      }
    } on FormatException {
      // Some Spring errors are HTML; report the HTTP status below.
    }
    if (serverMessage != null && serverMessage.isNotEmpty) {
      throw ReservaApiException(serverMessage);
    }
    if (response.statusCode == 409) {
      throw const ReservaApiException(
        'El libro ya no tiene disponibilidad para reservar.',
      );
    }
    if (response.statusCode >= 300 && response.statusCode < 400) {
      throw const ReservaApiException(
        'El servidor redirigió la solicitud. Puede que tu sesión haya vencido.',
      );
    }
    throw ReservaApiException(
      'No se pudo completar la solicitud (${response.statusCode}).',
    );
  }

  void close() {
    if (_ownsClient) _client.close();
  }
}
