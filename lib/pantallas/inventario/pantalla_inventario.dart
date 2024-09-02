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
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildAddProductButton(),
      backgroundColor: Color(0xFFFFF8E1),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text('Inventario'),
      backgroundColor: Color(0xFFFFA726),
    );
  }

  Widget _buildBody() {
    return StreamBuilder(
      stream: _getProductStream(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return _buildErrorMessage(snapshot.error);
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingIndicator();
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyInventoryMessage();
        }
        return _buildProductList(snapshot.data!.docs);
      },
    );
  }

  Stream<QuerySnapshot> _getProductStream() {
    return FirebaseFirestore.instance
        .collection('productos')
        .where('usuario', isEqualTo: usuario)
        .snapshots();
  }

  Widget _buildErrorMessage(Object? error) {
    return Center(
      child: Text('Error al cargar el inventario: $error'),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(child: CircularProgressIndicator());
  }

  Widget _buildEmptyInventoryMessage() {
    return Center(child: Text('No hay productos en el inventario.'));
  }

  Widget _buildProductList(List<DocumentSnapshot> documents) {
    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: documents.map((doc) => _buildProductCard(doc)).toList(),
    );
  }

  Card _buildProductCard(DocumentSnapshot doc) {
    final producto = _convertToProducto(doc);

    if (producto.cantidad <= 5) {
      _showLowStockAlert(producto.nombre);
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
        subtitle: _buildProductDetails(producto),
        trailing: _buildActionButtons(producto),
      ),
    );
  }

  Producto _convertToProducto(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Producto(
      id: doc.id,
      nombre: data['nombre'],
      precio: data['precio'].toDouble(),
      cantidad: data['cantidad'],
    );
  }

  void _showLowStockAlert(String productName) {
    Future.delayed(Duration.zero, () {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('¡Alerta! Stock bajo para $productName')),
      );
    });
  }

  Column _buildProductDetails(Producto producto) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8.0),
        Text('Precio: \$${producto.precio.toStringAsFixed(2)}',
            style: TextStyle(color: Color(0xFF757575))),
        SizedBox(height: 4.0),
        Text('Cantidad: ${producto.cantidad}',
            style: TextStyle(color: Color(0xFF757575))),
      ],
    );
  }

  Row _buildActionButtons(Producto producto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.edit, color: Color(0xFF42A5F5)),
          onPressed: () => _editProduct(producto),
        ),
        IconButton(
          icon: Icon(Icons.delete, color: Colors.redAccent),
          onPressed: () => _deleteProduct(producto.id),
        ),
      ],
    );
  }

  FloatingActionButton _buildAddProductButton() {
    return FloatingActionButton(
      onPressed: _showAddProductDialog,
      child: Icon(Icons.add),
      backgroundColor: Color(0xFFFFA726),
    );
  }

  Future<void> _deleteProduct(String productId) async {
    try {
      await FirebaseFirestore.instance
          .collection('productos')
          .doc(productId)
          .delete();
      _showSnackbar('Producto eliminado con éxito');
    } catch (e) {
      _showSnackbar('Error al eliminar producto: $e');
    }
  }

  void _editProduct(Producto producto) {
    final _nombreController = TextEditingController(text: producto.nombre);
    final _precioController =
        TextEditingController(text: producto.precio.toString());
    final _cantidadController =
        TextEditingController(text: producto.cantidad.toString());

    showDialog(
      context: context,
      builder: (context) {
        return _buildProductDialog(
          title: 'Editar Producto',
          nombreController: _nombreController,
          precioController: _precioController,
          cantidadController: _cantidadController,
          onSave: () => _updateProduct(producto.id, _nombreController.text,
              _precioController.text, _cantidadController.text),
        );
      },
    );
  }

  Future<void> _updateProduct(
      String productId, String nombre, String precio, String cantidad) async {
    try {
      await FirebaseFirestore.instance
          .collection('productos')
          .doc(productId)
          .update({
        'nombre': nombre,
        'precio': double.parse(precio),
        'cantidad': int.parse(cantidad),
      });
      _showSnackbar('Producto actualizado con éxito');
      Navigator.of(context).pop(); // Cerrar el diálogo
    } catch (e) {
      _showSnackbar('Error al actualizar producto: $e');
    }
  }

  Future<void> _showAddProductDialog() async {
    final _nombreController = TextEditingController();
    final _precioController = TextEditingController();
    final _cantidadController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return _buildProductDialog(
          title: 'Agregar Producto',
          nombreController: _nombreController,
          precioController: _precioController,
          cantidadController: _cantidadController,
          onSave: () => _addProduct(_nombreController.text,
              _precioController.text, _cantidadController.text),
        );
      },
    );
  }

  Future<void> _addProduct(
      String nombre, String precio, String cantidad) async {
    try {
      await FirebaseFirestore.instance.collection('productos').add({
        'nombre': nombre,
        'precio': double.parse(precio),
        'cantidad': int.parse(cantidad),
        'usuario': usuario, // Asociar el producto al usuario actual
      });
      _showSnackbar('Producto agregado con éxito');
      Navigator.of(context).pop(); // Cerrar el diálogo
    } catch (e) {
      _showSnackbar('Error al agregar producto: $e');
    }
  }

  AlertDialog _buildProductDialog({
    required String title,
    required TextEditingController nombreController,
    required TextEditingController precioController,
    required TextEditingController cantidadController,
    required VoidCallback onSave,
  }) {
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTextField(nombreController, 'Nombre'),
          _buildTextField(precioController, 'Precio',
              keyboardType: TextInputType.number),
          _buildTextField(cantidadController, 'Cantidad',
              keyboardType: TextInputType.number),
        ],
      ),
      actions: [
        ElevatedButton(onPressed: onSave, child: Text('Guardar')),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar'),
        ),
      ],
    );
  }

  TextField _buildTextField(TextEditingController controller, String label,
      {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: keyboardType,
    );
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
