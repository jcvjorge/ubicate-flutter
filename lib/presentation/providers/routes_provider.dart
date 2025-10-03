import 'package:flutter/material.dart';
import '../../data/services/public_service.dart';

class RoutesProvider with ChangeNotifier {
  final PublicService _publicService = PublicService();

  // Estado global
  List<dynamic> _todasLasRutas = [];
  List<dynamic> _empresas = [];
  String? _filtroEmpresaId;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<dynamic> get todasLasRutas => _todasLasRutas;
  List<dynamic> get empresas => _empresas;
  String? get filtroEmpresaId => _filtroEmpresaId;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Rutas filtradas por empresa seleccionada
  List<dynamic> get rutasFiltradas {
    if (_filtroEmpresaId == null) return _todasLasRutas;
    return _todasLasRutas.where((ruta) {
      return ruta['empresa_id']?.toString() == _filtroEmpresaId;
    }).toList();
  }

  // Nombre de empresa filtrada
  String get nombreEmpresaFiltrada {
    if (_filtroEmpresaId == null) return 'Todas las empresas';
    final empresa = _empresas.firstWhere(
      (e) => e['id'].toString() == _filtroEmpresaId,
      orElse: () => {'nombre': 'Empresa desconocida'},
    );
    return empresa['nombre'];
  }

  // Cargar todos los datos al inicio
  Future<void> loadAllData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Cargar empresas
      _empresas = await _publicService.getEmpresas();
      
      // Cargar todas las rutas de todas las empresas
      _todasLasRutas = [];
      for (final empresa in _empresas) {
        try {
          final rutasEmpresa = await _publicService.getRutasByEmpresa(
            empresa['id'].toString(),
          );
          
          // Agregar empresa_id a cada ruta para filtrado
          for (final ruta in rutasEmpresa) {
            ruta['empresa_id'] = empresa['id'];
            ruta['empresa_nombre'] = empresa['nombre'];
          }
          
          _todasLasRutas.addAll(rutasEmpresa);
        } catch (e) {
          print('Error cargando rutas de empresa ${empresa['id']}: $e');
        }
      }
      
      _isLoading = false;
      notifyListeners();
      
      print('✅ Datos cargados: ${_empresas.length} empresas, ${_todasLasRutas.length} rutas');
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Filtrar por empresa
  void setFiltroEmpresa(String? empresaId) {
    _filtroEmpresaId = empresaId;
    notifyListeners();
  }

  // Limpiar filtro
  void clearFiltro() {
    _filtroEmpresaId = null;
    notifyListeners();
  }

  // Obtener empresa por ID
  Map<String, dynamic>? getEmpresaById(String empresaId) {
    try {
      return _empresas.firstWhere(
        (empresa) => empresa['id'].toString() == empresaId,
      );
    } catch (e) {
      return null;
    }
  }
}