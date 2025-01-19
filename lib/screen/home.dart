//V1.2

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/controllers/userController.dart';
import 'package:flutter_application_1/controllers/eventController.dart';
import 'package:flutter_application_1/screen/calendarScreen.dart';
import 'package:flutter_application_1/controllers/themeController.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final EventController eventController = Get.put(EventController()); // Instancia de EventController

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 1.0, end: 1.1).animate(_controller);

    // Cargar eventos al iniciar
    eventController.fetchIncomingEvents();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Función para abrir una llamada de emergencia
  _contactEmergency() async {
    const emergencyPhoneNumber = 'tel:+34639574144';
    if (await canLaunch(emergencyPhoneNumber)) {
      await launch(emergencyPhoneNumber);
    } else {
      throw 'No se puede realizar la llamada'.tr;
    }
  }

  @override
  Widget build(BuildContext context) {
    Get.put(UserController());

    // Obtener el ThemeController para acceder a la función de cambio de tema
    final ThemeController themeController = Get.find();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight), // Usamos el tamaño predeterminado del AppBar
        child: Obx(() {
          return AppBar(
            title: Text('Inicio'.tr, // Traducción dinámica
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), // Tamaño y estilo fijo del texto
            backgroundColor: themeController.isDarkMode.value
                ? Color(0xFF555A6F) // Color para el modo oscuro
                : Color(0xFF89AFAF), // Color para el modo claro
            toolbarHeight: 70.0, // Altura fija del AppBar
            actions: [
              // Botón para cambiar tema
              IconButton(
                icon: Icon(Icons.brightness_6),
                onPressed: () {
                  themeController.toggleTheme(); // Cambiar tema
                },
              ),
              // Botón para cambio de idioma
              PopupMenuButton<String>(
                onSelected: (String languageCode) {
                  if (languageCode == 'ca') {
                    Get.updateLocale(Locale('ca', 'ES'));
                  } else if (languageCode == 'es') {
                    Get.updateLocale(Locale('es', 'ES'));
                  } else if (languageCode == 'en') {
                    Get.updateLocale(Locale('en', 'US'));
                  }
                },
                itemBuilder: (BuildContext context) {
                  return [
                    PopupMenuItem(value: 'ca', child: Text('Català')),
                    PopupMenuItem(value: 'es', child: Text('Español')),
                    PopupMenuItem(value: 'en', child: Text('English')),
                  ];
                },
              ),
            ],
          );
        }),
      ),
      body: Obx(() { // Obx para escuchar cambios en el tema
        return Container(
          color: themeController.getBackgroundColor('home'),
          child: Center(
            child: Container(
              padding: EdgeInsets.all(20),
              margin: EdgeInsets.symmetric(horizontal: 30), // Ajustado para que no sea demasiado pequeño
              decoration: BoxDecoration(
                color: themeController.isDarkMode.value
                    ? Colors.grey[800]!
                    : Color.fromARGB(194, 162, 204, 204),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: themeController.isDarkMode.value
                        ? Colors.white54
                        : Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Benvinguda a STAYCLOSE'.tr,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: themeController.isDarkMode.value
                          ? Colors.white70
                          : Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Ens alegra tenir-te aquí. Gaudeix d\'aquesta aplicació i mantén la teva comunitat segura.'
                        .tr,
                    style: TextStyle(
                      fontSize: 16,
                      color: themeController.isDarkMode.value
                          ? Colors.white54
                          : Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _animation.value,
                        child: Image.asset(
                          'assets/icons/logo.png',
                          height: 80,
                          width: 80,
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Próximos Eventos'.tr,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: themeController.isDarkMode.value
                          ? Colors.white70
                          : Colors.white,
                    ),
                  ),
                  SizedBox(height: 10),
                  // Desplegable dinámico para eventos
                  Obx(() {
                    if (eventController.isLoading.value) {
                      return CircularProgressIndicator();
                    } else if (eventController.events.isEmpty) {
                      return Text('No hay eventos próximos'.tr);
                    } else {
                      return ExpansionTile(
                        title: Text(
                          'Ver eventos próximos'.tr,
                          style: TextStyle(
                              fontSize: 16,
                              color: themeController.isDarkMode.value
                                  ? Colors.white
                                  : Colors.black),
                        ),
                        children: eventController.events.map((event) {
                          return Card(
                            color: themeController.isDarkMode.value
                                ? Colors.grey[700]
                                : Colors.white,
                            margin: EdgeInsets.symmetric(vertical: 2),
                            child: ListTile(
                              title: Text(event.name),
                              subtitle: Text(
                                DateFormat('yyyy-MM-dd').format(event.eventDate),
                              ),
                              trailing: Icon(Icons.event),
                              onTap: () {
                                // Navegar a la pantalla de calendario
                                Get.to(() => CalendarScreen(), arguments: {
                                  'selectedDay': event.eventDate,
                                });
                              },
                            ),
                          );
                        }).toList(),
                      );
                    }
                  }),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _contactEmergency,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeController.isDarkMode.value
                          ? Color.fromARGB(214, 255, 67, 67)
                          : Color.fromARGB(214, 255, 67, 67),
                      shape: CircleBorder(),
                      padding: EdgeInsets.all(20),
                    ),
                    child: Icon(
                      Icons.sos,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
