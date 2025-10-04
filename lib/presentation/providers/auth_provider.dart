import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/storage_service.dart';
import '../../data/services/firebase_tracking_service.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final FirebaseTrackingService _firebaseService = FirebaseTrackingService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _currentUser;
  String? _errorMessage;
  bool _firebaseConnected = false;

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;
  bool get firebaseConnected => _firebaseConnected;

  Future<void> checkAuthStatus() async {
    try {
      final hasSession = await _storageService.hasSession();

      if (hasSession) {
        final user = await _storageService.getUser();
        if (user != null) {
          _currentUser = user;
          _status = AuthStatus.authenticated;

          // ✅ CORREGIDO: Si es chofer, usar autenticación anónima de Firebase
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

      _currentUser = authResponse.user;
      _status = AuthStatus.authenticated;

      // ✅ CORREGIDO: Si es chofer, conectar a Firebase sin custom tokens
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

  // ✅ CORREGIDO: Método de conexión Firebase simplificado
  Future<void> _connectToFirebase() async {
    try {
      // Usar autenticación anónima de Firebase (funciona siempre)
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
        print('✅ Chofer conectado a Firebase (modo anónimo)');
      } else {
        print('✅ Chofer ya conectado a Firebase');
      }

      _firebaseConnected = true;
      notifyListeners();
    } catch (e) {
      print('❌ Error conectando a Firebase: $e');
      _firebaseConnected = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      // ✅ CORREGIDO: Cerrar sesión Firebase correctamente
      if (_firebaseConnected && FirebaseAuth.instance.currentUser != null) {
        await FirebaseAuth.instance.signOut();
        _firebaseConnected = false;
        print('✅ Sesión Firebase cerrada');
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

  FirebaseTrackingService get firebaseService => _firebaseService;
}
