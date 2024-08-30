import 'package:flutter/material.dart';
import '../modelos/venta.dart';

class VentaWidget extends StatelessWidget {
  final Venta venta;

  VentaWidget({required this.venta});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('ID Producto: ${venta.idProducto}'),
      subtitle: Text(
          'Cantidad Vendida: ${venta.cantidadVendida}, Fecha: ${venta.fechaVenta}'),
    );
  }
}
