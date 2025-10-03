import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.currentUser;
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Modo Chofer'),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await authProvider.logout();
                  if (!context.mounted) return;
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
                  
                  // 🔥 ESTADO DE FIREBASE
                  Card(
                    color: authProvider.firebaseConnected ? Colors.green[50] : Colors.red[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            authProvider.firebaseConnected 
                                ? Icons.cloud_done 
                                : Icons.cloud_off,
                            color: authProvider.firebaseConnected 
                                ? Colors.green 
                                : Colors.red,
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  authProvider.firebaseConnected 
                                      ? '✅ Firebase Conectado'
                                      : '❌ Firebase Desconectado',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: authProvider.firebaseConnected 
                                        ? Colors.green[700] 
                                        : Colors.red[700],
                                  ),
                                ),
                                Text(
                                  authProvider.firebaseConnected 
                                      ? 'Listo para transmitir ubicación'
                                      : 'No se puede transmitir ubicación',
                                  style: TextStyle(
                                    color: authProvider.firebaseConnected 
                                        ? Colors.green[600] 
                                        : Colors.red[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // INFORMACIÓN DEL USUARIO
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildInfoRow(Icons.person, 'Nombre', user?.nombre ?? 'N/A'),
                          const Divider(),
                          _buildInfoRow(Icons.email, 'Email', user?.email ?? 'N/A'),
                          const Divider(),
                          _buildInfoRow(Icons.business, 'Empresa', user?.empresaId ?? 'Sin asignar'),
                          const Divider(),
                          _buildInfoRow(Icons.directions_bus, 'Bus ID', user?.busId ?? 'Sin asignar'),
                          const Divider(),
                          _buildInfoRow(Icons.confirmation_number, 'Placa', user?.busPlate ?? 'N/A'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // BOTÓN PARA IR AL MAPA
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/driver-map');
                    },
                    icon: const Icon(Icons.map),
                    label: const Text('Iniciar Transmisión GPS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: authProvider.firebaseConnected 
                          ? Colors.green 
                          : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                  
                  if (!authProvider.firebaseConnected) ...[
                    const SizedBox(height: 16),
                    const Text(
                      '⚠️ Firebase no está conectado. Contacta al administrador.',
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}