import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../modelos/producto.dart';

class PantallaInventario extends StatefulWidget {
  @override
  _PantallaInventarioState createState() => _PantallaInventarioState();
}

class _PantallaInventarioState extends State<PantallaInventario> {
  final String usuario = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _construirAppBar(),
      body: _construirCuerpo(),
      floatingActionButton: _construirBotonAgregarProducto(),
      backgroundColor: Color(0xFFFFF8E1),
    );
  }

  AppBar _construirAppBar() {
    return AppBar(
      title: Text('Inventario'),
      backgroundColor: Color(0xFFFFA726),
    );
  }

  Widget _construirCuerpo() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('productos')
          .where('usuario', isEqualTo: usuario)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Center(
              child: Text('Error al cargar el inventario: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No hay productos en el inventario.'));
        }

        return ListView(
          padding: const EdgeInsets.all(8.0),
          children: snapshot.data!.docs.map((doc) {
            return _construirProductoCard(doc);
          }).toList(),
        );
      },
    );
  }

  Card _construirProductoCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final producto = Producto(
      id: doc.id,
      nombre: data['nombre'],
      precio: data['precio'].toDouble(),
      cantidad: data['cantidad'],
    );

    // Verificar si la cantidad es baja y mostrar una alerta
    if (producto.cantidad <= 5) {
      Future.delayed(Duration.zero, () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('¡Alerta! Stock bajo para ${producto.nombre}')),
        );
      });
    }

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: Icon(Icons.inventory, color: Color(0xFFFFA726), size: 40),
        title: Text(
          producto.nombre,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF212121),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8.0),
            Text('Precio: \$${producto.precio.toStringAsFixed(2)}',
                style: TextStyle(color: Color(0xFF757575))),
            SizedBox(height: 4.0),
            Text('Cantidad: ${producto.cantidad}',
                style: TextStyle(color: Color(0xFF757575))),
          ],
        ),
        trailing: _construirBotonesAccion(producto),
      ),
    );
  }

  Row _construirBotonesAccion(Producto producto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.edit, color: Color(0xFF42A5F5)),
          onPressed: () => _editarProducto(producto),
        ),
        IconButton(
          icon: Icon(Icons.delete, color: Colors.redAccent),
          onPressed: () => _eliminarProducto(producto.id),
        ),
      ],
    );
  }

  FloatingActionButton _construirBotonAgregarProducto() {
    return FloatingActionButton(
      onPressed: _mostrarDialogoAgregarProducto,
      child: Icon(Icons.add),
      backgroundColor: Color(0xFFFFA726),
    );
  }

  void _eliminarProducto(String idProducto) async {
    try {
      await FirebaseFirestore.instance
          .collection('productos')
          .doc(idProducto)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Producto eliminado con éxito')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar producto: $e')),
      );
    }
  }

  void _editarProducto(Producto producto) {
    TextEditingController _nombreController =
        TextEditingController(text: producto.nombre);
    TextEditingController _precioController =
        TextEditingController(text: producto.precio.toString());
    TextEditingController _cantidadController =
        TextEditingController(text: producto.cantidad.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Editar Producto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _construirTextField(_nombreController, 'Nombre'),
              _construirTextField(_precioController, 'Precio',
                  keyboardType: TextInputType.number),
              _construirTextField(_cantidadController, 'Cantidad',
                  keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('productos')
                      .doc(producto.id)
                      .update({
                    'nombre': _nombreController.text,
                    'precio': double.parse(_precioController.text),
                    'cantidad': int.parse(_cantidadController.text),
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Producto actualizado con éxito')),
                  );
                  Navigator.of(context).pop(); // Cerrar el diálogo
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al actualizar producto: $e')),
                  );
                }
              },
              child: Text('Guardar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _mostrarDialogoAgregarProducto() async {
    TextEditingController _nombreController = TextEditingController();
    TextEditingController _precioController = TextEditingController();
    TextEditingController _cantidadController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Agregar Producto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _construirTextField(_nombreController, 'Nombre'),
              _construirTextField(_precioController, 'Precio',
                  keyboardType: TextInputType.number),
              _construirTextField(_cantidadController, 'Cantidad',
                  keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance.collection('productos').add({
                    'nombre': _nombreController.text,
                    'precio': double.parse(_precioController.text),
                    'cantidad': int.parse(_cantidadController.text),
                    'usuario': usuario, // Asociar el producto al usuario actual
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Producto agregado con éxito')),
                  );
                  Navigator.of(context).pop(); // Cerrar el diálogo
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al agregar producto: $e')),
                  );
                }
              },
              child: Text('Agregar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  TextField _construirTextField(TextEditingController controller, String label,
      {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: keyboardType,
    );
  }
}
