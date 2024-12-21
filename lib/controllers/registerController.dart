import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/googleAuthServices.dart';
import 'package:get/get.dart';
import 'package:flutter_application_1/services/userServices.dart';
import 'package:flutter_application_1/models/user.dart';

class RegisterController extends GetxController {
  final UserService userService = Get.put(UserService());
  //afegim GoogleAuth Service
  final Googleauthservices googleAuth = Googleauthservices();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  var isPasswordVisible = false.obs;
  var isConfirmPasswordVisible = false.obs;
  
  

  var isLoading = false.obs;
  var errorMessage = ''.obs;


  // Toggle password visibility
  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  // Toggle confirm password visibility
  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  // Sign up logic
  void signUp() async {
    // Handle sign-up logic
    if (passwordController.text == confirmPasswordController.text) {
      // Validación de campos vacíos
    if (nameController.text.isEmpty || passwordController.text.isEmpty || emailController.text.isEmpty || usernameController.text.isEmpty) {
      errorMessage.value = 'Campos vacíos';
      Get.snackbar('Error', errorMessage.value, snackPosition: SnackPosition.BOTTOM);
      return;
    }
    
    // Validación de longitud mínima de contraseña
    if (passwordController.text.length < 7) {
      errorMessage.value = 'La contraseña debe tener al menos 7 caracteres';
      Get.snackbar('Error', errorMessage.value, snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // Validación de formato de correo electrónico
    if (!GetUtils.isEmail(emailController.text)) {
      errorMessage.value = 'Correo electrónico no válido';
      Get.snackbar('Error', errorMessage.value, snackPosition: SnackPosition.BOTTOM);
      return;
    }

    isLoading.value = true;

    try {
      UserModel newUser = UserModel(
        username: usernameController.text,
        name: nameController.text,
        password: passwordController.text,
        email: emailController.text,
        actualUbication: List.empty(),
        admin: true
      );

      final response = await userService.createUser(newUser);

      if (response != null && response== 201) {
        Get.snackbar('Éxito', 'Usuario creado exitosamente');
        Get.toNamed('/login');
      } else {
        errorMessage.value = 'Error: Este E-Mail o Teléfono ya están en uso';
        Get.snackbar('Error', errorMessage.value, snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      errorMessage.value = 'Error al registrar usuario';
      Get.snackbar('Error', errorMessage.value, snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
    } else {
      errorMessage.value = 'Las contraseñas no coinciden';
    }
  }

  // Sign up logic
  void signUpWithGoogle() async {
    try{
      final googleUser = await googleAuth.signInWithGooggle();
      if (googleUser != null){
        final response = await userService.createUser(googleUser);
        if (response == 201){
          Get.snackbar('Éxito', 'Registro con Google exitoso');
          final logIn = (
            username: googleUser.username,
            password: googleUser.password,
          );
          final response2 = await userService.logIn(logIn);
          if (response2 == 200) {
            // Manejo de respuesta exitosa
            Get.snackbar('Éxito', 'Inicio de sesión exitoso');
            Text('Bienvenido, ${googleUser.username ?? "Cargando..."}');
            Get.toNamed('/home');
          } else {
          errorMessage.value = 'Usuario o contraseña incorrectos';
          }  
        } else {
          Get.snackbar('Error', 'No se pudo registrar con Google');
        }
      } else {
        errorMessage.value = 'Error: Este E-Mail o Teléfono ya están en uso';
        Get.snackbar('Error', errorMessage.value, snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      errorMessage.value = 'Error al registrar usuario';
      Get.snackbar('Error', errorMessage.value, snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }
}
