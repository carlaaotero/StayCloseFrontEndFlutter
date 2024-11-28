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
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Campo para el nombre de usuario
              TextField(
                controller: registerController.nameController,
                decoration: InputDecoration(
                  labelText: 'Usuario',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              SizedBox(height: 16),

              // Campo para el correo electrónico
              TextField(
                controller: registerController.mailController,
                decoration: InputDecoration(
                  labelText: 'Correo Electrónico',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              SizedBox(height: 16),

              // Campo para la contraseña
              TextField(
                controller: registerController.passwordController,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true, // Oculta la contraseña
              ),
              SizedBox(height: 16),

              // Campo para el comentario
              TextField(
                controller: registerController.commentController,
                decoration: InputDecoration(
                  labelText: 'Comentario',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.comment),
                ),
              ),
              SizedBox(height: 24),

              // Mostrar indicador de carga o botón de registro
              Obx(() {
                if (registerController.isLoading.value) {
                  return CircularProgressIndicator();
                } else {
                  return ElevatedButton(
                    onPressed: registerController.signUp,
                    style: ElevatedButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text('Registrarse', style: TextStyle(fontSize: 18)),
                  );
                }
              }),

              SizedBox(height: 16),

              // Mostrar mensaje de error, si existe
              Obx(() {
                if (registerController.errorMessage.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      registerController.errorMessage.value,
                      style: TextStyle(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  );
                } else {
                  return Container();
                }
              }),

              SizedBox(height: 24),

              // Botón para volver a la página de inicio de sesión
              TextButton(
                onPressed: () => Get.toNamed('/login'),
                child: Text(
                  '¿Ya tienes una cuenta? Inicia sesión aquí',
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
