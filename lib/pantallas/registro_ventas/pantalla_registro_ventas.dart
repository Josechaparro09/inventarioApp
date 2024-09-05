import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PantallaRegistroVentas extends StatefulWidget {
  @override
  _PantallaRegistroVentasState createState() => _PantallaRegistroVentasState();
}

class _PantallaRegistroVentasState extends State<PantallaRegistroVentas> {
  DateTime? _fechaSeleccionada;

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _fechaSeleccionada) {
      setState(() {
        _fechaSeleccionada = picked;
      });
    }
  }

  Future<void> _mostrarDialogoVenta(
      BuildContext context,
      List<dynamic> nombresProductos, // Ahora utiliza nombres en lugar de IDs
      List<dynamic> cantidades,
      double? total,
      DateTime fechaVenta) async {
    List<String> detallesProductos = [];

    for (var i = 0; i < nombresProductos.length; i++) {
      var nombreProducto = nombresProductos[i];
      var cantidadVendida = cantidades[i];

      // Buscar el producto por su nombre en lugar de ID
      QuerySnapshot productoSnapshot = await FirebaseFirestore.instance
          .collection('productos')
          .where('nombre', isEqualTo: nombreProducto)
          .limit(1)
          .get();

      if (productoSnapshot.docs.isNotEmpty) {
        var productoData =
            productoSnapshot.docs.first.data() as Map<String, dynamic>;
        var precioProducto = productoData['precio']?.toDouble() ?? 0.0;

        detallesProductos.add(
            '$nombreProducto - Cantidad: $cantidadVendida - Precio: \$${precioProducto.toStringAsFixed(2)}');
      } else {
        detallesProductos
            .add('Producto no encontrado - Cantidad: $cantidadVendida');
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Factura de Venta'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'Fecha: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(fechaVenta)}'),
              const SizedBox(height: 8),
              const Text('Productos vendidos:'),
              for (var detalle in detallesProductos) Text(detalle),
              const SizedBox(height: 8),
              Text('Total a pagar: \$${(total ?? 0.0).toStringAsFixed(2)}'),
            ],
          ),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Ventas'),
        backgroundColor: const Color(0xFFFFA726),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _fechaSeleccionada == null
                        ? 'Selecciona una fecha'
                        : 'Fecha seleccionada: ${DateFormat('dd/MM/yyyy').format(_fechaSeleccionada!)}',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _seleccionarFecha(context),
                  child: const Text('Seleccionar Fecha'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _fechaSeleccionada == null
                  ? const Center(
                      child: Text('No se ha seleccionado ninguna fecha.'))
                  : StreamBuilder(
                      stream: FirebaseFirestore.instance
                          .collection('ventas')
                          .where('fechaVenta',
                              isGreaterThanOrEqualTo:
                                  Timestamp.fromDate(_fechaSeleccionada!))
                          .where('fechaVenta',
                              isLessThanOrEqualTo: Timestamp.fromDate(
                                  _fechaSeleccionada!
                                      .add(const Duration(days: 1))))
                          .snapshots(),
                      builder:
                          (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                              child: Text(
                                  'Error al cargar las ventas: ${snapshot.error}'));
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                              child: Text(
                                  'No hay ventas registradas para esta fecha.'));
                        }

                        int ventaContador = 1;

                        return ListView(
                          children: snapshot.data!.docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final nombresProductos =
                                data['nombresProductos'] ?? [];
                            final cantidades = data['cantidades'] ?? [];
                            final total = data['precioFinal']?.toDouble();
                            final fechaVenta =
                                (data['fechaVenta'] as Timestamp).toDate();

                            return ListTile(
                              title: Text(
                                  'Venta #${ventaContador.toString().padLeft(3, '0')} - Hora: ${DateFormat('HH:mm').format(fechaVenta)}'),
                              subtitle: Text(
                                  'Total: \$${total?.toStringAsFixed(2) ?? "0.00"}'),
                              onTap: () => _mostrarDialogoVenta(
                                  context,
                                  nombresProductos,
                                  cantidades,
                                  total,
                                  fechaVenta),
                            );
                          }).toList(),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
