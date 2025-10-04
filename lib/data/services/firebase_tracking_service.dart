// lib/data/services/firebase_tracking_service.dart
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseTrackingService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  Future<void> authenticateWithCustomToken(String customToken) async {
    try {
      await FirebaseAuth.instance.signInWithCustomToken(customToken);
    } catch (e) {
      throw Exception('Firebase no configurado: Verifica google-services.json');
    }
  }

  Future<void> updateBusLocation({
    required String empresaId,
    required String busId,
    required double latitud,
    required double longitud,
    required double velocidad,
  }) async {
    try {
      DatabaseReference ref = _database
          .ref()
          .child('empresas')
          .child(empresaId)
          .child('buses')
          .child(busId);

      await ref.update({
        'latitud': latitud,
        'longitud': longitud,
        'velocidad': velocidad,
        'timestamp': ServerValue.timestamp,
        'activo': true,
      });
    } catch (e) {
      throw Exception('Error actualizando ubicación: $e');
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }
}
