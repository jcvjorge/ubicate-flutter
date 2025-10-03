import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../../data/services/public_service.dart';
import '../../providers/company_provider.dart';
import '../../providers/map_provider.dart';
import 'dart:async';

class UserMapScreen extends StatefulWidget {
  const UserMapScreen({super.key});

  @override
  State<UserMapScreen> createState() => _UserMapScreenState();
}

class _UserMapScreenState extends State<UserMapScreen> {
  final PublicService _publicService = PublicService();
  Position? _currentPosition;
  Timer? _refreshTimer;
  static const LatLng _limaCenter = LatLng(-12.0464, -77.0428);

  // Marcadores generales (no de rutas específicas)
  Set<Marker> _generalMarkers = {};

  @override
  void initState() {
    super.initState();
    _initializeMap();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    await _getCurrentLocation();
    await _loadGeneralBuses();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final position = await Geolocator.getCurrentPosition();
      setState(() => _currentPosition = position);
    } catch (e) {
      debugPrint('Error obteniendo ubicación: $e');
    }
  }

  Future<void> _loadGeneralBuses() async {
    final companyProvider = context.read<CompanyProvider>();
    final mapProvider = context.read<MapProvider>();
    final selectedEmpresaId = companyProvider.selectedEmpresaId;

    // Si hay una ruta seleccionada, no cargar buses generales
    if (mapProvider.selectedRoute != null) return;

    try {
      if (selectedEmpresaId == null) {
        setState(() => _generalMarkers = {});
        return;
      }

      final buses = await _publicService.getBusesByEmpresa(
        selectedEmpresaId,
        since: DateTime.now().toUtc().subtract(const Duration(minutes: 5)),
      );

      final busMarkers = <Marker>{};
      for (final bus in buses) {
        final lat = bus['latitud'];
        final lng = bus['longitud'];
        if (lat != null && lng != null) {
          busMarkers.add(
            Marker(
              markerId: MarkerId('general-bus-${bus['id']}'),
              position: LatLng((lat as num).toDouble(), (lng as num).toDouble()),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueBlue,
              ),
              infoWindow: InfoWindow(
                title: 'Bus ${bus['placa'] ?? bus['id']}',
                snippet: bus['rutaAsignada']?['nombre'] ?? 'Sin ruta',
              ),
              onTap: () => _showBusDetail(bus),
            ),
          );
        }
      }

      setState(() => _generalMarkers = busMarkers);
    } catch (e) {
      debugPrint('Error cargando buses: $e');
    }
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _loadGeneralBuses(),
    );
  }

  void _showBusDetail(Map<String, dynamic> bus) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.directions_bus,
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
                        'Bus ${bus['placa'] ?? bus['id']}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        bus['modelo'] ?? 'Modelo desconocido',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow(
              Icons.route,
              'Ruta',
              bus['rutaAsignada']?['nombre'] ?? 'Sin ruta',
            ),
            _buildInfoRow(
              Icons.speed,
              'Velocidad',
              '${bus['velocidad'] ?? 0} km/h',
            ),
            _buildInfoRow(
              Icons.event_seat,
              'Capacidad',
              '${bus['capacidad'] ?? '-'} pasajeros',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                label: const Text('Cerrar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text('$label: ', style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🗺️ MAPA PRINCIPAL
          Consumer<MapProvider>(
            builder: (context, mapProvider, _) {
              // Combinar marcadores generales con marcadores de ruta
              final allMarkers = <Marker>{};
              
              // Si hay una ruta seleccionada, mostrar solo marcadores de la ruta
              if (mapProvider.selectedRoute != null) {
                allMarkers.addAll(mapProvider.markers);
              } else {
                // Si no hay ruta seleccionada, mostrar buses generales
                allMarkers.addAll(_generalMarkers);
              }

              return GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentPosition != null
                      ? LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        )
                      : _limaCenter,
                  zoom: 14,
                ),
                markers: allMarkers,
                polylines: mapProvider.polylines,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                onMapCreated: (controller) {
                  mapProvider.setMapController(controller);
                },
              );
            },
          ),

          // ⏳ INDICADOR DE CARGA DE RUTA
          Consumer<MapProvider>(
            builder: (context, mapProvider, _) {
              if (mapProvider.isLoadingRoute) {
                return Positioned(
                  top: 100,
                  left: 16,
                  right: 16,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Cargando ruta: ${mapProvider.selectedRoute?['nombre']}...',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // 🏷️ CHIP DE RUTA SELECCIONADA
          Consumer<MapProvider>(
            builder: (context, mapProvider, _) {
              if (mapProvider.selectedRoute != null) {
                return Positioned(
                  top: 100,
                  left: 16,
                  right: 16,
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.route, color: Colors.blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  mapProvider.selectedRoute!['nombre'] ?? 'Ruta',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  mapProvider.selectedRoute!['empresa_nombre'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              mapProvider.clearSelectedRoute();
                              // Recargar buses generales
                              _loadGeneralBuses();
                            },
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // 🎮 BOTONES FLOTANTES
          Positioned(
            right: 16,
            bottom: 100,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'location',
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: () {
                    if (_currentPosition != null) {
                      final mapProvider = context.read<MapProvider>();
                      mapProvider.mapController?.animateCamera(
                        CameraUpdate.newLatLng(
                          LatLng(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          ),
                        ),
                      );
                    }
                  },
                  child: const Icon(Icons.my_location, color: Colors.blue),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'routes',
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: () => Navigator.pushNamed(context, '/routes'),
                  child: const Icon(Icons.route, color: Colors.blue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}