import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  bool _hasAutoNavigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAutoNavigation();
    });
  }

  void _checkAutoNavigation() async {
    if (!mounted || _hasAutoNavigated) return;

    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;

    if (user?.empresaId != null) {
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted || _hasAutoNavigated) return;

      int attempts = 0;
      while (!authProvider.firebaseConnected && attempts < 10) {
        await Future.delayed(const Duration(milliseconds: 500));
        attempts++;
        if (!mounted) return;
      }

      if (authProvider.firebaseConnected || attempts >= 10) {
        _hasAutoNavigated = true;
        Navigator.pushNamed(context, '/driver-map');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.currentUser;

        final bool hasCompany = user?.empresaId != null;
        final bool firebaseReady = authProvider.firebaseConnected;
        final bool isReady = hasCompany && firebaseReady;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Conductor'),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await authProvider.logout();
                  if (!mounted) return;
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue,
                    child: Text(
                      user?.nombre.substring(0, 1).toUpperCase() ?? 'C',
                      style: const TextStyle(
                        fontSize: 40,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    '¡Bienvenido, ${user?.nombre ?? 'Conductor'}!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),

                  Card(
                    color:
                        isReady
                            ? Colors.green[50]
                            : firebaseReady
                            ? Colors.blue[50]
                            : Colors.orange[50],
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          if (isReady && !_hasAutoNavigated) ...[
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            const Text(
                              'Iniciando mapa...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ] else ...[
                            Icon(
                              isReady
                                  ? Icons.gps_fixed
                                  : firebaseReady
                                  ? Icons.wifi
                                  : Icons.wifi_off,
                              color:
                                  isReady
                                      ? Colors.green
                                      : firebaseReady
                                      ? Colors.blue
                                      : Colors.orange,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _getStatusTitle(hasCompany, firebaseReady),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color:
                                    isReady
                                        ? Colors.green[700]
                                        : firebaseReady
                                        ? Colors.blue[700]
                                        : Colors.orange[700],
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            _getStatusDescription(
                              hasCompany,
                              firebaseReady,
                              _hasAutoNavigated,
                            ),
                            style: TextStyle(
                              color:
                                  isReady
                                      ? Colors.green[600]
                                      : firebaseReady
                                      ? Colors.blue[600]
                                      : Colors.orange[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Información del Servicio',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            Icons.person,
                            'Conductor',
                            '${user?.nombre ?? ''} ${user?.apellido ?? ''}',
                          ),
                          const Divider(),
                          _buildInfoRow(
                            Icons.business,
                            'Empresa ID',
                            user?.empresaId ?? 'Sin asignar',
                            isGood: user?.empresaId != null,
                          ),
                          const Divider(),
                          _buildInfoRow(
                            Icons.directions_bus,
                            'Unidad',
                            user?.busPlate ?? 'No asignada',
                            isOptional: false,
                          ),
                          if (user?.telefono != null) ...[
                            const Divider(),
                            _buildInfoRow(
                              Icons.phone,
                              'Teléfono',
                              user!.telefono!,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed:
                          (isReady && !_hasAutoNavigated)
                              ? () {
                                _hasAutoNavigated = true;
                                Navigator.pushNamed(context, '/driver-map');
                              }
                              : null,
                      icon: Icon(
                        isReady
                            ? Icons.navigation
                            : firebaseReady
                            ? Icons.hourglass_empty
                            : Icons.wifi_off,
                      ),
                      label: Text(
                        _getButtonText(
                          hasCompany,
                          firebaseReady,
                          _hasAutoNavigated,
                        ),
                        style: const TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isReady
                                ? Colors.green
                                : firebaseReady
                                ? Colors.blue
                                : Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  if (!hasCompany) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red[600], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Contacta a tu administrador para asignar empresa',
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getStatusTitle(bool hasCompany, bool firebaseReady) {
    if (!hasCompany) return 'Sin Empresa Asignada';
    if (!firebaseReady) return 'Conectando...';
    return 'Sistema Listo';
  }

  String _getStatusDescription(
    bool hasCompany,
    bool firebaseReady,
    bool hasNavigated,
  ) {
    if (!hasCompany) return 'Necesitas empresa asignada para continuar';
    if (!firebaseReady) return 'Conectando con sistema de ubicación...';
    if (hasNavigated) return 'Cargando mapa de conducción...';
    return 'Listo para iniciar recorrido';
  }

  String _getButtonText(
    bool hasCompany,
    bool firebaseReady,
    bool hasNavigated,
  ) {
    if (!hasCompany) return 'Sin Empresa';
    if (!firebaseReady) return 'Conectando...';
    if (hasNavigated) return 'Cargando...';
    return 'Ir al Mapa';
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isGood = true,
    bool isOptional = false,
  }) {
    Color iconColor =
        isOptional
            ? Colors.grey[400]!
            : isGood
            ? Colors.grey[600]!
            : Colors.red[400]!;

    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isOptional) ...[
                    const SizedBox(width: 4),
                    Text(
                      '(opcional)',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[400],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isOptional ? Colors.grey[500] : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
