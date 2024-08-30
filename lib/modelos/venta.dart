import 'package:cloud_firestore/cloud_firestore.dart';

class Venta {
  String id;
  String idProducto;
  int cantidadVendida;
  DateTime fechaVenta;

  Venta({
    required this.id,
    required this.idProducto,
    required this.cantidadVendida,
    required this.fechaVenta,
  });

  factory Venta.fromMap(Map<String, dynamic> data) {
    return Venta(
      id: data['id'],
      idProducto: data['idProducto'],
      cantidadVendida: data['cantidadVendida'],
      fechaVenta: (data['fechaVenta'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'idProducto': idProducto,
      'cantidadVendida': cantidadVendida,
      'fechaVenta': fechaVenta,
    };
  }
}
