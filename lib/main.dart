import 'package:cloudinary_flutter/cloudinary_object.dart';
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
import 'package:flutter_application_1/screen/mapScreen.dart';
import 'package:cloudinary_flutter/cloudinary_context.dart';
//import 'package:cloudinary_flutter/image/cld_image.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';
import 'package:flutter_application_1/screen/calendarScreen.dart'; 
import 'package:flutter_application_1/services/backgroundServices.dart';
import 'package:flutter/material.dart';

void main() async {

  
  WidgetsFlutterBinding.ensureInitialized();
  // Logs per depuració
  debugPrint('Comprovant permisos i inicialitzant BackgroundService...');
  await BackgroundService.initialize().catchError((e) {
    debugPrint('Error inicialitzant el servei de segon pla: $e');
  });

  CloudinaryContext.cloudinary = Cloudinary.fromCloudName(cloudName: "djen7vqby");
  Get.put(UserController());  // Esto asegura que el controlador se ponga en el GetX 'depósito'
  

  runApp(
    MyApp(),
  );
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
        GetPage(
          name: '/mapa',
          page: () => BottomNavScaffold(child: MapScreen()),
        ),
        GetPage(
          name: '/calendario',
          page: () => BottomNavScaffold(child: CalendarScreen()),
        ),/*
        GetPage(
          name: '/chat',
          page: () => BottomNavScaffold(child: PerfilScreen()),
        ),*/
        GetPage(
          name: '/perfil',
          page: () => BottomNavScaffold(child: PerfilScreen()),
        ),
      ],
    );
  }
}