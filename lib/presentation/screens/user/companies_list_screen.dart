// lib/presentation/screens/user/companies_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/services/public_service.dart';
import '../../providers/company_provider.dart';
import 'company_routes_screen.dart';

class CompaniesListScreen extends StatefulWidget {
  const CompaniesListScreen({super.key});

  @override
  State<CompaniesListScreen> createState() => _CompaniesListScreenState();
}

class _CompaniesListScreenState extends State<CompaniesListScreen> {
  final PublicService _publicService = PublicService();
  List<dynamic> _empresas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmpresas();
  }

  Future<void> _loadEmpresas() async {
    try {
      final empresas = await _publicService.getEmpresas();
      setState(() {
        _empresas = empresas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _selectEmpresa(Map<String, dynamic> empresa) {
    // Actualizar el provider con la empresa seleccionada
    final companyProvider = context.read<CompanyProvider>();
    companyProvider.selectEmpresa(empresa['id'].toString(), empresa['nombre']);

    // Retornar true para indicar que se seleccionó una empresa
    Navigator.pop(context, true);
  }

  void _viewEmpresaRoutes(Map<String, dynamic> empresa) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => CompanyRoutesScreen(
              empresaId: empresa['id'].toString(),
              empresaNombre: empresa['nombre'],
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Empresas de Transporte'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _empresas.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.business, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No hay empresas disponibles',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadEmpresas,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _empresas.length,
                  itemBuilder: (context, index) {
                    final empresa = _empresas[index];
                    return _CompanyCard(
                      empresa: empresa,
                      onSelect: () => _selectEmpresa(empresa),
                      onViewRoutes: () => _viewEmpresaRoutes(empresa),
                    );
                  },
                ),
              ),
    );
  }
}

class _CompanyCard extends StatelessWidget {
  final Map<String, dynamic> empresa;
  final VoidCallback onSelect;
  final VoidCallback onViewRoutes;

  const _CompanyCard({
    required this.empresa,
    required this.onSelect,
    required this.onViewRoutes,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.business,
                      color: Colors.blue,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          empresa['nombre'] ?? 'Sin nombre',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.phone,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              empresa['telefono'] ?? 'Sin teléfono',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onViewRoutes,
                      icon: const Icon(Icons.route, size: 18),
                      label: const Text('Ver Rutas'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: const BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onSelect,
                      icon: const Icon(Icons.map, size: 18),
                      label: const Text('Ver Buses'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
