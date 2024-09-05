import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:inventario/pantallas/PantallaConfiguracion/pantalla_configuracion.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'inventario/pantalla_inventario.dart';
import 'ventas/pantalla_ventas.dart';
import 'registro_ventas/pantalla_registro_ventas.dart';
import 'autenticacion/pantalla_login.dart';

class PantallaPrincipal extends StatefulWidget {
  @override
  _PantallaPrincipalState createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal>
    with SingleTickerProviderStateMixin {
  User? usuarioActual;
  late AnimationController _controller;
  late Animation<double> _animation;
  String nombreNegocio = 'Mi Negocio'; // Nombre por defecto del negocio
  String nombreUsuario = 'Usuario'; // Nombre del usuario por defecto

  @override
  void initState() {
    super.initState();
    usuarioActual = FirebaseAuth.instance.currentUser;
    FirebaseAuth.instance.userChanges().listen((User? user) {
      setState(() {
        usuarioActual = user;
        nombreUsuario =
            user?.displayName ?? 'Usuario'; // Obtener el nombre del usuario
      });
    });

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _cargarNombreNegocio(); // Cargar el nombre del negocio almacenado en SharedPreferences
  }

  Future<void> _cargarNombreNegocio() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      nombreNegocio = prefs.getString('nombreNegocio') ??
          'Mi Negocio'; // Cargar el nombre del negocio
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF8E1),
      appBar: AppBar(
        title: Text(
          nombreNegocio, // Aquí se mostrará el nombre del negocio
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFFFFA726),
        elevation: 0, // Sin bordes ni sombras en el AppBar
      ),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          _buildHeader(), // Aquí se muestra el nombre del usuario
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return _buildCreativeGrid(constraints);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFFFFA726),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bienvenido,',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                  fontStyle: FontStyle.italic,
                ),
              ),
              Text(
                nombreUsuario, // Aquí se mostrará el nombre del usuario
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_animation.value * 0.1),
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Text(
                    nombreUsuario
                        .substring(0, 1)
                        .toUpperCase(), // Inicial del nombre del usuario
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFA726)),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCreativeGrid(BoxConstraints constraints) {
    final bool isLargeScreen = constraints.maxWidth > 600;
    final int crossAxisCount = isLargeScreen ? 4 : 2;
    final double aspectRatio = isLargeScreen ? 1.2 : 1.0;
    final double iconSize = isLargeScreen ? 40 : 30;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: aspectRatio,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
        ),
        itemCount: 4,
        itemBuilder: (BuildContext context, int index) =>
            _buildAnimatedCard(index, iconSize),
      ),
    );
  }

  Widget _buildAnimatedCard(int index, double iconSize) {
    final List<Map<String, dynamic>> items = [
      {
        'icon': Icons.inventory,
        'title': 'Inventario',
        'color': Colors.blue,
        'route': PantallaInventario()
      },
      {
        'icon': Icons.shopping_cart,
        'title': 'Ventas',
        'color': Colors.green,
        'route': PantallaVentas()
      },
      {
        'icon': Icons.receipt,
        'title': 'Registro',
        'color': Colors.purple,
        'route': PantallaRegistroVentas()
      },
      {
        'icon': Icons.settings,
        'title': 'Configuración',
        'color': Colors.red,
        'route': PantallaConfiguracion()
      },
    ];

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, sin(_animation.value * 2 * 3.14159) * 5),
          child: GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => items[index]['route'])),
            child: Container(
              decoration: BoxDecoration(
                color: items[index]['color'].withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: items[index]['color'].withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(items[index]['icon'],
                      size: iconSize, color: Colors.white),
                  SizedBox(height: 8),
                  Text(
                    items[index]['title'],
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Color(0xFFFFA726),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Text(
                    nombreUsuario
                        .substring(0, 1)
                        .toUpperCase(), // Inicial del nombre del usuario
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFA726)),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  nombreUsuario, // Mostrar el nombre del usuario
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  usuarioActual?.email ?? 'Correo no disponible',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.person, color: Color(0xFFFFA726)),
            title: Text('Perfil'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.settings, color: Color(0xFFFFA726)),
            title: Text('Configuración'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => PantallaConfiguracion()));
            },
          ),
          ListTile(
            leading: Icon(Icons.help, color: Color(0xFFFFA726)),
            title: Text('Ayuda'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.exit_to_app, color: Color(0xFFFFA726)),
            title: Text('Cerrar Sesión'),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => PantallaLogin()));
            },
          ),
        ],
      ),
    );
  }
}
