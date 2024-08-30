import 'package:flutter/material.dart';
import '../modelos/producto.dart';

class ProductoWidget extends StatelessWidget {
  final Producto producto;

  ProductoWidget({required this.producto});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(producto.nombre),
      subtitle:
          Text('Precio: \$${producto.precio}, Cantidad: ${producto.cantidad}'),
      trailing: IconButton(
        icon: Icon(Icons.delete),
        onPressed: () {
          // Implementar eliminación de producto
        },
      ),
    );
  }
}
