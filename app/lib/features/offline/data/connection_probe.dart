import 'package:http/http.dart' as http;

Future<bool> hasInternetConnection({http.Client? client}) async {
  final connection = client ?? http.Client();
  try {
    final response = await connection
        .get(Uri.https('connectivitycheck.gstatic.com', '/generate_204'))
        .timeout(const Duration(seconds: 5));
    return response.statusCode == 204;
  } catch (_) {
    return false;
  } finally {
    if (client == null) connection.close();
  }
}
