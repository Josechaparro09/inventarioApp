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
    return Column(
      children: [
        BarraBusqueda(),
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

  Padding BarraBusqueda() {
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

  Stream<QuerySnapshot> _obtenerStreamProductos() {
    return _logicaInventario.getProductStream();
  }

  Widget _mostrarMensajeError(Object? error) {
    return Center(
      child: Text('Error al cargar el inventario: $error'),
    );
  }

  Widget _mostrarIndicadorCarga() {
    return Center(child: CircularProgressIndicator());
  }

  Widget _mostrarMensajeInventarioVacio() {
    return Center(child: Text('No hay productos en el inventario.'));
  }

  Widget _construirListaProductos(List<DocumentSnapshot> documentos) {
    // Filtrar los productos según el término de búsqueda
    final documentosFiltrados = documentos.where((doc) {
      final producto = _convertirAProducto(doc);
      return producto.nombre.toLowerCase().contains(_terminoBusqueda);
    }).toList();

    // Mostrar un mensaje si no hay productos que coincidan con la búsqueda
    if (documentosFiltrados.isEmpty) {
      return Center(
        child: Text(
          'no existe el producto buscado',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: documentosFiltrados
          .map((doc) => _construirTarjetaProducto(doc))
          .toList(),
    );
  }

  Producto _convertirAProducto(DocumentSnapshot doc) {
    return _logicaInventario.convertToProducto(doc);
  }

  Card _construirTarjetaProducto(DocumentSnapshot doc) {
    final producto = _convertirAProducto(doc);

    if (producto.cantidad <= 5) {
      _mostrarAlertaStockBajo(producto.nombre);
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
        SizedBox(height: 8.0),
        Text('Precio: \$${producto.precio.toStringAsFixed(2)}',
            style: TextStyle(color: Color(0xFF757575))),
        SizedBox(height: 4.0),
        Text('Cantidad: ${producto.cantidad}',
            style: TextStyle(color: Color(0xFF757575))),
      ],
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
          title: Text('Editar Producto'),
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
              child: Text('Guardar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
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
        SnackBar(content: Text('Producto actualizado con éxito')),
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
        SnackBar(content: Text('Producto eliminado con éxito')),
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
          title: Text('Agregar Producto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _construirCampoTexto(_controladorNombre, 'Nombre'),
              _construirCampoTexto(_controladorPrecio, 'Precio'),
              _construirCampoTexto(_controladorCantidad, 'Cantidad'),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => _agregarProducto(_controladorNombre.text,
                  _controladorPrecio.text, _controladorCantidad.text),
              child: Text('Guardar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
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
        SnackBar(content: Text('Producto agregado con éxito')),
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
