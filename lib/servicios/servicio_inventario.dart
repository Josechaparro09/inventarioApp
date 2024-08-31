import 'package:cloud_firestore/cloud_firestore.dart';
import '../modelos/producto.dart';

class ServicioInventario {
  final CollectionReference _productosCollection =
      FirebaseFirestore.instance.collection('productos');

  Future<void> agregarProducto(Producto producto) async {
    await _productosCollection.add(producto.toMap());
  }

  Future<void> actualizarProducto(String id, Producto producto) async {
    await _productosCollection.doc(id).update(producto.toMap());
  }

  Future<void> eliminarProducto(String id) async {
    await _productosCollection.doc(id).delete();
  }

  Stream<List<Producto>> obtenerProductos() {
    return _productosCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Producto.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }
}
