import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../modelos/producto.dart';

class PantallaVentas extends StatefulWidget {
  const PantallaVentas({super.key});

  @override
  _PantallaVentasState createState() => _PantallaVentasState();
}

class _PantallaVentasState extends State<PantallaVentas> {
  final Map<Producto, int> productosSeleccionados = {};
  final TextEditingController _cantidadController = TextEditingController();

  void _agregarProductoSeleccionado(Producto producto, int cantidad) {
    if (producto.id == null || producto.id.isEmpty) {
      print('Error: Producto ID está vacío');
      return; // O lanza una excepción dependiendo de cómo quieres manejar esto
    }

    setState(() {
      productosSeleccionados[producto] = cantidad;
    });
  }

  void _eliminarProductoSeleccionado(Producto producto) {
    setState(() {
      productosSeleccionados.remove(producto);
    });
  }

  Future<void> _realizarVenta() async {
    if (productosSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor selecciona al menos un producto')),
      );
      return;
    }

    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (var entry in productosSeleccionados.entries) {
        final producto = entry.key;
        final cantidadVendida = entry.value;

        if (producto.id.isEmpty) {
          throw Exception('El ID del producto no puede estar vacío');
        }

        DocumentReference productoRef =
            FirebaseFirestore.instance.collection('productos').doc(producto.id);

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

      await batch.commit();

      // Mostrar ventana emergente de éxito
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Venta realizada'),
            content: const Text('La venta se realizó con éxito.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Aceptar'),
              ),
            ],
          );
        },
      );

      setState(() {
        productosSeleccionados.clear();
        _cantidadController.clear();
      });
    } catch (e, stacktrace) {
      print("Error al realizar la venta: $e");
      print("Stacktrace: $stacktrace");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Error al realizar la venta: $e\nDetalles: $stacktrace')),
      );
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
      FirebaseFirestore.instance.collection('ventas').doc(),
      {
        'idProducto': producto.id,
        'nombreProducto': producto.nombre,
        'cantidadVendida': cantidadVendida,
        'precioFinal': precioFinal,
        'fechaVenta': Timestamp.now(),
        'usuario': FirebaseAuth.instance.currentUser!.uid,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1), // Fondo en color crema
      appBar: AppBar(
        title: const Text('Ventas'),
        backgroundColor: const Color(0xFFFFA726), // Color de la AppBar
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('productos')
                    .where('usuario', isEqualTo: usuario)
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                        child: Text(
                            'Error al cargar los productos: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                        child: Text(
                            'No hay productos disponibles en el inventario.'));
                  }

                  final productos = snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Producto.fromMap(
                        data, doc.id); // Pasando el ID correctamente
                  }).toList();

                  return Column(
                    children: productos.map((producto) {
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 12.0),
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16.0),
                          title: Text(
                            producto.nombre ?? 'Producto sin nombre',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF212121)),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Precio: \$${producto.precio.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    color: Color(0xFF757575), fontSize: 16),
                              ),
                              Text(
                                'Cantidad disponible: ${producto.cantidad}',
                                style: const TextStyle(
                                    color: Color(0xFF757575), fontSize: 16),
                              ),
                            ],
                          ),
                          trailing: productosSeleccionados.containsKey(producto)
                              ? IconButton(
                                  icon: const Icon(Icons.remove_circle,
                                      color: Colors.red),
                                  onPressed: () =>
                                      _eliminarProductoSeleccionado(producto),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.add_circle,
                                      color: Color.fromRGBO(255, 167, 38, 1)),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title:
                                              const Text('Cantidad a vender'),
                                          content: TextField(
                                            controller: _cantidadController,
                                            decoration: const InputDecoration(
                                              labelText: 'Cantidad',
                                              border: OutlineInputBorder(),
                                            ),
                                            keyboardType: TextInputType.number,
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                final cantidad = int.tryParse(
                                                        _cantidadController
                                                            .text) ??
                                                    0;
                                                if (cantidad > 0) {
                                                  _agregarProductoSeleccionado(
                                                      producto, cantidad);
                                                  _cantidadController.clear();
                                                  Navigator.of(context).pop();
                                                }
                                              },
                                              child: const Text('Agregar'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                _cantidadController.clear();
                                                Navigator.of(context).pop();
                                              },
                                              child: const Text('Cancelar'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 20),
              if (productosSeleccionados.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Productos seleccionados:',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ...productosSeleccionados.entries.map((entry) {
                      final producto = entry.key;
                      final cantidad = entry.value;

                      if (producto != null && cantidad != null) {
                        return ListTile(
                          title: Text(producto.nombre ?? 'Producto sin nombre'),
                          subtitle: Text('Cantidad: $cantidad'),
                          trailing: Text(
                            'Total: \$${(producto.precio * cantidad).toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    }).toList(),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: _realizarVenta,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30.0, vertical: 15.0),
                          backgroundColor:
                              const Color.fromRGBO(255, 167, 38, 1),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0)),
                        ),
                        child: const Text(
                          'Realizar Venta',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
