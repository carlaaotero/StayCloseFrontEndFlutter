import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_application_1/services/user.dart';
import 'package:flutter_application_1/models/userModel.dart';

class RegisterController extends GetxController {
  final UserService userService = Get.put(UserService());

  // Controladores de los campos de entrada
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController mailController = TextEditingController();
  final TextEditingController commentController = TextEditingController();

  // Variables reactivas para manejar el estado
  var isLoading = false.obs; // Indica si la operación está en curso
  var errorMessage = ''.obs; // Mensaje de error para mostrar en pantalla

  // Método para registrar un usuario
  Future<void> signUp() async {
    // Validación de campos vacíos
    if (nameController.text.isEmpty ||
        passwordController.text.isEmpty ||
        mailController.text.isEmpty ||
        commentController.text.isEmpty) {
      errorMessage.value = 'Todos los campos son obligatorios.';
      Get.snackbar('Error', errorMessage.value,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // Validación de formato de correo electrónico
    if (!GetUtils.isEmail(mailController.text)) {
      errorMessage.value = 'Correo electrónico no válido.';
      Get.snackbar('Error', errorMessage.value,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // Activar el estado de carga
    isLoading.value = true;

    try {
      // Crear un modelo de usuario con los datos ingresados
      UserModel newUser = UserModel(
        username: nameController.text,
        name: nameController.text,
        email: mailController.text,
        password: passwordController.text,
        // comment: commentController.text,
        actualUbication: [], // Proporcionar un valor por defecto
      );

      // Llamar al servicio para registrar al usuario
      final response = await userService.createUser(newUser);

      if (response == 201) {
        // Si el registro es exitoso, mostrar mensaje de éxito y redirigir
        Get.snackbar('Éxito', 'Usuario registrado exitosamente',
            snackPosition: SnackPosition.BOTTOM);
        clearFields(); // Limpiar los campos del formulario
        Get.toNamed('/login'); // Redirigir al inicio de sesión
      } else {
        // Manejar el caso de error devuelto por la API
        errorMessage.value = 'Este correo ya está en uso.';
        Get.snackbar('Error', errorMessage.value,
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      // Manejar errores de conexión o del servidor
      errorMessage.value = 'Error al registrar usuario. Intente nuevamente.';
      Get.snackbar('Error', errorMessage.value,
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      // Desactivar el estado de carga
      isLoading.value = false;
    }
  }

  // Método para limpiar los campos del formulario
  void clearFields() {
    nameController.clear();
    passwordController.clear();
    mailController.clear();
    commentController.clear();
  }

  // Método para destruir los controladores cuando ya no sean necesarios
  @override
  void onClose() {
    nameController.dispose();
    passwordController.dispose();
    mailController.dispose();
    commentController.dispose();
    super.onClose();
  }
}
