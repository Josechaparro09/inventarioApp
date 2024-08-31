import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:inventario/pantallas/ventas/pantalla_agregar_venta.dart';
import 'package:inventario/pantallas/ventas/pantalla_ventas.dart';
import 'firebase_options.dart';
import 'pantallas/autenticacion/pantalla_login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App de Inventario y Ventas',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: PantallaVentas(),
      debugShowCheckedModeBanner: false,
    );
  }
}
