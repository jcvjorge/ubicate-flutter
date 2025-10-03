import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class FirebaseTrackingService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Autenticar con custom token del backend
  Future<void> authenticateWithCustomToken(String customToken) async {
    try {
      // Verificar configuración antes de autenticar
      if (!_isFirebaseConfigured()) {
        throw Exception('Firebase no está configurado correctamente');
      }

      print('🔐 Intentando autenticar con custom token...');
      final credential = await _auth.signInWithCustomToken(customToken);

      if (credential.user != null) {
        print('✅ Autenticado en Firebase correctamente');
        print('🆔 Usuario Firebase: ${credential.user!.uid}');
      } else {
        throw Exception('Error: No se pudo crear usuario Firebase');
      }
    } catch (e) {
      print('❌ Error autenticando en Firebase: $e');

      if (e.toString().contains('CONFIGURATION_NOT_FOUND')) {
        throw Exception(
          'Firebase no configurado: Verifica google-services.json',
        );
      } else if (e.toString().contains('custom-token-mismatch')) {
        throw Exception('Token inválido: Verifica configuración del backend');
      } else if (e.toString().contains('network-request-failed')) {
        throw Exception('Sin conexión: Verifica tu internet');
      }

      rethrow;
    }
  }

  // Verificar si Firebase está configurado
  bool _isFirebaseConfigured() {
    try {
      // Intentar acceder a la configuración
      final app = FirebaseAuth.instance.app;
      return app.options.projectId.isNotEmpty;
    } catch (e) {
      print('⚠️ Firebase no configurado: $e');
      return false;
    }
  }

  // Enviar ubicación GPS a Firebase
  Future<void> updateBusLocation({
    required String empresaId,
    required String busId,
    required double latitud,
    required double longitud,
    required double velocidad,
  }) async {
    try {
      // Verificar autenticación
      if (_auth.currentUser == null) {
        throw Exception('No autenticado en Firebase');
      }

      final ref = _database.ref('empresas/$empresaId/buses/$busId');

      final data = {
        'latitud': latitud,
        'longitud': longitud,
        'velocidad': velocidad,
        'timestamp': ServerValue.timestamp,
        'activo': true,
        'chofer_uid': _auth.currentUser!.uid,
      };

      await ref.update(data);

      print('📍 Ubicación enviada: $latitud, $longitud, ${velocidad}km/h');
    } catch (e) {
      print('❌ Error enviando ubicación: $e');
      rethrow;
    }
  }

  // Escuchar cambios de buses en tiempo real
  Stream<DatabaseEvent> watchBuses(String empresaId) {
    return _database.ref('empresas/$empresaId/buses').onValue;
  }

  // Escuchar un bus específico
  Stream<DatabaseEvent> watchBus(String empresaId, String busId) {
    return _database.ref('empresas/$empresaId/buses/$busId').onValue;
  }

  // Verificar si está autenticado
  bool get isAuthenticated => _auth.currentUser != null;

  // Obtener info del usuario actual
  String? get currentUserUid => _auth.currentUser?.uid;

  // Cerrar sesión de Firebase
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('🔒 Sesión de Firebase cerrada');
    } catch (e) {
      print('❌ Error cerrando sesión Firebase: $e');
    }
  }
}
