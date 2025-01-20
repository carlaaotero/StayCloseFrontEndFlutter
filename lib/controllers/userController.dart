import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_application_1/services/userServices.dart';
import 'package:flutter_application_1/models/user.dart';
import 'dart:typed_data';
import 'package:image_picker_web/image_picker_web.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserController extends GetxController {
  final UserService userService = Get.put(UserService());
  var currentUserName = ''.obs;
  // Lista de usuarios cargados
  var users = <UserModel>[].obs;

  // Controladores de texto para la UI
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Variables reactivas para la UI
  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var isPasswordVisible = false.obs;

  // Usando Rxn para que sea nullable (inicialmente vacío)
  var user = Rxn<UserModel>();

  var connectedUsers = <UserModel>[].obs; // Lista de usuarios conectados
  var searchResults = <UserModel>[].obs; // Resultados de búsqueda

// Método para obtener un usuario por su ID
  Future<void> fetchUser(String id) async {
    try {
      final fetchedUser = await userService.getUser(id);
      print("fetch $fetchedUser");
      if (fetchedUser != null) {
        user.value = fetchedUser;
        currentUserName.value = fetchedUser.username; // Actualiza el username
      } else {
        Get.snackbar('Error', 'Usuario no encontrado');
      }
    } catch (e) {
      Get.snackbar('Error', 'No se pudo obtener el usuario');
      print('Error al obtener el usuario: $e');
    }
  }

  // Método para cargar todos los usuarios
  Future<void> fetchUsers() async {
    try {
      isLoading.value = true;

      // Llamar al servicio para obtener los usuarios
      final fetchedUsers = await userService
          .getUsers(); // Asegúrate de que esto devuelva una lista válida
      if (fetchedUsers.isNotEmpty) {
        users.value = fetchedUsers; // Actualizar la lista de usuarios
      } else {
        print("No se encontraron usuarios.");
        users.clear(); // Limpia la lista si no hay usuarios
      }
    } catch (e) {
      print("Error al obtener usuarios: $e");
      Get.snackbar("Error", "No se pudieron cargar los usuarios.");
    } finally {
      isLoading.value = false;
    }
  }

  /*
  Future<void> fetchUsers() async {
    try {
      isLoading.value = true;

      // Llamar al servicio para obtener los usuarios
      final fetchedUsers = await userService.getUsers();
      users.value = fetchedUsers; // Actualizar la lista de usuarios
    } catch (e) {
      print("Error al obtener usuarios: $e");
      Get.snackbar("Error", "No se pudieron cargar los usuarios.");
    } finally {
      isLoading.value = false;
    }
  }
  */

  // Método para editar un usuario
  void editUser(UserModel updatedUser, String id, String password) async {
    try {
      final result = await userService.editUser(updatedUser, id, password);
      print("result: $result");
      if (result == 200) {
        user.value = updatedUser; // Actualizar el estado reactivo
        Get.snackbar('Éxito', 'Usuario actualizado correctamente');
        if (user.value != null) {
          usernameController.text =
              user.value!.username; // Usa el valor si no es nulo
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

    print('estoy en el login de usercontroller iniciando sesión ');

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

      print('el response data es:${responseData}');

      if (responseData == 200) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        final username = prefs.getString('username') ?? '';
        currentUserName.value = username;

        print('Inicio de sesión exitoso. Username: $username');
        // Manejo de respuesta exitosa
        Get.snackbar('Éxito', 'Inicio de sesión exitoso');
        Text('Bienvenido, ${user.value?.name ?? "Cargando..."}');
        Get.toNamed('/home');
      } else if (responseData == 300) {
        errorMessage.value = 'Usuario deshabilitado'.tr;
      } else {
        errorMessage.value = 'Usuario o contraseña incorrectos'.tr;
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

  // Método para crear una nueva experiencia
  Rxn<Uint8List> selectedImage =
      Rxn<Uint8List>(); // Bytes de la imagen seleccionada
  var uploadedImageUrl = ''.obs; // URL de la imagen subida a Cloudinary

  // Seleccionar imagen desde el dispositivo
  Future<void> pickImage() async {
    try {
      Uint8List? imageBytes = await ImagePickerWeb.getImageAsBytes();
      if (imageBytes != null) {
        selectedImage.value = imageBytes; // Guarda la imagen en selectedImage
        uploadedImageUrl.value = ''; // Si usas Cloudinary o alguna URL, resetea
        update(); // Actualiza la UI
        Get.snackbar('Éxito', 'Imagen seleccionada correctamente');
      }
    } catch (e) {
      Get.snackbar('Error', 'No se pudo seleccionar la imagen: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  //Buscar usuario por username
  // Buscar usuario por username
  Future<void> searchUser(String username) async {
    try {
      isLoading.value = true;
      UserModel? user = await userService.getUserByUsername(username);
      if (user != null) {
        searchResults.value = [user];
      } else {
        searchResults.clear();
      }
    } catch (e) {
      print("Error al buscar usuario: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // Subir imagen a Cloudinary
  Future<void> uploadImageToCloudinary() async {
    if (selectedImage == null) {
      Get.snackbar('Error', 'Selecciona una imagen primero',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      isLoading.value = true;
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/djen7vqby/image/upload'),
      );
      request.fields['upload_preset'] = 'nm1eu9ik';
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          selectedImage.value!,
          filename: 'image_${DateTime.now().millisecondsSinceEpoch}.png',
        ),
      );
      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var data = jsonDecode(responseData);
        uploadedImageUrl.value = data['secure_url'];
        Get.snackbar('Éxito', 'Imagen subida correctamente');
      } else {
        Get.snackbar('Error', 'Falló la subida de la imagen',
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('Error', 'Error al subir la imagen: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }
}
