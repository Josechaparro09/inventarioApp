import 'package:flutter/material.dart';
import 'inventario/pantalla_inventario.dart';
import 'inventario/pantalla_agregar_producto.dart';
import 'ventas/pantalla_ventas.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'autenticacion/pantalla_login.dart';

class PantallaPrincipal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Menú Principal'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          ListTile(
            leading: Icon(Icons.inventory),
            title: Text('Gestionar Inventario'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PantallaInventario()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.add),
            title: Text('Agregar Producto'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => PantallaAgregarProducto()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.shopping_cart),
            title: Text('Realizar Venta'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PantallaVentas()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Cerrar Sesión'),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => PantallaLogin()),
              );
            },
          ),
        ],
      ),
    );
  }
}
