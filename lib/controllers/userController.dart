/*import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_application_1/services/userServices.dart';
import 'package:flutter_application_1/models/user.dart';

class UserController extends GetxController {
  final UserService userService = Get.put(UserService());

  // Controladores de texto para la UI
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Variables reactivas para la UI
  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var isPasswordVisible = false.obs;
  
  // Usando Rxn para que sea nullable (inicialmente vacío)
  var user = Rxn<UserModel>();

// Método para obtener un usuario por su ID
  Future<void> fetchUser(String id) async {
    try {
      final fetchedUser = await userService.getUser(id);
      print("fetch $fetchedUser");
      if (fetchedUser != null) {
        user.value = fetchedUser;
      } else {
        Get.snackbar('Error', 'Usuario no encontrado');
      }
    } catch (e) {
      Get.snackbar('Error', 'No se pudo obtener el usuario');
      print('Error al obtener el usuario: $e');
    }
  }

  // Método para editar un usuario
  void editUser(UserModel updatedUser, String id) async {
    try {
      final result = await userService.EditUser(updatedUser, id);
      print("result: $result");
      if (result == 200) {
        user.value = updatedUser; // Actualizar el estado reactivo
        Get.snackbar('Éxito', 'Usuario actualizado correctamente');
        if (user.value != null) {
          usernameController.text = user.value!.username; // Usa el valor si no es nulo
          
        }

      } else {
        Get.snackbar('Error', 'No se pudo actualizar el usuario');
      }
    } catch (e) {
      Get.snackbar('Error', 'Error al actualizar el usuario');
      print('Error al actualizar el usuario: $e');
    }
  }
  // Toggle password visibility
  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void logIn() async {
    // Validación de campos
    if (usernameController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar('Error', 'Campos vacíos',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    print('estoy en el login de usercontroller');

    final logIn = (
      username: usernameController.text,
      password: passwordController.text,
    );

    // Iniciar el proceso de inicio de sesión
    isLoading.value = true;
    errorMessage.value = '';

    try {
      // Llamada al servicio para iniciar sesión
      final responseData = await userService.logIn(logIn);

      print('el response data es:${ responseData}');

      if (responseData == 200) {
        // Manejo de respuesta exitosa
        Get.snackbar('Éxito', 'Inicio de sesión exitoso');
        Text('Bienvenido, ${user.value?.name ?? "Cargando..."}');
        Get.toNamed('/home');
      } else {
        errorMessage.value = 'Usuario o contraseña incorrectos';
      }
    } catch (e) {
      errorMessage.value = 'Error: No se pudo conectar con la API';
    } finally {
      isLoading.value = false;
    }
  }

  // Método para cerrar sesión
  void logOut() async {
    try {
      // Llamada al servicio para cerrar sesión
      await userService.logOut();
      Get.snackbar('Éxito', 'Has cerrado sesión correctamente');

      // Redirigir al usuario a la pantalla de login
      Get.offAllNamed('/login');
    } catch (e) {
      Get.snackbar('Error', 'Hubo un problema al cerrar sesión');
    }
  }
}

*/
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/userServices.dart';
import '../models/user.dart';

class UserController extends GetxController {
  final UserService userService = Get.put(UserService());

  // Controladores de texto para la UI
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Variables reactivas para la UI
  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var isPasswordVisible = false.obs;

  // Usuario reactivo
  var user = Rxn<UserModel>();

  // Método para obtener un usuario por su ID
  Future<void> fetchUser(String id) async {
    try {
      final fetchedUser = await userService.getUser(id);
      if (fetchedUser != null) {
        user.value = fetchedUser;
      } else {
        Get.snackbar('Error', 'Usuario no encontrado');
      }
    } catch (e) {
      Get.snackbar('Error', 'No se pudo obtener el usuario');
      print('Error al obtener el usuario: $e');
    }
  }

  // Método para editar un usuario
  void editUser(UserModel updatedUser, String id) async {
    try {
      final result = await userService.editUser(updatedUser, id);
      if (result == 200) {
        user.value = updatedUser; // Actualizar el estado reactivo
        Get.snackbar('Éxito', 'Usuario actualizado correctamente');
      } else {
        Get.snackbar('Error', 'No se pudo actualizar el usuario');
      }
    } catch (e) {
      Get.snackbar('Error', 'Error al actualizar el usuario');
      print('Error al actualizar el usuario: $e');
    }
  }

  // Método para iniciar sesión
  void logIn() async {
    if (usernameController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar('Error', 'Campos vacíos');
      return;
    }

    final logIn = {
      'username': usernameController.text,
      'password': passwordController.text,
    };

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final responseData = await userService.logIn(logIn);

      if (responseData == 200) {
        Get.snackbar('Éxito', 'Inicio de sesión exitoso');
        Get.toNamed('/home');
      } else {
        errorMessage.value = 'Usuario o contraseña incorrectos';
      }
    } catch (e) {
      errorMessage.value = 'Error: No se pudo conectar con la API';
      print(e);
    } finally {
      isLoading.value = false;
    }
  }

  // Método para cerrar sesión
  void logOut() async {
    try {
      await userService.logOut();
      Get.snackbar('Éxito', 'Has cerrado sesión correctamente');
      Get.offAllNamed('/login');
    } catch (e) {
      Get.snackbar('Error', 'Hubo un problema al cerrar sesión');
      print(e);
    }
  }

  // Mostrar/ocultar contraseña
  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }
}
