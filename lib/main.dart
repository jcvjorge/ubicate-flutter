import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/company_provider.dart';
import 'presentation/providers/routes_provider.dart';
import 'presentation/providers/map_provider.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/driver/driver_home_screen.dart';
import 'presentation/screens/driver/driver_map_screen.dart';
import 'presentation/screens/main/main_screen.dart';
import 'presentation/screens/user/routes_list_screen.dart';
// ❌ REMOVIDO: import 'presentation/screens/user/companies_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CompanyProvider()),
        ChangeNotifierProvider(create: (_) => RoutesProvider()),
        ChangeNotifierProvider(create: (_) => MapProvider()),
      ],
      child: MaterialApp(
        title: 'Ubicate - Bus Tracker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(centerTitle: true, elevation: 2),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/driver-home': (context) => const DriverHomeScreen(),
          '/driver-map': (context) => const DriverMapScreen(),
          '/main': (context) => const MainScreen(),
          '/routes': (context) => const RoutesListScreen(),
          // ❌ REMOVIDO: '/companies': (context) => const CompaniesListScreen(),
        },
      ),
    );
  }
}
