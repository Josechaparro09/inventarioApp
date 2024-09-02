import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:inventario/pantallas/PantallaConfiguracion/pantalla_configuracion.dart';
import 'package:inventario/pantallas/inventario/pantalla_inventario.dart';
import 'package:inventario/pantallas/pantalla_principal.dart';
import 'package:inventario/pantallas/autenticacion/pantalla_registro.dart';
import 'package:inventario/splash_page.dart';
import 'firebase_options.dart';

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
    return MaterialApp(
      title: 'App de Inventario y Ventas',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashPage(), // Puedes definir la pantalla inicial aquí
      routes: {
        '/principal': (context) => PantallaPrincipal(),
        '/registro': (context) => PantallaRegistro(),
        '/inventario': (context) => PantallaInventario(),
        '/configuracion': (context) => PantallaConfiguracion(),
      },
    );
  }
}
