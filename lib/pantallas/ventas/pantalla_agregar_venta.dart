import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PantallaAgregarVenta extends StatefulWidget {
  @override
  _PantallaAgregarVentaState createState() => _PantallaAgregarVentaState();
}

class _PantallaAgregarVentaState extends State<PantallaAgregarVenta> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _idProductoController = TextEditingController();
  final TextEditingController _cantidadController = TextEditingController();

  void _realizarVenta() async {
    if (_formKey.currentState!.validate()) {
      final idProducto = _idProductoController.text;
      final cantidadVendida = int.parse(_cantidadController.text);

      FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentReference productoRef =
            FirebaseFirestore.instance.collection('productos').doc(idProducto);

        DocumentSnapshot productoSnapshot = await transaction.get(productoRef);
        if (!productoSnapshot.exists) {
          throw Exception("El producto no existe!");
        }

        int cantidadActual = productoSnapshot['cantidad'];

        if (cantidadActual < cantidadVendida) {
          throw Exception("Cantidad insuficiente en inventario!");
        }

        transaction.update(productoRef, {
          'cantidad': cantidadActual - cantidadVendida,
        });

        await FirebaseFirestore.instance.collection('ventas').add({
          'idProducto': idProducto,
          'cantidadVendida': cantidadVendida,
          'fechaVenta': Timestamp.now(),
        });
      }).then((value) {
        Navigator.pop(context);
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al realizar venta: $error')));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Realizar Venta'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _idProductoController,
                decoration: InputDecoration(labelText: 'ID del Producto'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el ID del producto';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _cantidadController,
                decoration: InputDecoration(labelText: 'Cantidad Vendida'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa la cantidad vendida';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _realizarVenta,
                child: Text('Realizar Venta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
