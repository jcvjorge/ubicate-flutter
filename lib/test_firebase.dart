import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

class FirebaseTestScreen extends StatefulWidget {
  @override
  _FirebaseTestScreenState createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  String _status = "Inicializando...";
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  @override
  void initState() {
    super.initState();
    _testFirebase();
  }

  Future<void> _testFirebase() async {
    try {
      // 1. Verificar inicialización de Firebase
      setState(() => _status = "🔥 Verificando Firebase...");
      await Future.delayed(Duration(seconds: 1));
      
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      
      setState(() => _status = "✅ Firebase inicializado correctamente");
      await Future.delayed(Duration(seconds: 1));

      // 2. Test Realtime Database
      setState(() => _status = "📊 Probando Realtime Database...");
      
      DatabaseReference testRef = _database.ref().child('test');
      await testRef.set({
        'mensaje': 'Prueba desde Flutter',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'usuario': 'test_user'
      });
      
      setState(() => _status = "✅ Datos escritos en Database");
      await Future.delayed(Duration(seconds: 1));

      // 3. Leer datos
      setState(() => _status = "📖 Leyendo datos...");
      DataSnapshot snapshot = await testRef.get();
      
      if (snapshot.exists) {
        setState(() => _status = "✅ Datos leídos: ${snapshot.value}");
      } else {
        setState(() => _status = "❌ No se encontraron datos");
      }

    } catch (e) {
      setState(() => _status = "❌ Error: $e");
      print("Error en test Firebase: $e");
    }
  }

  Future<void> _testAuth() async {
    try {
      setState(() => _status = "🔐 Probando Authentication...");
      
      // Crear usuario de prueba
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: "test${DateTime.now().millisecondsSinceEpoch}@test.com",
        password: "test123456"
      );
      
      setState(() => _status = "✅ Usuario creado: ${userCredential.user?.email}");
      
      // Cerrar sesión
      await FirebaseAuth.instance.signOut();
      setState(() => _status = "✅ Test Authentication completado");
      
    } catch (e) {
      setState(() => _status = "❌ Error Auth: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🧪 Test Firebase'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.science,
              size: 80,
              color: Colors.blue,
            ),
            SizedBox(height: 20),
            Text(
              'Estado de Firebase',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _status,
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _testFirebase,
              child: Text('🔄 Repetir Test Database'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _testAuth,
              child: Text('🔐 Test Authentication'),
            ),
          ],
        ),
      ),
    );
  }
}