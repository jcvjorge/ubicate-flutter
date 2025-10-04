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
  bool _isDisposed = false;
  bool _hasInitialized = false;

  static const LatLng _limaCenter = LatLng(-12.0464, -77.0428);
  static Position? _lastKnownPosition;

  @override
  void initState() {
    super.initState();
    _quickInitialize();
  }

  void _quickInitialize() {
    if (_lastKnownPosition != null) {
      setState(() {
        _currentPosition = _lastKnownPosition;
        _hasInitialized = true;
      });
      _updateLocationInBackground();
    } else {
      _initializeLocation();
    }
  }

  Future<void> _updateLocationInBackground() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      if (!_isDisposed && mounted) {
        setState(() => _currentPosition = position);
        _lastKnownPosition = position;
        _moveCameraToPosition(position);
      }
    } catch (e) {
      debugPrint('Error actualizando ubicación: $e');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _stopTracking();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    if (_isDisposed) return;

    await _requestPermissions();

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!_isDisposed && mounted) {
        setState(() {
          _currentPosition = position;
          _hasInitialized = true;
        });
        _lastKnownPosition = position;
        _moveCameraToPosition(position);
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        setState(() {
          _currentPosition = Position(
            latitude: _limaCenter.latitude,
            longitude: _limaCenter.longitude,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );
          _hasInitialized = true;
        });
      }
    }
  }

  Future<void> _requestPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
  }

  void _moveCameraToPosition(Position position) {
    if (_isDisposed || _mapController == null) return;
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
    if (_isDisposed || !mounted) return;

    final authProvider = context.read<AuthProvider>();

    if (!authProvider.firebaseConnected) {
      _showSnackBar('Firebase no conectado', Colors.red);
      return;
    }

    setState(() => _isTracking = true);

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((position) {
      if (!_isDisposed && mounted) {
        setState(() => _currentPosition = position);
        _lastKnownPosition = position;
        _moveCameraToPosition(position);
      }
    });

    _locationTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_isDisposed && _currentPosition != null) {
        _sendLocationToFirebase();
      }
    });

    _showSnackBar('Transmisión iniciada', Colors.green);
  }

  void _stopTracking() {
    if (_isDisposed) return;

    if (mounted) {
      setState(() => _isTracking = false);
    }

    _positionStream?.cancel();
    _positionStream = null;
    _locationTimer?.cancel();
    _locationTimer = null;

    if (mounted && !_isDisposed) {
      _showSnackBar('Transmisión detenida', Colors.orange);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (_isDisposed || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _sendLocationToFirebase() async {
    if (_isDisposed || _currentPosition == null || !mounted) return;

    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;

    if (user?.empresaId == null) return;

    try {
      await authProvider.firebaseService.updateBusLocation(
        empresaId: user!.empresaId!,
        busId: user.busId ?? 'default-bus',
        latitud: _currentPosition!.latitude,
        longitud: _currentPosition!.longitude,
        velocidad: _currentPosition!.speed * 3.6,
      );
    } catch (e) {
      debugPrint('Error enviando ubicación: $e');
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
              if (!_hasInitialized)
                Container(
                  color: Colors.grey[100],
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Preparando mapa...',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              else
                GoogleMap(
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
                  mapToolbarEnabled: false,
                  compassEnabled: true,
                  onMapCreated: (controller) {
                    if (!_isDisposed) {
                      _mapController = controller;
                    }
                  },
                ),

              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white, Colors.white.withOpacity(0.8)],
                    ),
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
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (!_isDisposed && mounted) {
                            Navigator.pop(context);
                          }
                        },
                        icon: const Icon(Icons.arrow_back),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          elevation: 2,
                        ),
                      ),
                      const SizedBox(width: 12),
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
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        _isTracking
                                            ? Colors.green
                                            : Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isTracking ? 'En línea' : 'Fuera de línea',
                                  style: TextStyle(
                                    color:
                                        _isTracking
                                            ? Colors.green
                                            : Colors.grey,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              authProvider.firebaseConnected
                                  ? Colors.green
                                  : Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              authProvider.firebaseConnected
                                  ? Icons.wifi
                                  : Icons.wifi_off,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              authProvider.firebaseConnected ? 'OK' : 'OFF',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Positioned(
                bottom: 32,
                left: 16,
                right: 16,
                child: ElevatedButton(
                  onPressed: () {
                    if (!_isDisposed && mounted) {
                      _isTracking ? _stopTracking() : _startTracking();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isTracking ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isTracking
                            ? Icons.stop_circle
                            : Icons.play_circle_fill,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isTracking ? 'Detener' : 'Iniciar',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Positioned(
                right: 16,
                bottom: 100,
                child: FloatingActionButton(
                  heroTag: 'center',
                  mini: true,
                  backgroundColor: Colors.white,
                  elevation: 4,
                  onPressed: () {
                    if (!_isDisposed && _currentPosition != null) {
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
