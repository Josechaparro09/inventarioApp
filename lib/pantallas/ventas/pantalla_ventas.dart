import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../modelos/venta.dart';
import '../../widgets/venta_widget.dart';

class PantallaVentas extends StatelessWidget {
  final CollectionReference _ventasCollection =
      FirebaseFirestore.instance.collection('ventas');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ventas'),
      ),
      body: StreamBuilder(
        stream: _ventasCollection.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Ocurrió un error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // Verifica que snapshot.data no sea null y que tenga documentos
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No hay ventas disponibles.'));
          }

          final ventas = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;

            return Venta(
              id: doc.id,
              idProducto: data['idProducto'] ?? 'Desconocido',
              cantidadVendida: data['cantidadVendida'] ?? 0,
              fechaVenta: (data['fechaVenta'] as Timestamp).toDate(),
            );
          }).toList();

          return ListView.builder(
            itemCount: ventas.length,
            itemBuilder: (context, index) {
              final venta = ventas[index];
              return VentaWidget(venta: venta);
            },
          );
        },
      ),
    );
  }
}
