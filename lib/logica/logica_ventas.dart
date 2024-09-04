import 'package:cloud_firestore/cloud_firestore.dart';
import '../modelos/producto.dart';

class LogicaVentas {
  final String usuario;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  LogicaVentas(this.usuario);

  Stream<QuerySnapshot> getProductStream() {
    return _firestore
        .collection('productos')
        .where('usuario', isEqualTo: usuario)
        .snapshots();
  }

  Future<void> realizarVenta(Map<Producto, int> productosSeleccionados) async {
    WriteBatch batch = _firestore.batch();

    try {
      await _processBatch(batch, productosSeleccionados);
      await batch.commit();
    } catch (e) {
      throw Exception('Error al realizar la venta: $e');
    }
  }

  Future<void> _processBatch(
      WriteBatch batch, Map<Producto, int> productosSeleccionados) async {
    for (var entry in productosSeleccionados.entries) {
      final producto = entry.key;
      final cantidadVendida = entry.value;

      if (producto.id.isEmpty) {
        throw Exception('El ID del producto no puede estar vacío');
      }

      DocumentReference productoRef =
          _firestore.collection('productos').doc(producto.id);
      DocumentSnapshot productoSnapshot = await productoRef.get();

      if (!productoSnapshot.exists) {
        throw Exception("El producto no existe: ${producto.nombre}");
      }

      int cantidadActual = productoSnapshot['cantidad'];

      if (cantidadActual < cantidadVendida) {
        throw Exception(
            "Cantidad insuficiente en inventario para ${producto.nombre}");
      }

      _actualizarInventario(
          batch, productoRef, cantidadActual - cantidadVendida);
      _registrarVenta(batch, producto, cantidadVendida);
    }
  }

  void _actualizarInventario(
      WriteBatch batch, DocumentReference productoRef, int nuevaCantidad) {
    batch.update(productoRef, {
      'cantidad': nuevaCantidad,
    });
  }

  void _registrarVenta(
      WriteBatch batch, Producto producto, int cantidadVendida) {
    double precioFinal = producto.precio * cantidadVendida;

    batch.set(
      _firestore.collection('ventas').doc(),
      {
        'idProducto': producto.id,
        'nombreProducto': producto.nombre,
        'cantidadVendida': cantidadVendida,
        'precioFinal': precioFinal,
        'fechaVenta': Timestamp.now(),
        'usuario': usuario,
      },
    );
  }
}
