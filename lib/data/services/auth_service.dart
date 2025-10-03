import '../models/auth_response_model.dart';
import '../models/user_model.dart';
import '../../config/constants/api_constants.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  // Login
  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _apiService.post(ApiConstants.login, {
        'email': email,
        'password': password,
      });
      return AuthResponse.fromJson(response);
    } catch (e) {
      throw Exception('Error en login: $e');
    }
  }

  // Perfil (si tienes endpoint)
  Future<UserModel> getProfile() async {
    try {
      final response = await _apiService.get(ApiConstants.profile);
      return UserModel.fromJson(response);
    } catch (e) {
      throw Exception('Error obteniendo perfil: $e');
    }
  }

  /// Registro de **empresa** (tu backend expone /auth/register/empresa)
  Future<AuthResponse> registerEmpresa(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post(
        ApiConstants.registerEmpresa,
        data,
      );
      return AuthResponse.fromJson(response);
    } catch (e) {
      throw Exception('Error en registro de empresa: $e');
    }
  }

  /// Compatibilidad hacia atrás: si en algún sitio llamas `register(...)`,
  /// redirigimos al registro de empresa.
  Future<AuthResponse> register(Map<String, dynamic> data) =>
      registerEmpresa(data);

  /// (Opcional) Registro de chofer — tu backend lo bloquea con 403 por diseño.
  Future<AuthResponse> registerChofer(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post(
        ApiConstants.registerChofer,
        data,
      );
      return AuthResponse.fromJson(response);
    } catch (e) {
      throw Exception('Error en registro de chofer: $e');
    }
  }
}
