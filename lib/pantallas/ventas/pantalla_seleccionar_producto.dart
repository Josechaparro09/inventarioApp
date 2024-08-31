import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../modelos/producto.dart';

class PantallaSeleccionarProducto extends StatefulWidget {
  @override
  _PantallaSeleccionarProductoState createState() =>
      _PantallaSeleccionarProductoState();
}

class _PantallaSeleccionarProductoState
    extends State<PantallaSeleccionarProducto> {
  Producto? productoSeleccionado;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ventas'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('productos')
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  print("Error al cargar los productos: ${snapshot.error}");
                  return Center(
                      child: Text(
                          'Error al cargar los productos: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  print("Cargando datos...");
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  print("No hay productos en el inventario.");
                  return Center(
                      child: Text(
                          'No hay productos disponibles en el inventario.'));
                }

                // Imprimir la cantidad de documentos obtenidos
                print(
                    "Cantidad de productos obtenidos: ${snapshot.data!.docs.length}");

                return DropdownButton<Producto>(
                  hint: Text('Selecciona un producto'),
                  value: productoSeleccionado,
                  onChanged: (Producto? nuevoProducto) {
                    setState(() {
                      productoSeleccionado = nuevoProducto;
                    });
                  },
                  items: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    final String nombre = data['nombre'] ?? 'Desconocido';
                    final double precio = data['precio'] is double
                        ? data['precio']
                        : (data['precio'] is int
                            ? (data['precio'] as int).toDouble()
                            : 0.0);
                    final int cantidad = data['cantidad'] ?? 0;

                    print(
                        "Producto: $nombre, Precio: $precio, Cantidad: $cantidad");

                    final producto = Producto(
                      id: doc.id,
                      nombre: nombre,
                      precio: precio,
                      cantidad: cantidad,
                    );

                    return DropdownMenuItem<Producto>(
                      value: producto,
                      child: Text(producto.nombre),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
