import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../modelos/producto.dart';
import '../../widgets/producto_widget.dart';

class PantallaInventario extends StatelessWidget {
  final CollectionReference _productosCollection =
      FirebaseFirestore.instance.collection('productos');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inventario'),
      ),
      body: StreamBuilder(
        stream: _productosCollection.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Ocurrió un error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // Verifica que snapshot.data no sea null
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('No hay datos disponibles'));
          }

          final productos = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;

            return Producto(
              id: doc.id,
              nombre: data['nombre'] ?? 'Nombre desconocido',
              precio: data['precio'] != null ? data['precio'].toDouble() : 0.0,
              cantidad: data['cantidad'] ?? 0,
            );
          }).toList();

          return ListView.builder(
            itemCount: productos.length,
            itemBuilder: (context, index) {
              final producto = productos[index];
              return ProductoWidget(producto: producto);
            },
          );
        },
      ),
    );
  }
}
