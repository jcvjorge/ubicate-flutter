import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/routes_provider.dart';
import '../../providers/map_provider.dart';

class RoutesListScreen extends StatefulWidget {
  const RoutesListScreen({super.key});

  @override
  State<RoutesListScreen> createState() => _RoutesListScreenState();
}

class _RoutesListScreenState extends State<RoutesListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Explorar Rutas'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<RoutesProvider>(
        builder: (context, routesProvider, _) {
          if (routesProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando rutas...'),
                ],
              ),
            );
          }

          if (routesProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error cargando rutas',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    routesProvider.errorMessage!,
                    style: TextStyle(color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => routesProvider.loadAllData(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final todasLasRutas = routesProvider.todasLasRutas;
          final empresas = routesProvider.empresas;

          if (todasLasRutas.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.route, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No hay rutas disponibles',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Filtrar por búsqueda y empresa
          final rutasFiltradas =
              todasLasRutas.where((ruta) {
                final matchesSearch =
                    _searchQuery.isEmpty ||
                    ruta['nombre']?.toString().toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ==
                        true ||
                    ruta['codigo']?.toString().toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ==
                        true ||
                    ruta['empresa_nombre']?.toString().toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ==
                        true;

                final matchesEmpresa =
                    routesProvider.filtroEmpresaId == null ||
                    ruta['empresa_id']?.toString() ==
                        routesProvider.filtroEmpresaId;

                return matchesSearch && matchesEmpresa;
              }).toList();

          return Column(
            children: [
              // ✨ HEADER MEJORADO
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue, Colors.blueAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Estadísticas rápidas
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.route,
                            label: 'Rutas',
                            value: '${rutasFiltradas.length}',
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.business,
                            label: 'Empresas',
                            value: '${empresas.length}',
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Barra de búsqueda
                    TextField(
                      onChanged:
                          (value) => setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Buscar rutas, empresas o códigos...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon:
                            _searchQuery.isNotEmpty
                                ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed:
                                      () => setState(() => _searchQuery = ''),
                                )
                                : null,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ✨ FILTRO DE EMPRESAS MEJORADO
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: routesProvider.filtroEmpresaId,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.filter_list),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        hint: const Text('Filtrar por empresa'),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('📍 Todas las empresas'),
                          ),
                          ...empresas.map((empresa) {
                            final rutasCount =
                                todasLasRutas
                                    .where(
                                      (r) =>
                                          r['empresa_id']?.toString() ==
                                          empresa['id'].toString(),
                                    )
                                    .length;
                            return DropdownMenuItem<String>(
                              value: empresa['id'].toString(),
                              child: Text(
                                '🚌 ${empresa['nombre']} ($rutasCount rutas)',
                              ),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          routesProvider.setFiltroEmpresa(value);
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // ✨ LISTA DE RUTAS MEJORADA
              Expanded(
                child:
                    rutasFiltradas.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'No se encontraron rutas para "$_searchQuery"'
                                    : 'No hay rutas en esta empresa',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() => _searchQuery = '');
                                  routesProvider.clearFiltro();
                                },
                                icon: const Icon(Icons.clear_all),
                                label: const Text('Limpiar filtros'),
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: rutasFiltradas.length,
                          itemBuilder: (context, index) {
                            final ruta = rutasFiltradas[index];
                            final color = _getColorFromHex(ruta['color_hex']);
                            return _RouteCard(
                              ruta: ruta,
                              color: color,
                              onTap: () async {
                                print(
                                  '🚌 Seleccionando ruta: ${ruta['nombre']}',
                                );

                                final mapProvider = context.read<MapProvider>();

                                // Mostrar loading
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Text(
                                            'Cargando ruta: ${ruta['nombre']}...',
                                          ),
                                        ),
                                      ],
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );

                                // Cargar la ruta en el mapa
                                await mapProvider.showRouteOnMap(
                                  ruta,
                                  empresaId: ruta['empresa_id']?.toString(),
                                );

                                // Cerrar la lista y volver al mapa
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              },
                            );
                          },
                        ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getColorFromHex(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) return Colors.blue;
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }
}

// ✨ WIDGET PARA ESTADÍSTICAS
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }
}

// ✨ CARD DE RUTA MEJORADA
class _RouteCard extends StatelessWidget {
  final Map<String, dynamic> ruta;
  final Color color;
  final VoidCallback onTap;

  const _RouteCard({
    required this.ruta,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Ícono de ruta con color
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.3), width: 2),
                ),
                child: Icon(Icons.route, color: color, size: 32),
              ),
              const SizedBox(width: 16),

              // Información de la ruta
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

                    // Empresa
                    Row(
                      children: [
                        Icon(Icons.business, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            ruta['empresa_nombre'] ?? 'Empresa desconocida',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Código de ruta
                    if (ruta['codigo'] != null)
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
                          'Código: ${ruta['codigo']}',
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Flecha
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.blue,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
