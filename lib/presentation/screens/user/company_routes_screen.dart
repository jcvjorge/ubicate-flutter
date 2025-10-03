import 'package:flutter/material.dart';
import 'route_map_screen.dart'; // Asegúrate de importar la pantalla del mapa
import '../../../data/services/public_service.dart';

class CompanyRoutesScreen extends StatefulWidget {
  final String empresaId;
  final String empresaNombre;

  const CompanyRoutesScreen({
    super.key,
    required this.empresaId,
    required this.empresaNombre,
  });

  @override
  State<CompanyRoutesScreen> createState() => _CompanyRoutesScreenState();
}

class _CompanyRoutesScreenState extends State<CompanyRoutesScreen> {
  final PublicService _publicService = PublicService();
  List<dynamic> _rutas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRutas();
  }

  Future<void> _loadRutas() async {
    try {
      final rutas = await _publicService.getRutasByEmpresa(widget.empresaId);
      setState(() {
        _rutas = rutas;
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

  Color _getColorFromHex(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) return Colors.blue;
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.empresaNombre),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _rutas.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.route, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text(
                      'Esta empresa no tiene rutas disponibles',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadRutas,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _rutas.length,
                  itemBuilder: (context, index) {
                    final ruta = _rutas[index];
                    final color = _getColorFromHex(ruta['color_hex']);
                    return _RouteCard(
                      ruta: ruta,
                      color: color,
                      onViewMap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => RouteMapScreen(
                                  rutaId: ruta['id'].toString(),
                                  empresaId: widget.empresaId,
                                  color: color,
                                ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final Map<String, dynamic> ruta;
  final Color color;
  final VoidCallback onViewMap;

  const _RouteCard({
    required this.ruta,
    required this.color,
    required this.onViewMap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.route, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ruta['nombre'] ?? 'Sin nombre',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          ruta['codigo'] ?? 'N/A',
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (ruta['descripcion'] != null) ...[
              const SizedBox(height: 12),
              Text(
                ruta['descripcion'],
                style: TextStyle(color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.directions_bus, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${ruta['total_buses'] ?? 0} buses',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onViewMap,
                  child: const Text('Ver en mapa'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
