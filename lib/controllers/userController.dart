import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_application_1/services/userServices.dart';
import 'package:flutter_application_1/models/user.dart';
import 'dart:typed_data';
//import 'package:image_picker_web/image_picker_web.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart'; // Para Android/iOS


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

  // Método para crear una nueva experiencia
  Rxn<Uint8List> selectedImage = Rxn<Uint8List>(); // Bytes de la imagen seleccionada
  var uploadedImageUrl = ''.obs; // URL de la imagen subida a Cloudinary

 // Seleccionar imagen desde el dispositivo (compatible con Android/iOS y web)
Future<void> pickImage() async {
  try {
    Uint8List? imageBytes;

    if (kIsWeb) {
      // Usar ImagePickerWeb para la web
      //imageBytes = await ImagePickerWeb.getImageAsBytes();
    } else {
      // Usar ImagePicker para Android/iOS
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        imageBytes = await pickedFile.readAsBytes();
      }
    }

    if (imageBytes != null) {
      selectedImage.value = imageBytes; // Guarda la imagen seleccionada
      uploadedImageUrl.value = ''; // Restablece la URL si es necesario
      update(); // Actualiza la UI
      Get.snackbar('Éxito', 'Imagen seleccionada correctamente');
    } else {
      Get.snackbar('Error', 'No se seleccionó ninguna imagen');
    }
  } catch (e) {
    Get.snackbar('Error', 'No se pudo seleccionar la imagen: $e',
        snackPosition: SnackPosition.BOTTOM);
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
