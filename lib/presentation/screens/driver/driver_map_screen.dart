import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../providers/auth_provider.dart';

class DriverMapScreen extends StatefulWidget {
  const DriverMapScreen({super.key});

  @override
  State<DriverMapScreen> createState() => _DriverMapScreenState();
}

class _DriverMapScreenState extends State<DriverMapScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isTracking = false;
  Timer? _locationTimer;
  StreamSubscription<Position>? _positionStream;

  static const LatLng _limaCenter = LatLng(-12.0464, -77.0428);

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void dispose() {
    _stopTracking();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    await _requestPermissions();
    await _getCurrentLocation();
  }

  Future<void> _requestPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permisos de ubicación denegados permanentemente'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() => _currentPosition = position);
      _moveCameraToPosition(position);
    } catch (e) {
      print('Error obteniendo ubicación: $e');
    }
  }

  void _moveCameraToPosition(Position position) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 16,
        ),
      ),
    );
  }

  void _startTracking() {
    final authProvider = context.read<AuthProvider>();
    
    // 🔥 VERIFICAR CONEXIÓN FIREBASE
    if (!authProvider.firebaseConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se puede transmitir: Firebase no está conectado',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 🔥 VERIFICAR DATOS DEL USUARIO
    final user = authProvider.currentUser;
    if (user?.empresaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se puede transmitir: Sin empresa asignada',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (user?.busId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se puede transmitir: Sin bus asignado',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isTracking = true);

    // 🔥 ESCUCHAR CAMBIOS DE UBICACIÓN
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Solo actualizar si se mueve 10 metros
      ),
    ).listen((position) {
      setState(() => _currentPosition = position);
      _moveCameraToPosition(position);
    });

    // 🔥 ENVIAR UBICACIÓN CADA 5 SEGUNDOS
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_currentPosition != null) {
        _sendLocationToFirebase();
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.radio_button_checked, color: Colors.white),
            SizedBox(width: 8),
            Text('📡 Transmisión iniciada a Firebase'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _stopTracking() {
    setState(() => _isTracking = false);
    _positionStream?.cancel();
    _locationTimer?.cancel();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.radio_button_unchecked, color: Colors.white),
              SizedBox(width: 8),
              Text('📡 Transmisión detenida'),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // 🔥 ENVIAR UBICACIÓN A FIREBASE
  Future<void> _sendLocationToFirebase() async {
    if (_currentPosition == null) return;

    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    
    if (user?.empresaId == null || user?.busId == null) {
      print('⚠️ Usuario sin empresaId o busId');
      return;
    }

    try {
      await authProvider.firebaseService.updateBusLocation(
        empresaId: user!.empresaId!,
        busId: user.busId!,
        latitud: _currentPosition!.latitude,
        longitud: _currentPosition!.longitude,
        velocidad: _currentPosition!.speed * 3.6, // m/s a km/h
      );
      
      print('✅ Ubicación enviada: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
    } catch (e) {
      print('❌ Error enviando ubicación a Firebase: $e');
      
      // Mostrar error al usuario
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error enviando ubicación: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.currentUser;
        
        return Scaffold(
          body: Stack(
            children: [
              // 🗺️ MAPA
              _currentPosition == null
                  ? const Center(child: CircularProgressIndicator())
                  : GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                        zoom: 16,
                      ),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      onMapCreated: (controller) => _mapController = controller,
                    ),

              // 📊 TOP BAR CON INFORMACIÓN
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  padding: EdgeInsets.fromLTRB(
                    16,
                    MediaQuery.of(context).padding.top + 8,
                    16,
                    16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bus ${user?.busPlate ?? user?.busNumber ?? "N/A"}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    // 🔥 INDICADOR DE ESTADO
                                    Icon(
                                      _isTracking
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_unchecked,
                                      color: _isTracking ? Colors.green : Colors.grey,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isTracking
                                          ? '📡 Transmitiendo a Firebase'
                                          : '⏸️ Detenido',
                                      style: TextStyle(
                                        color: _isTracking ? Colors.green : Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                // 🔥 INDICADOR DE FIREBASE
                                Row(
                                  children: [
                                    Icon(
                                      authProvider.firebaseConnected
                                          ? Icons.cloud_done
                                          : Icons.cloud_off,
                                      color: authProvider.firebaseConnected 
                                          ? Colors.blue : Colors.red,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      authProvider.firebaseConnected
                                          ? '☁️ Firebase conectado'
                                          : '☁️ Firebase desconectado',
                                      style: TextStyle(
                                        color: authProvider.firebaseConnected 
                                            ? Colors.blue : Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 🎮 BOTÓN DE CONTROL
              Positioned(
                bottom: 32,
                left: 16,
                right: 16,
                child: ElevatedButton.icon(
                  onPressed: _isTracking ? _stopTracking : _startTracking,
                  icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
                  label: Text(
                    _isTracking ? 'Detener Transmisión' : 'Iniciar Transmisión',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isTracking ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              // 🧭 BOTÓN DE CENTRAR
              Positioned(
                right: 16,
                bottom: 100,
                child: FloatingActionButton(
                  heroTag: 'center',
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: () {
                    if (_currentPosition != null) {
                      _moveCameraToPosition(_currentPosition!);
                    }
                  },
                  child: const Icon(Icons.my_location, color: Colors.blue),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}