import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import '../../auth/data/auth_http_client.dart';
import '../../auth/data/lectio_auth_service.dart';

const _defaultBackendUri = 'https://lectio-biblioteca.onrender.com';

class LibroVirtual {
  const LibroVirtual({
    required this.titulo,
    required this.categoria,
    required this.autor,
    required this.descripcion,
    required this.url,
  });

  final String titulo;
  final String categoria;
  final String autor;
  final String descripcion;
  final Uri url;
}

class LibrosVirtualesException implements Exception {
  const LibrosVirtualesException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class LibrosVirtualesDataSource {
  Future<List<LibroVirtual>> loadBooks();
}

class LibrosVirtualesService implements LibrosVirtualesDataSource {
  LibrosVirtualesService({
    required this.session,
    http.Client? client,
    Uri? backendUri,
  }) : _client = client ?? createAuthHttpClient(),
       _backendUri = backendUri ?? Uri.parse(_defaultBackendUri),
       _ownsClient = client == null;

  final AuthSession session;
  final http.Client _client;
  final Uri _backendUri;
  final bool _ownsClient;

  @override
  Future<List<LibroVirtual>> loadBooks() async {
    final request =
        http.Request('GET', _backendUri.resolve('/api/libroVirtualesLog'))
          ..followRedirects = false
          ..headers['Accept'] = 'text/html';
    if (!kIsWeb && session.cookie.isNotEmpty) {
      request.headers['Cookie'] = session.cookie;
    }

    final http.Response response;
    try {
      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 60));
      response = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw const LibrosVirtualesException(
        'El servidor está tardando demasiado. Inténtalo de nuevo.',
      );
    } on http.ClientException catch (error) {
      if (kIsWeb) {
        throw const LibrosVirtualesException(
          'No se pudo conectar con el catálogo. Revisa la conexión y la configuración CORS del backend.',
        );
      }
      throw LibrosVirtualesException(
        'No se pudo conectar con Lectio: ${error.message}',
      );
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const LibrosVirtualesException(
        'Tu sesión ya no es válida. Inicia sesión nuevamente para ver el catálogo.',
      );
    }
    if (response.statusCode >= 300 && response.statusCode < 400) {
      throw const LibrosVirtualesException(
        'El servidor redirigió al inicio de sesión. Vuelve a iniciar sesión para ver el catálogo.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw LibrosVirtualesException(
        'No se pudo cargar el catálogo (${response.statusCode}).',
      );
    }

    final document = html_parser.parse(response.body);
    final grid = document.querySelector('#booksGrid');
    if (grid == null) {
      throw const LibrosVirtualesException(
        'El servidor no devolvió el catálogo esperado. Comprueba que tu sesión siga activa.',
      );
    }

    final books = <LibroVirtual>[];
    for (final card in grid.querySelectorAll('.book-card')) {
      final title = card.querySelector('h3')?.text.trim() ?? '';
      final category =
          card.querySelector('.category')?.text.trim() ??
          card.attributes['data-category']?.trim() ??
          '';
      final author = card.querySelector('.author')?.text.trim() ?? '';
      final description = card.querySelector('.desc')?.text.trim() ?? '';
      final rawUrl = card.querySelector('a.read-btn')?.attributes['href'];
      Uri? uri;
      if (rawUrl != null && rawUrl.trim().isNotEmpty) {
        try {
          uri = _backendUri.resolveUri(Uri.parse(rawUrl.trim()));
        } on FormatException {
          throw const LibrosVirtualesException(
            'Un libro del catálogo tiene un enlace de lectura inválido.',
          );
        }
      }

      if (title.isEmpty ||
          category.isEmpty ||
          uri == null ||
          (uri.scheme != 'http' && uri.scheme != 'https')) {
        throw const LibrosVirtualesException(
          'Un libro del catálogo tiene datos incompletos o un enlace de lectura inválido.',
        );
      }

      books.add(
        LibroVirtual(
          titulo: title,
          categoria: category,
          autor: author,
          descripcion: description,
          url: uri,
        ),
      );
    }
    return books;
  }

  void close() {
    if (_ownsClient) _client.close();
  }
}
