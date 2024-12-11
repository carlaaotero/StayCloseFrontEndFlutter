import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_application_1/controllers/userController.dart';
import 'package:flutter_application_1/Widgets/bottomNavigationBar.dart';
import 'package:flutter_application_1/screen/postScreen.dart';
import 'package:flutter_application_1/screen/logIn.dart';
import 'package:flutter_application_1/screen/register.dart';
//import 'package:flutter_application_1/screen/user.dart';
import 'package:flutter_application_1/screen/home.dart';
import 'package:flutter_application_1/screen/perfilScreen.dart';
import 'package:flutter_application_1/screen/chattscreen.dart';
import 'package:flutter_application_1/services/socketService.dart';

void main() {
  runApp(
    MyApp(),
  );
  Get.put(
      UserController()); // Esto asegura que el controlador se ponga en el GetX 'depósito'
  Get.put(SocketService()); // Registra el servicio de sockets
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      getPages: [
        // Ruta de inicio de sesión
        GetPage(
          name: '/login',
          page: () => LogInPage(),
        ),
        // Ruta de registro
        GetPage(
          name: '/register',
          page: () => RegisterPage(),
        ),
        // Ruta de la pantalla principal con BottomNavScaffold
        GetPage(
          name: '/home',
          page: () => BottomNavScaffold(child: HomePage()),
        ),
        GetPage(
          name: '/posts',
          page: () => BottomNavScaffold(child: PostsScreen()),
        ),
        /*GetPage(
          name: '/mapa',
          page: () => BottomNavScaffold(child: PerfilScreen()),
        ),
        GetPage(
          name: '/calendario',
          page: () => BottomNavScaffold(child: PerfilScreen()),
        ), */
        GetPage(
          name: '/chat',
          page: () => BottomNavScaffold(
              child: ChatScreen(
            currentUser: 'user1', // Cambia esto según tu lógica
            recipient: 'user2', // Cambia esto según tu lógica
          )),
        ),
        GetPage(
          name: '/perfil',
          page: () => BottomNavScaffold(child: PerfilScreen()),
        ),
      ],
    );
  }
}
