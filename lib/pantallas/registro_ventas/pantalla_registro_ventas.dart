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
    if (picked != null && picked != _fechaSeleccionada)
      setState(() {
        _fechaSeleccionada = picked;
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registro de Ventas'),
        backgroundColor: Color(0xFFFFA726),
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
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _seleccionarFecha(context),
                  child: Text('Seleccionar Fecha'),
                ),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: _fechaSeleccionada == null
                  ? Center(child: Text('No se ha seleccionado ninguna fecha.'))
                  : StreamBuilder(
                      stream: FirebaseFirestore.instance
                          .collection('ventas')
                          .where('fechaVenta',
                              isGreaterThanOrEqualTo:
                                  Timestamp.fromDate(_fechaSeleccionada!))
                          .where('fechaVenta',
                              isLessThanOrEqualTo: Timestamp.fromDate(
                                  _fechaSeleccionada!.add(Duration(days: 1))))
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
                          return Center(child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
                              child: Text(
                                  'No hay ventas registradas para esta fecha.'));
                        }

                        return ListView(
                          children: snapshot.data!.docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return ListTile(
                              title: Text(data['nombreProducto']),
                              subtitle: Text(
                                  'Cantidad Vendida: ${data['cantidadVendida']}'),
                              trailing: Text(
                                  'Total: \$${data['precioFinal'].toStringAsFixed(2)}'),
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
