import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Para acceder a SharedPreferences
import 'package:get/get.dart';
import 'package:flutter_application_1/controllers/userController.dart'; // Importa el controlador
import 'package:flutter_application_1/models/user.dart'; // Asegúrate de importar el modelo
import 'package:flutter_application_1/services/userServices.dart'; // Importar el servicio

class ConfiguracionScreen extends StatefulWidget {
  @override
  _ConfiguracionScreenState createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  String? _userId;
  String? _username;
  String? _email;

  final UserController userController = Get.find<UserController>();
  final UserService userService = Get.find<UserService>();
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Cargar la ID del usuario desde SharedPreferences
  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('user_id');
    });

    if (_userId != null) {
      await _fetchUserData();
    }
  }

  // Obtener los datos completos del usuario con su ID
  Future<void> _fetchUserData() async {
    await userController.fetchUser(_userId!);
    if (userController.user.value != null) {
      setState(() {
        _usernameController.text = userController.user.value!.username;
        _nameController.text = userController.user.value!.name;
        _emailController.text = userController.user.value!.email;
        _passController.text = userController.user.value!.password;
      });
    } else {
      Get.snackbar('Error'.tr, 'No se pudo obtener los datos del usuario'.tr);
    }
  }

  // Función para guardar la configuración
  void _saveConfiguration() async {
    String newUsername = _usernameController.text.trim();
    String newName = _nameController.text.trim();
    String newEmail = _emailController.text.trim();
    String newPassword = _passController.text.trim();

    if (newUsername.isEmpty || newEmail.isEmpty || newPassword.isEmpty) {
      Get.snackbar('Error'.tr, 'Los campos no pueden estar vacíos'.tr);
    } else if (_userId == null) {
      Get.snackbar('Error'.tr, 'No se pudo obtener la ID del usuario'.tr);
    } else {
      // Crear un nuevo objeto UserModel con los datos actualizados
      UserModel updatedUser = UserModel(
        username: newUsername.isNotEmpty ? newUsername : userController.user.value!.username,
        name: newName.isNotEmpty ? newName : userController.user.value!.name,
        email: newEmail.isNotEmpty ? newEmail : userController.user.value!.email,
        password: newPassword.isNotEmpty ? newPassword : userController.user.value!.password,
        actualUbication: userController.user.value!.actualUbication,
        inHome: userController.user.value!.inHome,
        admin: userController.user.value!.admin,
        disabled: userController.user.value!.disabled,
      );

      // Llamar al método editUser para actualizar el usuario
      userController.editUser(updatedUser, _userId!);

      // Guardar los valores en SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', newUsername);
      await prefs.setString('email', newEmail);

      // Actualizar la pantalla principal
      setState(() {
        _username = newUsername;
        _email = newEmail;
      });

      // Mostrar confirmación y cerrar el diálogo
      Get.snackbar('Éxito'.tr, 'Configuración guardada correctamente'.tr);
      Navigator.pop(context);
    }
  }

  // Método para eliminar el usuario
  Future<void> _deleteUser() async {
    if (_userId != null) {
      int success = await userService.deleteUser(_userId!);
      if (success == 200) {
        Get.snackbar('Éxito'.tr, 'Usuario eliminado correctamente'.tr);

        // Eliminar los datos locales almacenados en SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove('user_id');
        await prefs.remove('user_data');
        await userService.logOut();

        // Redirigir a la pantalla de inicio de sesión después de la eliminación
        Get.offAllNamed('/login');
      } else {
        Get.snackbar('Error'.tr, 'No se pudo eliminar el usuario'.tr);
      }
    } else {
      Get.snackbar('Error'.tr, 'ID de usuario no disponible'.tr);
    }
  }

  // Método para mostrar el diálogo de confirmación
  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('¿Estas Seguro?'.tr),
          content: Text('¿Estás seguro de que deseas eliminar tu cuenta? Esta acción es irreversible.'.tr),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'.tr),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteUser();
              },
              child: Text('Eliminar'.tr),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE5E5E5),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Contenedor superior con esquinas redondeadas
            Container(
              width: 500,
              decoration: BoxDecoration(
                color: Color(0xFF89AFAF),
                borderRadius: BorderRadius.circular(20.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 5,
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  "Configuración de Perfil".tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

                      const SizedBox(height: 16), // Separación entre el contenedor superior y el formulario
            // Contenedor principal con el formulario
            Container(
              width: 500,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.0), // Redondear solo las esquinas del formulario
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 5,
                    blurRadius: 10,
                    offset: const Offset(0, 3), // Sombra suave
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Nombre de Usuario'.tr,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nombre Completo'.tr,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Correo Electrónico'.tr,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passController,
                      decoration: InputDecoration(
                        labelText: 'Contraseña'.tr,
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true, // Para ocultar la contraseña
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _saveConfiguration, // Guardar configuración
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF89AFAF),
                        foregroundColor: Colors.white, // Color del texto
                        minimumSize: const Size(double.infinity, 50), // Botón ancho
                      ),
                      child: Text('Guardar'.tr),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _showDeleteConfirmationDialog, // Mostrar diálogo de confirmación
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white, // Color del texto
                        minimumSize: const Size(double.infinity, 50), // Botón ancho
                      ),
                      child: Text('Eliminar Cuenta'.tr),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

}
}
