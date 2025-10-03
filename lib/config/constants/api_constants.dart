// lib/config/constants/api_constants.dart

class ApiConstants {
  static const String baseUrl = 'http://10.0.2.2:8080/api';

  // Auth
  static const String login = '/auth/login';
  static const String registerEmpresa = '/auth/register/empresa';
  static const String registerChofer = '/auth/register/chofer'; // si lo usas
  static const String profile = '/auth/profile'; // si tienes endpoint
  static const String logout = '/auth/logout'; // si tienes endpoint

  // ---- PÚBLICOS ----
  // Empresas
  static const String publicEmpresas = '/public/empresas';

  // Rutas por empresa
  static String publicRutasByEmpresa(String empresaId) =>
      '/public/empresas/$empresaId/rutas';

  // Buses por empresa (activos y con opcional ?since=... )
  static String publicBusesByEmpresa(String empresaId) =>
      '/public/empresas/$empresaId/buses';

  // Detalle de ruta
  static String publicRutaById(String rutaId) => '/public/rutas/$rutaId';

  // Detalle de bus
  static String publicBusById(String busId) => '/public/buses/$busId';
}

class StorageKeys {
  static const String token = 'auth_token';
  static const String userData = 'user_data';
}
