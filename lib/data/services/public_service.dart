// lib/data/services/public_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/constants/api_constants.dart';

class PublicService {
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<List<dynamic>> getEmpresas() async {
    try {
      final url = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.publicEmpresas}',
      );
      final response = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else {
        throw Exception('Error al obtener empresas: ${response.statusCode}');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getRutasByEmpresa(String empresaId) async {
    try {
      final url = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.publicRutasByEmpresa(empresaId)}',
      );
      final response = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else {
        throw Exception('Error al obtener rutas: ${response.statusCode}');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getRutaById(String rutaId) async {
    try {
      final url = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.publicRutaById(rutaId)}',
      );
      final response = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Error al obtener ruta: ${response.statusCode}');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getBusesByEmpresa(
    String empresaId, {
    DateTime? since,
  }) async {
    try {
      var url =
          '${ApiConstants.baseUrl}${ApiConstants.publicBusesByEmpresa(empresaId)}';

      if (since != null) {
        final sinceParam = since.toIso8601String();
        url += '?since=$sinceParam';
      }

      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else {
        throw Exception('Error al obtener buses: ${response.statusCode}');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getBusUbicacion(String busId) async {
    try {
      final url = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.publicBusById(busId)}',
      );
      final response = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Error al obtener bus: ${response.statusCode}');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(dynamic error) {
    if (error.toString().contains('SocketException')) {
      return 'Error de conexión. Verifica tu internet';
    } else if (error.toString().contains('TimeoutException')) {
      return 'Tiempo de espera agotado. Intenta nuevamente';
    } else if (error.toString().contains('FormatException')) {
      return 'Error al procesar datos del servidor';
    } else {
      return 'Error: ${error.toString()}';
    }
  }
}
