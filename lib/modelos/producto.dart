class Producto {
  final String id;
  final String nombre;
  final double precio;
  final int cantidad;

  Producto({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.cantidad,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'precio': precio,
      'cantidad': cantidad,
    };
  }

  factory Producto.fromMap(Map<String, dynamic> map, String id) {
    return Producto(
      id: id,
      nombre: map['nombre'] ?? '',
      precio: (map['precio'] is int)
          ? (map['precio'] as int).toDouble()
          : map['precio'] ?? 0.0,
      cantidad: map['cantidad'] ?? 0,
    );
  }

  static toStringasFixed(int i) {}
}
