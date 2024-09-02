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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Ventas'),
      backgroundColor: const Color(0xFFFFA726),
    );
  }

  Widget _buildBody() {
    final usuario = FirebaseAuth.instance.currentUser!.uid;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductList(usuario),
            const SizedBox(height: 20),
            if (productosSeleccionados.isNotEmpty) _buildSelectedProducts(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList(String usuario) {
    return StreamBuilder(
      stream: _getProductStream(usuario),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return _buildErrorMessage(snapshot.error);
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text('No hay productos disponibles en el inventario.'));
        }
        return _buildProductCards(snapshot.data!.docs);
      },
    );
  }

  Stream<QuerySnapshot> _getProductStream(String usuario) {
    return FirebaseFirestore.instance
        .collection('productos')
        .where('usuario', isEqualTo: usuario)
        .snapshots();
  }

  Widget _buildErrorMessage(Object? error) {
    return Center(child: Text('Error al cargar los productos: $error'));
  }

  Widget _buildProductCards(List<DocumentSnapshot> documents) {
    final productos = documents.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Producto.fromMap(data, doc.id);
    }).toList();

    return Column(
      children:
          productos.map((producto) => _buildProductCard(producto)).toList(),
    );
  }

  Card _buildProductCard(Producto producto) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
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
        subtitle: _buildProductDetails(producto),
        trailing: _buildTrailingIcon(producto),
      ),
    );
  }

  Column _buildProductDetails(Producto producto) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Precio: \$${producto.precio.toStringAsFixed(2)}',
          style: const TextStyle(color: Color(0xFF757575), fontSize: 16),
        ),
        Text(
          'Cantidad disponible: ${producto.cantidad}',
          style: const TextStyle(color: Color(0xFF757575), fontSize: 16),
        ),
      ],
    );
  }

  IconButton _buildTrailingIcon(Producto producto) {
    return productosSeleccionados.containsKey(producto)
        ? IconButton(
            icon: const Icon(Icons.remove_circle, color: Colors.red),
            onPressed: () => _eliminarProductoSeleccionado(producto),
          )
        : IconButton(
            icon: const Icon(Icons.add_circle, color: Color(0xFFFFA726)),
            onPressed: () => _showAddQuantityDialog(producto),
          );
  }

  Widget _buildSelectedProducts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Productos seleccionados:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ...productosSeleccionados.entries
            .map((entry) => _buildSelectedProductTile(entry))
            .toList(),
        const SizedBox(height: 20),
        _buildRealizarVentaButton(),
      ],
    );
  }

  ListTile _buildSelectedProductTile(MapEntry<Producto, int> entry) {
    final producto = entry.key;
    final cantidad = entry.value;

    return ListTile(
      title: Text(producto.nombre ?? 'Producto sin nombre'),
      subtitle: Text('Cantidad: $cantidad'),
      trailing: Text(
        'Total: \$${(producto.precio * cantidad).toStringAsFixed(2)}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Center _buildRealizarVentaButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _realizarVenta,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 15.0),
          backgroundColor: const Color(0xFFFFA726),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        ),
        child: const Text(
          'Realizar Venta',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }

  void _showAddQuantityDialog(Producto producto) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cantidad a vender'),
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
              onPressed: () => _handleAddProduct(producto),
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
  }

  void _handleAddProduct(Producto producto) {
    final cantidad = int.tryParse(_cantidadController.text) ?? 0;
    if (cantidad > 0) {
      _agregarProductoSeleccionado(producto, cantidad);
      _cantidadController.clear();
      Navigator.of(context).pop();
    }
  }

  void _agregarProductoSeleccionado(Producto producto, int cantidad) {
    if (producto.id == null || producto.id.isEmpty) {
      print('Error: Producto ID está vacío');
      return;
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
      _showSnackBar('Por favor selecciona al menos un producto');
      return;
    }

    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      await _processBatch(batch);
      await batch.commit();
      _showSuccessDialog();
      _resetAfterSale();
    } catch (e, stacktrace) {
      _handleSaleError(e, stacktrace);
    }
  }

  Future<void> _processBatch(WriteBatch batch) async {
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

  void _resetAfterSale() {
    setState(() {
      productosSeleccionados.clear();
      _cantidadController.clear();
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showSuccessDialog() {
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
  }

  void _handleSaleError(dynamic error, dynamic stacktrace) {
    print("Error al realizar la venta: $error");
    print("Stacktrace: $stacktrace");

    _showSnackBar('Error al realizar la venta: $error\nDetalles: $stacktrace');
  }
}
