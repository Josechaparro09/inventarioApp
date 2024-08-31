import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventario/modelos/producto.dart';

class ServicioInventario {
  final CollectionReference _productosCollection =
      FirebaseFirestore.instance.collection('productos');

  // Obtén el ID del usuario actual
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> agregarProducto(Producto producto) async {
    await _productosCollection.add(producto.toMap());
  }

  Future<void> actualizarProducto(String id, Producto producto) async {
    await _productosCollection.doc(id).update(producto.toMap());
  }

  Future<void> eliminarProducto(String id) async {
    await _productosCollection.doc(id).delete();
  }

  // Modificación para obtener productos por user_id
  Stream<List<Producto>> obtenerProductos() {
    return _productosCollection
        .where('user_id',
            isEqualTo: userId) // Filtra por el ID del usuario actual
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Producto.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }
}
