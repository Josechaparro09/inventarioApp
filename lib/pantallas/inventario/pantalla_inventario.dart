import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../modelos/producto.dart';
import '../../logica/logica_inventario.dart';

class PantallaInventario extends StatefulWidget {
  @override
  _PantallaInventarioState createState() => _PantallaInventarioState();
}

class _PantallaInventarioState extends State<PantallaInventario> {
  late LogicaInventario _logicaInventario;
  final TextEditingController _controladorBusqueda = TextEditingController();
  String _terminoBusqueda = '';

  @override
  void initState() {
    super.initState();
    final String usuario = FirebaseAuth.instance.currentUser?.uid ?? '';
    _logicaInventario = LogicaInventario(usuario);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _construirAppBar(),
      body: _construirCuerpo(),
      floatingActionButton: _construirBotonAgregarProducto(),
      backgroundColor: const Color(0xFFFFF8E1),
    );
  }

  AppBar _construirAppBar() {
    return AppBar(
      title: const Text(
        'Inventario',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 24,
          color: Colors.white,
        ),
      ),
      backgroundColor: const Color(0xFFFFA726),
      elevation: 0,
    );
  }

  Widget _construirCuerpo() {
    return Column(
      children: [
        _construirBarraBusqueda(),
        Expanded(
          child: StreamBuilder(
            stream: _obtenerStreamProductos(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasError) {
                return _mostrarMensajeError(snapshot.error);
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _mostrarIndicadorCarga();
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _mostrarMensajeInventarioVacio();
              }
              return _construirListaProductos(snapshot.data!.docs);
            },
          ),
        ),
      ],
    );
  }

  Padding _construirBarraBusqueda() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _controladorBusqueda,
          decoration: const InputDecoration(
            hintText: 'Buscar productos...',
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: Color(0xFFFFA726)),
            contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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

  Stream<QuerySnapshot> _obtenerStreamProductos() {
    return _logicaInventario.getProductStream();
  }

  Widget _mostrarMensajeError(Object? error) {
    return Center(
      child: Text('Error al cargar el inventario: $error'),
    );
  }

  Widget _mostrarIndicadorCarga() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _mostrarMensajeInventarioVacio() {
    return const Center(
      child: Text(
        'No hay productos en el inventario.',
        style: TextStyle(
          fontSize: 18,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _construirListaProductos(List<DocumentSnapshot> documentos) {
    final documentosFiltrados = documentos.where((doc) {
      final producto = _convertirAProducto(doc);
      return producto.nombre.toLowerCase().contains(_terminoBusqueda);
    }).toList();

    if (documentosFiltrados.isEmpty) {
      return const Center(
        child: Text(
          'No existe el producto buscado',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: documentosFiltrados.length,
      itemBuilder: (context, index) {
        return _construirTarjetaProducto(documentosFiltrados[index]);
      },
    );
  }

  Producto _convertirAProducto(DocumentSnapshot doc) {
    return _logicaInventario.convertToProducto(doc);
  }

  Widget _construirTarjetaProducto(DocumentSnapshot doc) {
    final producto = _convertirAProducto(doc);

    if (producto.cantidad <= 5) {
      _mostrarAlertaStockBajo(producto.nombre);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFFFA726),
          radius: 25,
          child: Icon(Icons.inventory, color: Colors.white, size: 30),
        ),
        title: Text(
          producto.nombre,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF212121),
          ),
        ),
        subtitle: _construirDetallesProducto(producto),
        trailing: _construirBotonesAccion(producto),
      ),
    );
  }

  void _mostrarAlertaStockBajo(String nombreProducto) {
    Future.delayed(Duration.zero, () {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('¡Alerta! Stock bajo para $nombreProducto')),
      );
    });
  }

  Column _construirDetallesProducto(Producto producto) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4.0),
        Text(
          'Precio: \$${producto.precio.toStringAsFixed(2)}',
          style: const TextStyle(color: Color(0xFF757575)),
        ),
        const SizedBox(height: 4.0),
        Text(
          'Cantidad: ${producto.cantidad}',
          style: const TextStyle(color: Color(0xFF757575)),
        ),
      ],
    );
  }

  Row _construirBotonesAccion(Producto producto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit, color: Color(0xFF42A5F5)),
          onPressed: () => _editarProducto(producto),
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.redAccent),
          onPressed: () => _eliminarProducto(producto.id),
        ),
      ],
    );
  }

  FloatingActionButton _construirBotonAgregarProducto() {
    return FloatingActionButton(
      onPressed: _mostrarDialogoAgregarProducto,
      child: const Icon(Icons.add),
      backgroundColor: const Color(0xFFFFA726),
    );
  }

  void _editarProducto(Producto producto) {
    final _controladorNombre = TextEditingController(text: producto.nombre);
    final _controladorPrecio =
        TextEditingController(text: producto.precio.toString());
    final _controladorCantidad =
        TextEditingController(text: producto.cantidad.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Producto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _construirCampoTexto(_controladorNombre, 'Nombre'),
              _construirCampoTexto(_controladorPrecio, 'Precio',
                  keyboardType: TextInputType.number),
              _construirCampoTexto(_controladorCantidad, 'Cantidad',
                  keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => _actualizarProducto(
                  producto.id,
                  _controladorNombre.text,
                  _controladorPrecio.text,
                  _controladorCantidad.text),
              child: const Text('Guardar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFFA726),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _actualizarProducto(
      String idProducto, String nombre, String precio, String cantidad) async {
    try {
      await _logicaInventario.updateProduct(
          idProducto, nombre, precio, cantidad);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto actualizado con éxito')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar producto: $e')),
      );
    }
  }

  Future<void> _eliminarProducto(String idProducto) async {
    try {
      await _logicaInventario.deleteProduct(idProducto);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto eliminado con éxito')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar producto: $e')),
      );
    }
  }

  Future<void> _mostrarDialogoAgregarProducto() async {
    final _controladorNombre = TextEditingController();
    final _controladorPrecio = TextEditingController();
    final _controladorCantidad = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Agregar Producto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _construirCampoTexto(_controladorNombre, 'Nombre'),
              _construirCampoTexto(_controladorPrecio, 'Precio',
                  keyboardType: TextInputType.number),
              _construirCampoTexto(_controladorCantidad, 'Cantidad',
                  keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => _agregarProducto(_controladorNombre.text,
                  _controladorPrecio.text, _controladorCantidad.text),
              child: const Text('Guardar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFFA726),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _agregarProducto(
      String nombre, String precio, String cantidad) async {
    try {
      await _logicaInventario.addProduct(nombre, precio, cantidad);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto agregado con éxito')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al agregar producto: $e')),
      );
    }
  }

  TextField _construirCampoTexto(
      TextEditingController controlador, String etiqueta,
      {TextInputType? keyboardType}) {
    return TextField(
      controller: controlador,
      decoration: InputDecoration(labelText: etiqueta),
      keyboardType: keyboardType,
    );
  }
}
