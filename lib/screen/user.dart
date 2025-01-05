/*import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/userServices.dart';
import 'package:flutter_application_1/controllers/userListController.dart';
import 'package:flutter_application_1/controllers/registerController.dart';
import 'package:flutter_application_1/Widgets/userCard.dart';
import 'package:get/get.dart';


class UserPage extends StatefulWidget {
  @override
  _UserPageState createState() => _UserPageState();
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User'),
      ),
    );
  }
}

class _UserPageState extends State<UserPage> {
  List<dynamic> _data = [];
  final UserService _userService = UserService();
  final RegisterController registerController = Get.put(RegisterController());
  final UserListController userController = Get.put(UserListController());

  bool _isLoading = false;
  String? _errorMessage;
  String? _usernameError;
  String? _mailError;
  String? _passwordError;
  String? _commentError;

  @override
  void initState() {
    super.initState();
    getUsers(); // truquem a la funció per obtenir la llista d'usuaris
  }

  Future<void> getUsers() async {
    final data = await _userService.getUsers();
    setState(() {
      _data = data;
    });
  }

  // funció per eliminar un usuari
  Future<void> deleteUser(String userId) async {
    final response = await _userService.deleteUser(userId);

    if (response ==201) {
      setState(() {
        _data.removeWhere((user) => user['_id'] == userId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuari eliminat amb èxit!'),
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error desconegut al eliminar'),
        ),
      );
    }
  }

  // Funció per eliminar un usuari amb confirmació
  Future<void> _confirmDeleteUser(String userId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Estàs segur?'),
          content: Text('Vols eliminar aquest usuari? Aquesta acció no es pot desfer.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Cancela l'eliminació
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Confirma l'eliminació
              },
              child: Text('Sí'),
            ),
          ],
        );
      },
    ) ?? false; // Si el diàleg es tanca sense selecció, retornem false

    // Si l'usuari confirma, eliminem l'usuari
    if (confirm) {
      await deleteUser(userId);
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text('User Management')),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Lista de usuarios
          Expanded(
            child: Obx(() {
              if (userController.isLoading.value) {
                return Center(child: CircularProgressIndicator());
              } else if (userController.userList.isEmpty) {
                return Center(child: Text("No hay usuarios disponibles"));
              } else {
                return ListView.builder(
                  itemCount: userController.userList.length,
                  itemBuilder: (context, index) {
                    return UserCard(user: userController.userList[index]);
                  },
                );
              }
            }),
          ),
          SizedBox(width: 20),
          // Formulario de registro de usuario
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Crear Nuevo Usuario',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                TextField(
                  controller: registerController.usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    errorText: _commentError,
                  ),
                ),
                TextField(
                  controller: registerController.nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    errorText: _usernameError, // Definir o eliminar estas variables
                  ),
                ),
                TextField(
                  controller: registerController.emailController,
                  decoration: InputDecoration(
                    labelText: 'Mail',
                    errorText: _mailError,
                  ),
                ),
                TextField(
                  controller: registerController.passwordController,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    errorText: _passwordError,
                  ),
                  obscureText: true,
                ),
                
                SizedBox(height: 16),
                Obx(() {
                  if (registerController.isLoading.value) {
                    return CircularProgressIndicator();
                  } else {
                    return ElevatedButton(
                      onPressed: registerController.signUp,
                      child: Text('Registrarse'),
                    );
                  }
                }),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
}
*/
