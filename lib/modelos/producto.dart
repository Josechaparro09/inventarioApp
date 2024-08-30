class Producto {
  String id;
  String nombre;
  double precio;
  int cantidad;

  Producto({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.cantidad,
  });

  factory Producto.fromMap(Map<String, dynamic> data) {
    return Producto(
      id: data['id'],
      nombre: data['nombre'],
      precio: data['precio'],
      cantidad: data['cantidad'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'precio': precio,
      'cantidad': cantidad,
    };
  }
}
