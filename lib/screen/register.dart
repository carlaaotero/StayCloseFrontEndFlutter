import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_application_1/controllers/registerController.dart';

class RegisterPage extends StatelessWidget {
  final RegisterController registerController = Get.put(RegisterController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registrarse'),
        backgroundColor: Color(0xFF89AFAF),
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          margin: const EdgeInsets.symmetric(horizontal: 40.0),
          constraints: BoxConstraints(
            maxWidth: 500,
          ),
          decoration: BoxDecoration(
            color: Color.fromARGB(194, 162, 204, 204),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Crear una cuenta",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF004D40),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: registerController.usernameController,
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    labelStyle: TextStyle(color: Colors.white),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: registerController.nameController,
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    labelText: 'Nom',
                    labelStyle: TextStyle(color: Colors.white),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: registerController.emailController,
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    labelText: 'Correo Electrónico',
                    labelStyle: TextStyle(color: Colors.white),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: registerController.passwordController,
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    labelStyle: TextStyle(color: Colors.white),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                Obx(() {
                  if (registerController.isLoading.value) {
                    return CircularProgressIndicator();
                  } else {
                    return ElevatedButton(
                      onPressed: registerController.signUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF89AFAF),
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Registrarse'),
                    );
                  }
                }),
                const SizedBox(height: 10),
                Obx(() {
                  if (registerController.errorMessage.isNotEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        registerController.errorMessage.value,
                        style: TextStyle(color: Colors.red),
                      ),
                    );
                  } else {
                    return Container();
                  }
                }),
                const SizedBox(height: 20),
                Text(
                  "Ya tienes una cuenta, inicia Sessión",
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF004D40),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => Get.toNamed('/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF89AFAF),
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Inicia Sessión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}