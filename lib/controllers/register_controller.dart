import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:guinea_roads/models/register_model.dart';
import 'package:guinea_roads/login_page.dart';

// Import LoginPage

class RegisterController {
  final AuthService _authService = AuthService();
  late TextEditingController emailController;
  late TextEditingController passwordController;
  late TextEditingController confirmPasswordController;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  RegisterController() {
    emailController = TextEditingController();
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();
  }

  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
  }

  Future<void> register(BuildContext context) async {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      String email = emailController.text.trim();
      String password = passwordController.text.trim();
      User? user = await _authService.registerWithEmailAndPassword(email, password);
      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur d\'inscription')),
        );
      }
    }
  }
}
