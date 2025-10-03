// lib/data/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/constants/api_constants.dart';
import 'storage_service.dart';

class ApiService {
  final StorageService _storage = StorageService();

  // Obtener headers con token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // GET request
  Future<dynamic> get(String endpoint) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final response = await http.get(
        url,
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // POST request
  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final response = await http.post(
        url,
        headers: await _getHeaders(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // PUT request
  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final response = await http.put(
        url,
        headers: await _getHeaders(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // DELETE request
  Future<dynamic> delete(String endpoint) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final response = await http.delete(
        url,
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Manejar respuesta
  dynamic _handleResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
        if (response.body.isEmpty) return null;
        return jsonDecode(response.body);
      case 204:
        return null;
      case 400:
        throw Exception('Solicitud incorrecta');
      case 401:
        throw Exception('No autorizado');
      case 403:
        throw Exception('Acceso prohibido');
      case 404:
        throw Exception('Recurso no encontrado');
      case 500:
        throw Exception('Error del servidor');
      default:
        throw Exception('Error desconocido: ${response.statusCode}');
    }
  }

  // Manejar errores
  String _handleError(dynamic error) {
    if (error.toString().contains('SocketException')) {
      return 'Error de conexión. Verifica tu internet';
    } else if (error.toString().contains('TimeoutException')) {
      return 'Tiempo de espera agotado';
    } else {
      return error.toString();
    }
  }
}