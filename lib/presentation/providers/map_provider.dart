import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../data/services/public_service.dart';
import 'dart:math' as math;

class MapProvider with ChangeNotifier {
  final PublicService _publicService = PublicService();

  // Estado del mapa
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isLoadingRoute = false;

  // Ruta seleccionada
  Map<String, dynamic>? _selectedRoute;

  // Getters
  Set<Marker> get markers => _markers;
  Set<Polyline> get polylines => _polylines;
  bool get isLoadingRoute => _isLoadingRoute;
  Map<String, dynamic>? get selectedRoute => _selectedRoute;
  GoogleMapController? get mapController => _mapController;

  // Setter para el controlador del mapa
  void setMapController(GoogleMapController controller) {
    _mapController = controller;
    print('🗺️ MapController configurado');
  }

  // Mostrar ruta seleccionada en el mapa principal
  Future<void> showRouteOnMap(
    Map<String, dynamic> ruta, {
    String? empresaId,
  }) async {
    print('🚌 Iniciando carga de ruta: ${ruta['nombre']}');

    _isLoadingRoute = true;
    _selectedRoute = ruta;
    notifyListeners();

    try {
      await _loadRouteData(ruta, empresaId);
      await _fitMapToRoute();
      _isLoadingRoute = false;
      notifyListeners();
      print('✅ Ruta cargada exitosamente');
    } catch (e) {
      print('❌ Error cargando ruta: $e');
      _isLoadingRoute = false;
      notifyListeners();
    }
  }

  // Cargar datos de la ruta
  Future<void> _loadRouteData(
    Map<String, dynamic> ruta,
    String? empresaId,
  ) async {
    _clearRouteOverlays();

    try {
      print('📡 Obteniendo detalles de ruta ID: ${ruta['id']}');

      // Cargar detalles completos de la ruta
      final rutaCompleta = await _publicService.getRutaById(
        ruta['id'].toString(),
      );
      print('📋 Datos de ruta obtenidos: ${rutaCompleta.keys}');

      // Dibujar polyline si existe
      final polylineStr = rutaCompleta['polyline'] as String?;
      print(
        '🗺️ Polyline string: ${polylineStr?.substring(0, math.min(50, polylineStr?.length ?? 0))}...',
      );

      if (polylineStr != null &&
          polylineStr.isNotEmpty &&
          !_isPlaceholder(polylineStr)) {
        final points = _decodePolyline(polylineStr);
        if (points.isNotEmpty) {
          print('✅ Polyline decodificado: ${points.length} puntos');
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('selected_route'),
              points: points,
              width: 6,
              color: _getColorFromHex(ruta['color_hex']),
            ),
          );
          _addEndpointMarkers(points.first, points.last, ruta);
        }
      } else {
        print('⚠️ No hay polyline válido, usando origen/destino');
        // Fallback: usar origen y destino
        final origin = _latLngFromStr(rutaCompleta['origen']);
        final dest = _latLngFromStr(rutaCompleta['destino']);
        print('📍 Origen: $origin, Destino: $dest');

        if (origin != null && dest != null) {
          _addEndpointMarkers(origin, dest, ruta);
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('selected_route_fallback'),
              points: [origin, dest],
              width: 4,
              color: _getColorFromHex(ruta['color_hex']),
              patterns: [PatternItem.dash(20), PatternItem.gap(10)],
            ),
          );
        } else {
          print('⚠️ No hay datos de origen/destino, usando marcador básico');
          _addBasicRouteMarker(ruta);
        }
      }

      // Cargar buses de esta ruta si hay empresa
      if (empresaId != null) {
        await _loadBusesForRoute(empresaId, ruta['id'].toString());
      }
    } catch (e) {
      print('❌ Error en _loadRouteData: $e');
      _addBasicRouteMarker(ruta);
    }
  }

  // Verificar si es placeholder
  bool _isPlaceholder(String polyline) {
    final lower = polyline.toLowerCase();
    return lower.contains('placeholder') ||
        lower.contains('aqui') ||
        lower.contains('example') ||
        polyline.length < 10;
  }

  // Agregar marcador básico si no hay datos de polyline
  void _addBasicRouteMarker(Map<String, dynamic> ruta) {
    const defaultPosition = LatLng(-12.0464, -77.0428);

    _markers.add(
      Marker(
        markerId: const MarkerId('route_basic'),
        position: defaultPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(
          title: ruta['nombre'] ?? 'Ruta',
          snippet: 'Ubicación aproximada',
        ),
      ),
    );
    print('📍 Agregado marcador básico para ruta');
  }

  // Convertir string de coordenadas a LatLng
  LatLng? _latLngFromStr(dynamic value) {
    if (value is! String || value.isEmpty) return null;

    try {
      final parts = value.split(',');
      if (parts.length != 2) return null;

      final lat = double.tryParse(parts[0].trim());
      final lng = double.tryParse(parts[1].trim());

      if (lat == null || lng == null) return null;
      if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;

      return LatLng(lat, lng);
    } catch (e) {
      print('❌ Error parseando coordenadas: $value');
      return null;
    }
  }

  // Cargar buses específicos de la ruta
  Future<void> _loadBusesForRoute(String empresaId, String rutaId) async {
    try {
      print('🚌 Cargando buses para empresa: $empresaId, ruta: $rutaId');

      final allBuses = await _publicService.getBusesByEmpresa(empresaId);
      print('📦 Total buses de empresa: ${allBuses.length}');

      final busesDeEstaRuta =
          allBuses.where((bus) {
            final busRutaId = bus['ruta']?['id']?.toString();
            return busRutaId == rutaId;
          }).toList();

      print('🎯 Buses filtrados para esta ruta: ${busesDeEstaRuta.length}');

      for (final bus in busesDeEstaRuta) {
        final lat = bus['latitud'];
        final lng = bus['longitud'];

        if (lat != null && lng != null) {
          _markers.add(
            Marker(
              markerId: MarkerId('bus-${bus['id']}'),
              position: LatLng(
                (lat as num).toDouble(),
                (lng as num).toDouble(),
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure,
              ),
              infoWindow: InfoWindow(
                title: 'Bus ${bus['placa'] ?? bus['id']}',
                snippet: 'Vel: ${bus['velocidad'] ?? 0} km/h',
              ),
            ),
          );
          print('🚌 Bus agregado: ${bus['id']} en ($lat, $lng)');
        }
      }
    } catch (e) {
      print('❌ Error cargando buses de ruta: $e');
    }
  }

  // Agregar marcadores de inicio y fin
  void _addEndpointMarkers(
    LatLng start,
    LatLng end,
    Map<String, dynamic> ruta,
  ) {
    _markers.addAll([
      Marker(
        markerId: const MarkerId('route_start'),
        position: start,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: 'Inicio - ${ruta['nombre']}',
          snippet: 'Punto de partida',
        ),
      ),
      Marker(
        markerId: const MarkerId('route_end'),
        position: end,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: 'Destino - ${ruta['nombre']}',
          snippet: 'Punto final',
        ),
      ),
    ]);
    print('📍 Marcadores de inicio y fin agregados');
  }

  // Ajustar mapa a la ruta
  Future<void> _fitMapToRoute() async {
    if (_mapController == null) {
      print('⚠️ MapController no disponible para ajuste');
      return;
    }

    await Future.delayed(const Duration(milliseconds: 500));

    final bounds = _computeBounds();
    if (bounds != null) {
      try {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 100),
        );
        print('📷 Mapa ajustado a los límites de la ruta');
      } catch (e) {
        print('❌ Error ajustando mapa: $e');
        // Fallback
        if (_markers.isNotEmpty) {
          final firstMarker = _markers.first;
          await _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(firstMarker.position, 14),
          );
          print('📷 Fallback: centrado en primer marcador');
        }
      }
    }
  }

  // Calcular límites del mapa
  LatLngBounds? _computeBounds() {
    final points = <LatLng>[];

    for (final polyline in _polylines) {
      points.addAll(polyline.points);
    }

    for (final marker in _markers) {
      points.add(marker.position);
    }

    if (points.isEmpty) {
      print('⚠️ No hay puntos para calcular límites');
      return null;
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    const padding = 0.002;
    final bounds = LatLngBounds(
      southwest: LatLng(minLat - padding, minLng - padding),
      northeast: LatLng(maxLat + padding, maxLng + padding),
    );

    print('📐 Límites calculados: $bounds');
    return bounds;
  }

  // Limpiar overlays de rutas
  void _clearRouteOverlays() {
    final removedMarkers =
        _markers
            .where(
              (marker) =>
                  marker.markerId.value.startsWith('route_') ||
                  marker.markerId.value.startsWith('bus-'),
            )
            .length;

    final removedPolylines =
        _polylines
            .where((polyline) => polyline.polylineId.value.contains('route'))
            .length;

    _markers.removeWhere(
      (marker) =>
          marker.markerId.value.startsWith('route_') ||
          marker.markerId.value.startsWith('bus-'),
    );
    _polylines.removeWhere(
      (polyline) => polyline.polylineId.value.contains('route'),
    );

    print(
      '🧹 Limpieza: $removedMarkers marcadores, $removedPolylines polylines',
    );
  }

  // Limpiar ruta seleccionada y volver al mapa general
  void clearSelectedRoute() {
    print('🗑️ Limpiando ruta seleccionada');
    _selectedRoute = null;
    _clearRouteOverlays();
    notifyListeners();
  }

  // Decodificar polyline (con mejor manejo de errores)
  List<LatLng> _decodePolyline(String polyline) {
    if (_isPlaceholder(polyline)) {
      print('⚠️ Polyline es placeholder, saltando decodificación');
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

        final latValue = lat / 1e5;
        final lngValue = lng / 1e5;

        // Validar coordenadas
        if (latValue >= -90 &&
            latValue <= 90 &&
            lngValue >= -180 &&
            lngValue <= 180) {
          points.add(LatLng(latValue, lngValue));
        }
      }

      print('✅ Polyline decodificado exitosamente: ${points.length} puntos');
      return points;
    } catch (e) {
      print('❌ Error decodificando polyline: $e');
      return [];
    }
  }

  // Helper para color
  Color _getColorFromHex(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) return Colors.blue;
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }
}
