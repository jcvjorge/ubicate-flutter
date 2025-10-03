import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/storage_service.dart';
import '../../data/services/firebase_tracking_service.dart'; // ← NUEVO IMPORT

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final FirebaseTrackingService _firebaseService = FirebaseTrackingService(); // ← NUEVO

  AuthStatus _status = AuthStatus.initial;
  UserModel? _currentUser;
  String? _errorMessage;
  bool _firebaseConnected = false; // ← NUEVO

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;
  bool get firebaseConnected => _firebaseConnected; // ← NUEVO

  Future<void> checkAuthStatus() async {
    try {
      final hasSession = await _storageService.hasSession();

      if (hasSession) {
        final user = await _storageService.getUser();
        if (user != null) {
          _currentUser = user;
          _status = AuthStatus.authenticated;
          
          // 🔥 NUEVO: Si es chofer, conectar a Firebase
          if (user.isChofer) {
            await _connectToFirebase();
          }
        } else {
          _status = AuthStatus.unauthenticated;
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'Error verificando sesión';
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final authResponse = await _authService.login(email, password);

      await _storageService.saveToken(authResponse.token);
      await _storageService.saveUser(authResponse.user);

      // 🔥 NUEVO: Guardar firebase token si viene (para choferes)
      if (authResponse.firebaseToken != null) {
        await _storageService.saveFirebaseToken(authResponse.firebaseToken!);
        print('🔥 Firebase token guardado: ${authResponse.firebaseToken!.substring(0, 20)}...');
      }

      _currentUser = authResponse.user;
      _status = AuthStatus.authenticated;

      // 🔥 NUEVO: Si es chofer, conectar a Firebase
      if (authResponse.user.isChofer) {
        await _connectToFirebase();
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _getErrorMessage(e.toString());
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // 🔥 NUEVO: Conectar a Firebase
  Future<void> _connectToFirebase() async {
    try {
      final firebaseToken = await _storageService.getFirebaseToken();
      
      if (firebaseToken != null) {
        await _firebaseService.authenticateWithCustomToken(firebaseToken);
        _firebaseConnected = true;
        print('✅ Chofer conectado a Firebase correctamente');
      } else {
        print('⚠️ No hay token de Firebase para el chofer');
        _firebaseConnected = false;
      }
      notifyListeners();
    } catch (e) {
      print('❌ Error conectando chofer a Firebase: $e');
      _firebaseConnected = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      // 🔥 NUEVO: Desconectar de Firebase si está conectado
      if (_firebaseConnected) {
        await _firebaseService.signOut();
        _firebaseConnected = false;
      }

      await _storageService.clearSession();
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al cerrar sesión';
      notifyListeners();
    }
  }

  Future<void> refreshUserData() async {
    try {
      final user = await _authService.getProfile();
      _currentUser = user;
      await _storageService.saveUser(user);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error actualizando datos';
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _getErrorMessage(String error) {
    if (error.contains('No autorizado')) {
      return 'Email o contraseña incorrectos';
    } else if (error.contains('conexión')) {
      return 'Error de conexión. Verifica tu internet';
    } else if (error.contains('TimeoutException')) {
      return 'Tiempo de espera agotado. Intenta nuevamente';
    } else {
      return 'Error al iniciar sesión. Intenta nuevamente';
    }
  }

  void setMockUser(UserModel user) {
    _currentUser = user;
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  // 🔥 NUEVO: Getter para Firebase service (para usar en driver_map_screen)
  FirebaseTrackingService get firebaseService => _firebaseService;
}