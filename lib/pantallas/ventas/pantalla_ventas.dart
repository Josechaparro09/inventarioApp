// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

        // Actualiza la cantidad de producto en el inventario
        batch.update(productoRef, {
          'cantidad': cantidadActual - cantidadVendida,
        });

        double precioFinal = producto.precio * cantidadVendida;

        // Registra la venta en la colección "ventas"
        batch.set(
          FirebaseFirestore.instance.collection('ventas').doc(),
          {
            'idProducto': producto.id,
            'nombreProducto': producto.nombre,
            'cantidadVendida': cantidadVendida,
            'precioFinal': precioFinal,
            'fechaVenta': Timestamp.now(),
          },
        );
      }

      // Commit the batch
      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venta realizada con éxito')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ventas'),
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
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                        child: Text(
                            'Error al cargar los productos: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                        child: Text(
                            'No hay productos disponibles en el inventario.'));
                  }

                  final productos = snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Producto.fromMap(data);
                  }).toList();

                  return Column(
                    children: productos.map((producto) {
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 12.0),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16.0),
                          title: Text(
                            producto.nombre,
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                              'Precio: \$${producto.precio.toStringAsFixed(2)}'),
                          trailing: productosSeleccionados.containsKey(producto)
                              ? IconButton(
                                  icon: Icon(Icons.remove_circle,
                                      color: Colors.red),
                                  onPressed: () =>
                                      _eliminarProductoSeleccionado(producto),
                                )
                              : IconButton(
                                  icon: Icon(Icons.add_circle,
                                      color: Colors.teal),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: Text('Cantidad a vender'),
                                          content: TextField(
                                            controller: _cantidadController,
                                            decoration: InputDecoration(
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
                                              child: Text('Agregar'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                _cantidadController.clear();
                                                Navigator.of(context).pop();
                                              },
                                              child: Text('Cancelar'),
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
              SizedBox(height: 20),
              if (productosSeleccionados.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Productos seleccionados:',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    ...productosSeleccionados.entries.map((entry) {
                      return ListTile(
                        title: Text('${entry.key.nombre}'),
                        subtitle: Text('Cantidad: ${entry.value}'),
                        trailing: Text(
                          'Total: \$${(entry.key.precio * entry.value).toStringAsFixed(2)}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
                    SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: _realizarVenta,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30.0, vertical: 15.0),
                          backgroundColor: Colors.teal,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0)),
                        ),
                        child: Text(
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
