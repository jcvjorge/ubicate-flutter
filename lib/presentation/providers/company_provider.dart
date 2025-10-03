// lib/presentation/providers/company_provider.dart

import 'package:flutter/material.dart';
import '../../data/services/public_service.dart';

class CompanyProvider with ChangeNotifier {
  final PublicService _publicService = PublicService();

  // Estado
  List<dynamic> _empresas = [];
  String? _selectedEmpresaId;
  String? _selectedEmpresaNombre;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<dynamic> get empresas => _empresas;
  String? get selectedEmpresaId => _selectedEmpresaId;
  String? get selectedEmpresaNombre => _selectedEmpresaNombre;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasSelectedEmpresa => _selectedEmpresaId != null;

  // Cargar todas las empresas
  Future<void> loadEmpresas() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _empresas = await _publicService.getEmpresas();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Seleccionar una empresa
  void selectEmpresa(String empresaId, String empresaNombre) {
    _selectedEmpresaId = empresaId;
    _selectedEmpresaNombre = empresaNombre;
    notifyListeners();
  }

  // Limpiar selección
  void clearSelection() {
    _selectedEmpresaId = null;
    _selectedEmpresaNombre = null;
    notifyListeners();
  }

  // Limpiar error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
