import 'package:firebase_auth/firebase_auth.dart';

class ServicioAutenticacion {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> iniciarSesion(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print('Error al iniciar sesión: $e');
      return null;
    }
  }

  Future<User?> registrarUsuario(String email, String password) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print('Error al registrar usuario: $e');
      return null;
    }
  }

  Future<void> cerrarSesion() async {
    await _auth.signOut();
  }
}
