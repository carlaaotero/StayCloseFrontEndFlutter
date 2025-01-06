/* import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  late final WebSocketChannel _channel;

  WebSocketService(String url) {
    _channel = WebSocketChannel.connect(Uri.parse(url));
  }

  // Escuchar mensajes
  Stream get messages => _channel.stream;

  // Enviar mensaje al WebSocket
  void sendMessage(Map<String, dynamic> message) {
    _channel.sink.add(message);
  }

  // Notificar estado de usuario
  void notifyStatus(String userId, String status) {
    sendMessage({
      'type': 'status',
      'userId': userId,
      'status': status,
    });
  }

  // Cerrar conexión
  void close() {
    _channel.sink.close();
  }
}
*/
/*
//06/01
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  late final WebSocketChannel _channel;

  WebSocketService(String url) {
    _channel = WebSocketChannel.connect(Uri.parse("ws://localhost:8080"));
  }

  // Escuchar mensajes del WebSocket
  Stream get messages => _channel.stream.map((message) => json.decode(message));

  // Enviar mensaje al WebSocket
  void sendMessage(Map<String, dynamic> message) {
    _channel.sink.add(json.encode(message));
  }

  // Notificar estado de usuario (ejemplo: online/offline)
  void notifyStatus(String userId, String status) {
    sendMessage({
      'type': 'status',
      'userId': userId,
      'status': status,
    });
  }

  // Cerrar la conexión WebSocket
  void close() {
    _channel.sink.close();
  }
}
*/
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WebSocketService {
  late final WebSocketChannel _channel;

  WebSocketService(String url) {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      print("WebSocket conectado a $url");
    } catch (e) {
      print("Error al conectar WebSocket: $e");
    }
  }

  // Escuchar mensajes del WebSocket
  Stream<Map<String, dynamic>> get messages => _channel.stream
      .map((message) => json.decode(message) as Map<String, dynamic>);

  // Enviar mensaje al WebSocket
  void sendMessage(Map<String, dynamic> message) {
    try {
      _channel.sink.add(json.encode(message));
      print("Mensaje enviado: $message");
    } catch (e) {
      print("Error al enviar mensaje: $e");
    }
  }

  // Notificar estado del usuario (online/offline)
  Future<void> notifyStatus(String status) async {
    final String? userId = await getUserId();
    if (userId == null) {
      print("No se encontró userId en SharedPreferences.");
      return;
    }

    sendMessage({
      'type': 'status',
      'userId': userId,
      'status': status,
    });
  }

  // Recuperar userId desde SharedPreferences
  Future<String?> getUserId() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_id');
    } catch (e) {
      print("Error al obtener user_id: $e");
      return null;
    }
  }

  // Recuperar token desde SharedPreferences
  Future<String?> getToken() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString('authToken');
    } catch (e) {
      print("Error al obtener token: $e");
      return null;
    }
  }

  // Cerrar conexión WebSocket
  void close() {
    try {
      _channel.sink.close();
      print("Conexión WebSocket cerrada.");
    } catch (e) {
      print("Error al cerrar WebSocket: $e");
    }
  }
}
