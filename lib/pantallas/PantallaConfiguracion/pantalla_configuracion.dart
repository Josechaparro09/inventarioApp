import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PantallaConfiguracion extends StatefulWidget {
  @override
  _PantallaConfiguracionState createState() => _PantallaConfiguracionState();
}

class _PantallaConfiguracionState extends State<PantallaConfiguracion> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    User? usuarioActual = _auth.currentUser;
    if (usuarioActual != null) {
      _nombreController.text = usuarioActual.displayName ?? '';
      _correoController.text = usuarioActual.email ?? '';
    }
  }

  Future<void> _guardarCambios() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? usuarioActual = _auth.currentUser;
      if (usuarioActual != null) {
        // Actualizar el nombre
        await usuarioActual.updateDisplayName(_nombreController.text.trim());

        // Actualizar el correo electrónico
        await usuarioActual.updateEmail(_correoController.text.trim());

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
            TextField(
              controller: _nombreController,
              decoration: InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
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
