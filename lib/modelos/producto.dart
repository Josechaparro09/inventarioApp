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

  // Método para convertir un mapa de datos en una instancia de Producto
  factory Producto.fromMap(Map<String, dynamic> data) {
    return Producto(
      id: data['id'] ?? '',
      nombre: data['nombre'] ?? '',
      precio: data['precio']?.toDouble() ?? 0.0,
      cantidad: data['cantidad']?.toInt() ?? 0,
    );
  }

  // Método para convertir una instancia de Producto en un mapa
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'precio': precio,
      'cantidad': cantidad,
    };
  }
}
