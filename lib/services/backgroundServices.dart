import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:workmanager/workmanager.dart';

class BackgroundService {
  static Future<void> initialize() async {
    // Sol·licitar permisos abans de començar el servei
    await _requestPermissions();

    // Configurar el servei en segon pla per a Android.
    await FlutterBackground.initialize();

    // Activar el servei en segon pla per a la ubicació.
    await FlutterBackground.enableBackgroundExecution();

    // Configurar el treball en segon pla per obtenir la ubicació.
    Workmanager().initialize(callbackDispatcher);

    // Registra un treball periòdic per obtenir la ubicació cada 15 minuts.
    Workmanager().registerPeriodicTask(
      'location_task',
      'get_location_task',
      frequency: Duration(minutes: 15), // Cada 15 minuts
      initialDelay: Duration(seconds: 10), // Es crida després de 10 segons
    );
  }

  // Funció per sol·licitar permisos de localització.
  static Future<void> _requestPermissions() async {
    // Comprova si el servei de localització està habilitat.
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Si no estan habilitats, retorna un error
      throw Exception('Els serveis de localització estan desactivats.');
    }

    // Comprovar els permisos de localització.
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Si el permís està denegat, el sol·licitem.
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
        // Si el permís continua denegat, llança un error
        throw Exception('Permís de localització denegat');
      }
    }

 
  }

  // La funció que s'executarà quan es cridi el treball en segon pla.
  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      // Obtenir la ubicació i enviar una notificació.
      try {
        Position position = await _getCurrentLocation();
        // Enviar notificació de la ubicació
        _sendNotification(position);
      } catch (e) {
        print("Error: $e");
      }
      return Future.value(true);
    });
  }

  // Funció per obtenir la ubicació.
  static Future<Position> _getCurrentLocation() async {
    // Obtenir la posició actual de l'usuari.
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  // Funció per enviar una notificació amb la ubicació.
  static void _sendNotification(Position position) async {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // Configurar els detalls de la notificació per Android
    var androidDetails = AndroidNotificationDetails(
      'location_channel',
      'Location Updates',
      channelDescription: 'Notifications for location updates',
      importance: Importance.high,
      priority: Priority.high,
    );

    var notificationDetails = NotificationDetails(android: androidDetails);

    // Enviar la notificació amb la latitud i longitud.
    flutterLocalNotificationsPlugin.show(
      0,
      'Ubicació actual',
      'Latitud: ${position.latitude}, Longitud: ${position.longitude}',
      notificationDetails,
    );
  }
}
