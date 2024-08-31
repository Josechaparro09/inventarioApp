import 'package:firebase_auth/firebase_auth.dart';

class ServicioAutenticacion {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Registro de usuario con correo y contraseña
  Future<User?> registrarUsuario(String email, String password) async {
    try {
      UserCredential userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print('Error al registrar usuario: $e');
      return null;
    }
  }

  // Inicio de sesión con correo y contraseña
  Future<User?> iniciarSesion(String email, String password) async {
    try {
      UserCredential userCredential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print('Error al iniciar sesión: $e');
      return null;
    }
  }

  // Cierre de sesión
  Future<void> cerrarSesion() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      print('Error al cerrar sesión: $e');
    }
  }

  // Obtener el usuario actualmente autenticado
  User? get usuarioActual {
    return _firebaseAuth.currentUser;
  }
}
