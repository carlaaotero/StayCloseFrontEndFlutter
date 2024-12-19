import 'package:flutter/material.dart';
import 'package:flutter_application_1/controllers/userController.dart';
import 'package:flutter_application_1/controllers/eventController.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_application_1/screen/calendarScreen.dart';
import 'package:intl/intl.dart';

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
    eventController.fetchEvents();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Función para abrir una llamada de emergencia
  _contactEmergency() async {
    const emergencyPhoneNumber = 'tel:+34 639845501';
    if (await canLaunch(emergencyPhoneNumber)) {
      await launch(emergencyPhoneNumber);
    } else {
      throw 'No se puede realizar la llamada';
    }
  }

  @override
  Widget build(BuildContext context) {
    Get.put(UserController());
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: const Color(0xFF89AFAF),
      ),
      body: Container(
        color: const Color(0xFFE0F7FA),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.symmetric(horizontal: 300),
            decoration: BoxDecoration(
              color: const Color.fromARGB(194, 162, 204, 204),
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Benvinguda a STAYCLOSE',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Ens alegra tenir-te aquí. Gaudeix d\'aquesta aplicació i mantén la teva comunitat segura.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
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
                const SizedBox(height: 20),
                const Text(
                  'Próximos Eventos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
                const SizedBox(height: 10),
                // Desplegable dinámico para eventos
                Obx(() {
                  if (eventController.isLoading.value) {
                    return const CircularProgressIndicator();
                  } else if (eventController.events.isEmpty) {
                    return const Text('No hay eventos próximos');
                  } else {
                    return ExpansionTile(
                      title: const Text(
                        'Ver eventos próximos',
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                      children: eventController.events.map((event) {
                        return Card(
                          color: Colors.white,
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          child: ListTile(
                            title: Text(event.name),
                            subtitle: Text(
                              DateFormat('yyyy-MM-dd').format(event.eventDate),
                            ),
                            trailing: const Icon(Icons.event),
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
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _contactEmergency,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(214, 255, 67, 67),
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(20),
                  ),
                  child: const Icon(
                    Icons.sos,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}