import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/company_provider.dart';
import '../../providers/routes_provider.dart';
import '../../providers/map_provider.dart';
import '../user/user_map_screen.dart';
import '../user/routes_list_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Cargar todos los datos al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoutesProvider>().loadAllData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Ubicate'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          // Indicador de carga global
          Consumer<RoutesProvider>(
            builder: (context, routesProvider, _) {
              if (routesProvider.isLoading) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context, user),
      body: const UserMapScreen(),
    );
  }

  Widget _buildDrawer(BuildContext context, user) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.blueAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            accountName: Text(user?.nombre ?? 'Usuario'),
            accountEmail: Text(user?.email ?? 'usuario@gmail.com'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user?.nombre?.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.map, color: Colors.blue),
                  title: const Text('Mapa Principal'),
                  subtitle: const Text('Vista general de buses'),
                  onTap: () {
                    Navigator.pop(context);
                    // Limpiar cualquier ruta seleccionada
                    context.read<MapProvider>().clearSelectedRoute();
                  },
                ),
                const Divider(),
                
                // ✅ SOLO RUTAS - SIN EMPRESAS
                Consumer<RoutesProvider>(
                  builder: (context, routesProvider, _) {
                    final totalRutas = routesProvider.todasLasRutas.length;
                    final totalEmpresas = routesProvider.empresas.length;
                    
                    return ListTile(
                      leading: const Icon(Icons.route, color: Colors.orange),
                      title: const Text('Explorar Rutas'),
                      subtitle: Text('$totalRutas rutas de $totalEmpresas empresas'),
                      trailing: totalRutas > 0 
                          ? Chip(
                              label: Text('$totalRutas'),
                              backgroundColor: Colors.orange.withOpacity(0.1),
                            )
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RoutesListScreen(),
                          ),
                        );
                      },
                    );
                  },
                ),
                
                ListTile(
                  leading: const Icon(Icons.favorite, color: Colors.red),
                  title: const Text('Favoritos'),
                  subtitle: const Text('Rutas guardadas'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Próximamente')),
                    );
                  },
                ),
                
                ListTile(
                  leading: const Icon(Icons.history, color: Colors.grey),
                  title: const Text('Historial'),
                  subtitle: const Text('Búsquedas recientes'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Próximamente')),
                    );
                  },
                ),
                
                const Divider(),
                
                ListTile(
                  leading: const Icon(Icons.settings, color: Colors.grey),
                  title: const Text('Configuración'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Próximamente')),
                    );
                  },
                ),
                
                ListTile(
                  leading: const Icon(Icons.info_outline, color: Colors.grey),
                  title: const Text('Acerca de'),
                  onTap: () {
                    Navigator.pop(context);
                    _showAboutDialog(context);
                  },
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await context.read<AuthProvider>().logout();
                if (!context.mounted) return;
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Ubicate',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.directions_bus, size: 48, color: Colors.blue),
      children: [
        const Text('Aplicación para el seguimiento de buses en tiempo real.'),
        const SizedBox(height: 8),
        const Text('Desarrollado con Flutter y Firebase.'),
      ],
    );
  }
}