import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PantallaAgregarProducto extends StatefulWidget {
  @override
  _PantallaAgregarProductoState createState() =>
      _PantallaAgregarProductoState();
}

class _PantallaAgregarProductoState extends State<PantallaAgregarProducto> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();
  final TextEditingController _cantidadController = TextEditingController();

  void _agregarProducto() async {
    final String nombre = _nombreController.text;
    final double precio = double.tryParse(_precioController.text) ?? 0.0;
    final int cantidad = int.tryParse(_cantidadController.text) ?? 0;
    final usuario = await FirebaseAuth.instance.currentUser?.getIdToken();

    if (nombre.isEmpty || precio <= 0 || cantidad <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Por favor ingrese todos los datos correctamente')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('productos').add({
        'nombre': nombre,
        'precio': precio,
        'cantidad': cantidad,
        'usuario': usuario
      });
      print(usuario);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Producto agregado al inventario con éxito')),
      );

      _nombreController.clear();
      _precioController.clear();
      _cantidadController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al agregar el producto: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agregar Producto al Inventario'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nombreController,
              decoration: InputDecoration(labelText: 'Nombre del Producto'),
            ),
            TextField(
              controller: _precioController,
              decoration: InputDecoration(labelText: 'Precio'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            TextField(
              controller: _cantidadController,
              decoration: InputDecoration(labelText: 'Cantidad'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _agregarProducto,
              child: Text('Agregar Producto'),
            ),
          ],
        ),
      ),
    );
  }
}
