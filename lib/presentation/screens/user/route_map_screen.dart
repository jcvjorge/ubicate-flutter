import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../data/services/public_service.dart';

class RouteMapScreen extends StatefulWidget {
  final String rutaId;
  final String? empresaId;
  final Color? color;

  const RouteMapScreen({
    super.key,
    required this.rutaId,
    this.empresaId,
    this.color,
  });

  @override
  State<RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends State<RouteMapScreen> {
  final _api = PublicService();
  GoogleMapController? _controller;

  Map<String, dynamic>? _ruta;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _loading = true;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (widget.empresaId != null) {
        await _loadBusesForRoute();
      }
    });
  }

  Future<void> _load() async {
    try {
      final data = await _api.getRutaById(widget.rutaId);
      _ruta = data;
      _buildOverlays();

      // Cargar buses con coordenadas si hay empresa
      if (widget.empresaId != null) {
        await _loadBusesForRoute();
      }

      setState(() => _loading = false);
      _fitBounds();
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _loadBusesForRoute() async {
    try {
      print(
        '🔍 Cargando buses para empresa: ${widget.empresaId}, ruta: ${widget.rutaId}',
      );

      final allBuses = await _api.getBusesByEmpresa(widget.empresaId!);
      print('📦 Total buses de la empresa: ${allBuses.length}');

      // Filtrar solo los buses de esta ruta
      final busesDeEstaRuta =
          allBuses.where((bus) {
            final rutaId = bus['ruta']?['id'];
            print(
              '   Bus ${bus['id']}: rutaId=$rutaId, buscando=${widget.rutaId}',
            );
            return rutaId != null && rutaId.toString() == widget.rutaId;
          }).toList();

      print('✅ Buses filtrados para esta ruta: ${busesDeEstaRuta.length}');

      // Imprimir cada bus
      for (var bus in busesDeEstaRuta) {
        print(
          '   - Bus ${bus['id']}: lat=${bus['latitud']}, lng=${bus['longitud']}',
        );
      }

      // Actualizar la ruta con los buses completos
      if (_ruta != null) {
        _ruta!['buses'] = busesDeEstaRuta;
        _drawBuses();
      }
    } catch (e) {
      print('❌ Error cargando buses: $e');
    }
  }

  void _buildOverlays() {
    _polylines.clear();
    _markers.clear();

    // Polyline si existe
    final polylineStr = _ruta?['polyline'] as String?;
    if (polylineStr != null && polylineStr.isNotEmpty) {
      final points = _decodePolyline(polylineStr);
      if (points.isNotEmpty) {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: points,
            width: 6,
            color: widget.color ?? Colors.blue,
          ),
        );
        _addEndpointMarkers(points.first, points.last);
      }
    } else {
      // Fallback: origen/destino
      final origin = _latLngFromStr(_ruta?['origen']);
      final dest = _latLngFromStr(_ruta?['destino']);
      if (origin != null && dest != null) {
        _addEndpointMarkers(origin, dest);
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('routeOD'),
            points: [origin, dest],
            width: 4,
            color: widget.color ?? Colors.blue,
            patterns: [PatternItem.dash(20), PatternItem.gap(10)],
          ),
        );
      }
    }

    _drawBuses();
  }

  void _addEndpointMarkers(LatLng origin, LatLng dest) {
    _markers.addAll([
      Marker(
        markerId: const MarkerId('origin'),
        position: origin,
        infoWindow: const InfoWindow(title: 'Origen'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: const MarkerId('dest'),
        position: dest,
        infoWindow: const InfoWindow(title: 'Destino'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    ]);
  }

  void _drawBuses() {
    final buses = (_ruta?['buses'] as List?) ?? [];
    _markers.removeWhere((m) => m.markerId.value.startsWith('bus-'));

    int busesConCoordenadas = 0;

    for (final b in buses) {
      final lat = b['latitud'];
      final lng = b['longitud'];

      if (lat != null && lng != null) {
        busesConCoordenadas++;
        _markers.add(
          Marker(
            markerId: MarkerId('bus-${b['id']}'),
            position: LatLng((lat as num).toDouble(), (lng as num).toDouble()),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
            infoWindow: InfoWindow(
              title: 'Bus ${b['placa'] ?? b['codigo'] ?? b['id']}',
              snippet: 'Vel: ${b['velocidad'] ?? 0} km/h',
            ),
          ),
        );
      }
    }

    debugPrint(
      'Buses en ruta: ${buses.length}, con coordenadas: $busesConCoordenadas',
    );
    setState(() {});
  }

  void _fitBounds() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (_controller == null) return;
    final bounds = _computeBounds();
    if (bounds != null) {
      _controller!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
    }
  }

  LatLngBounds? _computeBounds() {
    final points = <LatLng>[];
    for (final p in _polylines.expand((p) => p.points)) points.add(p);
    for (final m in _markers) points.add(m.position);
    if (points.isEmpty) return null;

    double minLat = points.first.latitude, maxLat = points.first.latitude;
    double minLng = points.first.longitude, maxLng = points.first.longitude;
    for (final p in points) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  List<LatLng> _decodePolyline(String polyline) {
    // Validar que no sea placeholder
    if (polyline.isEmpty ||
        polyline.toLowerCase().contains('aqui') ||
        polyline.toLowerCase().contains('placeholder')) {
      debugPrint('Polyline inválido o placeholder, usando fallback');
      return [];
    }

    try {
      final List<LatLng> points = [];
      int index = 0, lat = 0, lng = 0;

      while (index < polyline.length) {
        int b, shift = 0, result = 0;
        do {
          if (index >= polyline.length) break;
          b = polyline.codeUnitAt(index++) - 63;
          result |= (b & 0x1f) << shift;
          shift += 5;
        } while (b >= 0x20 && index < polyline.length);

        final dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
        lat += dlat;

        shift = 0;
        result = 0;
        do {
          if (index >= polyline.length) break;
          b = polyline.codeUnitAt(index++) - 63;
          result |= (b & 0x1f) << shift;
          shift += 5;
        } while (b >= 0x20 && index < polyline.length);

        final dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
        lng += dlng;

        points.add(LatLng(lat / 1e5, lng / 1e5));
      }

      debugPrint('Polyline decodificado: ${points.length} puntos');
      return points;
    } catch (e) {
      debugPrint('Error decodificando polyline: $e');
      return [];
    }
  }

  LatLng? _latLngFromStr(dynamic value) {
    if (value is! String) return null;
    final parts = value.split(',');
    if (parts.length != 2) return null;
    final lat = double.tryParse(parts[0].trim());
    final lng = double.tryParse(parts[1].trim());
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    final nombre = _ruta?['nombre'] ?? 'Ruta';
    return Scaffold(
      appBar: AppBar(
        title: Text(nombre),
        backgroundColor: widget.color ?? Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(-12.0464, -77.0428),
                  zoom: 13,
                ),
                polylines: _polylines,
                markers: _markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                onMapCreated: (c) {
                  _controller = c;
                  _fitBounds();
                },
              ),
    );
  }
}
