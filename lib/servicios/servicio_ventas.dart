import 'package:cloud_firestore/cloud_firestore.dart';
import '../modelos/venta.dart';

class ServicioVentas {
  final CollectionReference _ventasCollection =
      FirebaseFirestore.instance.collection('ventas');

  Future<void> realizarVenta(Venta venta) async {
    await _ventasCollection.add(venta.toMap());
  }

  Stream<List<Venta>> obtenerVentas() {
    return _ventasCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Venta.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }
}
