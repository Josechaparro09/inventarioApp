import 'package:cloud_firestore/cloud_firestore.dart';
import '../modelos/producto.dart';

class LogicaInventario {
  final String usuario;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  LogicaInventario(this.usuario);

  Stream<QuerySnapshot> getProductStream() {
    return _firestore
        .collection('productos')
        .where('usuario', isEqualTo: usuario)
        .snapshots();
  }

  Future<void> addProduct(String nombre, String precio, String cantidad) async {
    try {
      await _firestore.collection('productos').add({
        'nombre': nombre,
        'precio': double.parse(precio),
        'cantidad': int.parse(cantidad),
        'usuario': usuario,
      });
    } catch (e) {
      throw Exception('Error al agregar producto: $e');
    }
  }

  Future<void> updateProduct(
      String productId, String nombre, String precio, String cantidad) async {
    try {
      await _firestore.collection('productos').doc(productId).update({
        'nombre': nombre,
        'precio': double.parse(precio),
        'cantidad': int.parse(cantidad),
      });
    } catch (e) {
      throw Exception('Error al actualizar producto: $e');
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _firestore.collection('productos').doc(productId).delete();
    } catch (e) {
      throw Exception('Error al eliminar producto: $e');
    }
  }

  Producto convertToProducto(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Producto(
      id: doc.id,
      nombre: data['nombre'],
      precio: data['precio'].toDouble(),
      cantidad: data['cantidad'],
    );
  }
}
