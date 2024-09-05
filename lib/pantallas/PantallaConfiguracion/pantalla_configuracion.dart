import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PantallaConfiguracion extends StatefulWidget {
  @override
  _PantallaConfiguracionState createState() => _PantallaConfiguracionState();
}

class _PantallaConfiguracionState extends State<PantallaConfiguracion> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _nombreNegocioController =
      TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    User? usuarioActual = _auth.currentUser;
    if (usuarioActual != null) {
      _nombreController.text = usuarioActual.displayName ?? '';
      _correoController.text = usuarioActual.email ?? '';
    }
    _cargarNombreNegocio(); // Cargar el nombre del negocio almacenado
  }

  Future<void> _cargarNombreNegocio() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _nombreNegocioController.text = prefs.getString('nombreNegocio') ??
          ''; // Cargar el nombre del negocio
    });
  }

  Future<void> _guardarCambios() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? usuarioActual = _auth.currentUser;
      if (usuarioActual != null) {
        // Actualizar el nombre del usuario
        await usuarioActual.updateDisplayName(_nombreController.text.trim());

        // Actualizar el correo electrónico del usuario
        await usuarioActual.updateEmail(_correoController.text.trim());

        // Guardar el nombre del negocio en SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'nombreNegocio', _nombreNegocioController.text.trim());

        // Recargar el usuario para reflejar los cambios
        await usuarioActual.reload();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cambios guardados con éxito')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar cambios: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configuración'),
        backgroundColor: Color(0xFFFFA726),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Campo para modificar el nombre del negocio
            TextField(
              controller: _nombreNegocioController,
              decoration: InputDecoration(
                labelText: 'Nombre del Negocio',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            // Campo para modificar el nombre del usuario
            TextField(
              controller: _nombreController,
              decoration: InputDecoration(
                labelText: 'Nombre del Usuario',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            // Campo para modificar el correo electrónico del usuario
            TextField(
              controller: _correoController,
              decoration: InputDecoration(
                labelText: 'Correo Electrónico',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _guardarCambios,
                    child: Text('Guardar Cambios'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFFA726),
                      padding:
                          EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
