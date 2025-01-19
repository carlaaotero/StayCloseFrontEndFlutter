//V1.2

import 'package:cloudinary_flutter/cloudinary_object.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen/UserListScreen.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_application_1/controllers/userController.dart';
import 'package:flutter_application_1/Widgets/bottomNavigationBar.dart';
import 'package:flutter_application_1/screen/postScreen.dart';
import 'package:flutter_application_1/screen/logIn.dart'; // Importa LogInPage una sola vez
import 'package:flutter_application_1/screen/register.dart'; // Importa RegisterPage una sola vez
import 'package:flutter_application_1/screen/home.dart';
import 'package:flutter_application_1/screen/perfilScreen.dart';
import 'package:flutter_application_1/screen/mapScreen.dart';
import 'package:cloudinary_flutter/cloudinary_context.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';
import 'package:flutter_application_1/screen/calendarScreen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_application_1/translation_service.dart'; // Asegúrate de que el archivo esté en la ruta correcta
import 'package:flutter_application_1/controllers/themeController.dart';
import 'package:flutter_application_1/screen/chatScreen.dart';
import 'package:flutter_application_1/controllers/chatController.dart';

void main() {
  CloudinaryContext.cloudinary =
      Cloudinary.fromCloudName(cloudName: "djen7vqby");
  GetStorage.init(); // Inicializar GetStorage para guardar el estado del tema
  Get.put(
      UserController()); // Esto asegura que el controlador se ponga en el GetX 'depósito'
  Get.put(ThemeController());
  Get.put(ChatController());
  runApp(
    MyApp(),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ThemeController themeController =
        Get.find(); // Obtiene el controlador del tema
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
        primaryColor: Colors.teal,
        scaffoldBackgroundColor: Color(0xFFE0F7FA),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF89AFAF),
          titleTextStyle:
              TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black54),
          titleLarge: TextStyle(color: Colors.black),
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor:
            Colors.grey[800], // Color principal per al mode fosc (gris fosc)
        scaffoldBackgroundColor:
            Color(0xFF121212), // Fons fosc per les pantalles
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[850], // AppBar en gris fosc
          titleTextStyle:
              TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
          titleLarge: TextStyle(color: Colors.white),
        ),
        buttonTheme: ButtonThemeData(
            buttonColor: Colors.grey[700]), // Botons amb gris fosc
        iconTheme: IconThemeData(color: Colors.white70), // Icones en gris clar
      ),
      themeMode:
          themeController.isDarkMode.value ? ThemeMode.dark : ThemeMode.light,
      locale: Locale('es', 'ES'), // Idioma predeterminado
      translations: TranslationService(), // Usa la nueva clase de traducción
      fallbackLocale: Locale('en', 'US'), // Idioma de respaldo
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('en', 'US'),
        const Locale('es', 'ES'),
        const Locale('ca', 'ES'),
      ],
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
          name: '/mapa'.tr,
          page: () => BottomNavScaffold(child: MapScreen()),
        ),
        GetPage(
          name: '/calendario',
          page: () => BottomNavScaffold(child: CalendarScreen()),
        ),

        GetPage(
          name: '/chat',
          page: () => BottomNavScaffold(
            child: UserListScreen(),
          ),
        ),
        GetPage(
          name: '/perfil',
          page: () => BottomNavScaffold(child: PerfilScreen()),
        ),
      ],
    );
  }
}
