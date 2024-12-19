import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_application_1/controllers/userController.dart';
import 'package:flutter_application_1/Widgets/bottomNavigationBar.dart';
import 'package:flutter_application_1/screen/postScreen.dart';
import 'package:flutter_application_1/screen/logIn.dart';
import 'package:flutter_application_1/screen/register.dart';
import 'package:flutter_application_1/screen/home.dart';
import 'package:flutter_application_1/screen/perfilScreen.dart';
import 'package:flutter_application_1/screen/mapScreen.dart';
import 'package:cloudinary_flutter/cloudinary_context.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';
import 'package:flutter_application_1/screen/calendarScreen.dart'; 
import 'package:flutter_background/flutter_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configuració del servei en segon pla 
  const androidConfig = FlutterBackgroundAndroidConfig(
    notificationTitle: 'Execució en segon pla',
    notificationText: 'Aplicació activa en segon pla'
  );

  bool success = await FlutterBackground.initialize(androidConfig: androidConfig);
  if (success) {
    await FlutterBackground.enableBackgroundExecution();
  }

  CloudinaryContext.cloudinary = Cloudinary.fromCloudName(cloudName: "djen7vqby");
  Get.put(UserController());
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      getPages: [
        GetPage(
          name: '/login',
          page: () => LogInPage(),
        ),
        GetPage(
          name: '/register',
          page: () => RegisterPage(),
        ),
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
        ),
        GetPage(
          name: '/perfil',
          page: () => BottomNavScaffold(child: PerfilScreen()),
        ),
      ],
    );
  }
}
