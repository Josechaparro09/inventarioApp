import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../modelos/producto.dart';
import '../../logica/logica_ventas.dart';

class PantallaVentas extends StatefulWidget {
  const PantallaVentas({super.key});

  @override
  _PantallaVentasState createState() => _PantallaVentasState();
}

class _PantallaVentasState extends State<PantallaVentas> {
  late LogicaVentas _logicaVentas;
  final Map<Producto, int> productosSeleccionados = {};
  final TextEditingController _controladorCantidad = TextEditingController();
  final TextEditingController _controladorBusqueda = TextEditingController();
  String _terminoBusqueda = '';

  @override
  void initState() {
    super.initState();
    final String usuario = FirebaseAuth.instance.currentUser!.uid;
    _logicaVentas = LogicaVentas(usuario);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: _construirAppBar(),
      body: _construirCuerpo(),
      floatingActionButton: productosSeleccionados.isNotEmpty
          ? _construirBotonRealizarVenta()
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  AppBar _construirAppBar() {
    return AppBar(
      title: const Text('Ventas'),
      backgroundColor: const Color(0xFFFFA726),
    );
  }

  Widget _construirCuerpo() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _construirBarraBusqueda(),
            _construirListaProductos(),
            const SizedBox(height: 20),
            if (productosSeleccionados.isNotEmpty)
              _construirProductosSeleccionados(),
          ],
        ),
      ),
    );
  }

  Padding _construirBarraBusqueda() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _controladorBusqueda,
          decoration: InputDecoration(
            hintText: 'Buscar producto...',
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: Color(0xFFFFA726)),
            contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
          onChanged: (valor) {
            setState(() {
              _terminoBusqueda = valor.toLowerCase();
            });
          },
        ),
      ),
    );
  }

  Widget _construirListaProductos() {
    return StreamBuilder(
      stream: _logicaVentas.getProductStream(), // Cambio de método aquí
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return _construirMensajeError(snapshot.error);
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text('No hay productos disponibles en el inventario.'));
        }
        return _construirTarjetasProductos(snapshot.data!.docs);
      },
    );
  }

  Widget _construirMensajeError(Object? error) {
    return Center(child: Text('Error al cargar los productos: $error'));
  }

  Widget _construirTarjetasProductos(List<DocumentSnapshot> documentos) {
    // Filtrar los productos según el término de búsqueda
    final productosFiltrados = documentos.where((doc) {
      final producto =
          Producto.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      return producto.nombre.toLowerCase().contains(_terminoBusqueda);
    }).toList();

    // Mostrar un mensaje si no hay productos que coincidan con la búsqueda
    if (productosFiltrados.isEmpty) {
      return Center(
        child: Text(
          'No existe ningún producto para la búsqueda',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Column(
      children: productosFiltrados.map((doc) {
        final producto =
            Producto.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        return _construirTarjetaProducto(producto);
      }).toList(),
    );
  }

  Card _construirTarjetaProducto(Producto producto) {
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
        subtitle: _construirDetallesProducto(producto),
        trailing: _construirIconoAccion(producto),
      ),
    );
  }

  Column _construirDetallesProducto(Producto producto) {
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

  IconButton _construirIconoAccion(Producto producto) {
    return productosSeleccionados.containsKey(producto)
        ? IconButton(
            icon: const Icon(Icons.remove_circle, color: Colors.red),
            onPressed: () => _eliminarProductoSeleccionado(producto),
          )
        : IconButton(
            icon: const Icon(Icons.add_circle, color: Color(0xFFFFA726)),
            onPressed: () => _mostrarDialogoCantidad(producto),
          );
  }

  Widget _construirProductosSeleccionados() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Productos seleccionados:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ...productosSeleccionados.entries
            .map((entry) => _construirProductoSeleccionado(entry))
            .toList(),
        const SizedBox(height: 20),
      ],
    );
  }

  ListTile _construirProductoSeleccionado(MapEntry<Producto, int> entry) {
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

  FloatingActionButton _construirBotonRealizarVenta() {
    return FloatingActionButton.extended(
      onPressed: _confirmarVenta,
      label: const Text('Realizar Venta'),
      icon: const Icon(Icons.shopping_cart, color: Colors.deepPurple),
      backgroundColor: const Color(0xFFFFA726),
    );
  }

  void _mostrarDialogoCantidad(Producto producto) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cantidad a vender'),
          content: TextField(
            controller: _controladorCantidad,
            decoration: const InputDecoration(
              labelText: 'Cantidad',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () => _agregarProducto(producto),
              child: const Text('Agregar'),
            ),
            TextButton(
              onPressed: () {
                _controladorCantidad.clear();
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  void _agregarProducto(Producto producto) {
    final cantidad = int.tryParse(_controladorCantidad.text) ?? 0;
    if (cantidad > 0) {
      _agregarProductoSeleccionado(producto, cantidad);
      _controladorCantidad.clear();
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

  Future<void> _confirmarVenta() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar Venta'),
          content:
              const Text('¿Estás seguro de que deseas realizar esta venta?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cancelar la venta
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Confirmar la venta
                _realizarVenta();
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _realizarVenta() async {
    if (productosSeleccionados.isEmpty) {
      _mostrarSnackBar('Por favor selecciona al menos un producto');
      return;
    }

    try {
      await _logicaVentas.realizarVenta(productosSeleccionados);
      _mostrarDialogoFactura(productosSeleccionados.values.toList(),
          productosSeleccionados.keys.toList());
      _reiniciarDespuesDeVenta();
    } catch (e) {
      _manejarErrorVenta(e, StackTrace.current);
    }
  }

  void _reiniciarDespuesDeVenta() {
    setState(() {
      productosSeleccionados.clear();
      _controladorCantidad.clear();
    });
  }

  void _mostrarSnackBar(String mensaje) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  void _mostrarDialogoFactura(List<int> cantidades, List<Producto> productos) {
    final totalPagar = productos
        .asMap()
        .entries
        .map((e) => e.value.precio * cantidades[e.key])
        .reduce((value, element) => value + element);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Factura de Venta'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Fecha: ${DateTime.now()}'),
              const SizedBox(height: 8),
              const Text('Productos vendidos:'),
              for (var i = 0; i < productos.length; i++)
                Text(
                    '${productos[i].nombre} - Cantidad: ${cantidades[i]} - Precio: \$${productos[i].precio.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              Text('Total a pagar: \$${totalPagar.toStringAsFixed(2)}'),
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

  void _manejarErrorVenta(dynamic error, StackTrace stacktrace) {
    print("Error al realizar la venta: $error");
    print("Stacktrace: $stacktrace");

    _mostrarSnackBar('Error al realizar la venta: $error');
  }
}
