//servicios para interactuar con el backend del chat
/*
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/message_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';

class ChatService {
  final String baseUrl =
      'http://localhost:3000/api'; // Cambia si tu backend está en otro servidor.
  //'ws://localhost:8080';

  // Obtener el token del almacenamiento seguro (deberías tener un servicio para esto)
  Future<String> getToken() async {
    // Simulación, reemplaza esto con tu método real de obtención de token
    return 'Bearer your_jwt_token';
  }

  // Obtener usuarios conectados
  Future<List<UserModel>> getOnlineUsers() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/users/online'),
      headers: {'Authorization': token},
    );
    /*

    if (response.statusCode == 200) {
      final List<dynamic> usersJson = json.decode(response.body);
      return usersJson.map((json) => UserModel.fromJson(json)).toList();
    } else {
      throw Exception('Error al obtener usuarios conectados');
    }
    */
      if (response.statusCode == 200) {
      final List<dynamic> usersJson = json.decode(response.body);
      return usersJson.map((json) => UserModel.fromJson(json)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('No autorizado. Revisa tu token.');
    } else {
      throw Exception('Error al obtener usuarios conectados. Código: ${response.statusCode}');
    }
  } catch(e) {
    throw Exception('Error de red: $e');
  }
  }

  // Obtener grupos
  Future<List<dynamic>> getGroups() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/users/groups'),
      headers: {'Authorization': token},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al obtener grupos');
    }
  }

  // Enviar un mensaje
  Future<void> sendMessage(String senderId, String? receiverId, String? groupId,
      String content) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/messages/send'),
      headers: {
        'Authorization': token,
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'senderId': senderId,
        'receiverId': receiverId,
        'groupId': groupId,
        'content': content,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Error al enviar el mensaje');
    }
  }

  // Obtener mensajes de una conversación o grupo
  Future<List<MessageModel>> getMessages(String conversationId,
      {bool isGroup = false}) async {
    final token = await getToken();
    final endpoint = isGroup
        ? '$baseUrl/messages/group/$conversationId'
        : '$baseUrl/messages/conversation/$conversationId';

    final response = await http.get(
      Uri.parse(endpoint),
      headers: {'Authorization': token},
    );

    if (response.statusCode == 200) {
      final List<dynamic> messagesJson = json.decode(response.body);
      return messagesJson.map((json) => MessageModel.fromJson(json)).toList();
    } else {
      throw Exception('Error al obtener los mensajes');
    }
  }

  // Obtener una conversación específica
  Future<List<MessageModel>> getConversation(String conversationId) async {
    return getMessages(conversationId, isGroup: false);
  }
  //obtener los token del sharePrefetences

  Future<String> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');
    if (token == null) {
      throw Exception('Token no encontrado. Inicia sesión nuevamente.');
    }
    return 'Bearer $token';
  }
}


import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class ChatService {
  final String baseUrl = 'http://localhost:3000/api';

  Future<String> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');
    if (token == null) {
      throw Exception('Token no encontrado. Inicia sesión nuevamente.');
    }
    return 'Bearer $token';
  }

  // Obtener usuarios conectados
  Future<List<UserModel>> getOnlineUsers() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/user/online'),
      headers: {'Authorization': token},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => UserModel.fromJson(json)).toList();
    } else {
      throw Exception('Error al obtener usuarios conectados');
    }
  }

  Future<List<dynamic>> getGroups() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/user/groups'),
      headers: {'Authorization': token},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al obtener grupos');
    }
  }
}


 // Obtener mensajes de una conversación o grupo
  Future<List<MessageModel>> getMessages(String conversationId, {bool isGroup = false}) async {
    final token = await getToken();
    final endpoint = isGroup
        ? '$baseUrl/messages/group/$conversationId'
        : '$baseUrl/messages/conversation/$conversationId';

    final response = await http.get(
      Uri.parse(endpoint),
      headers: {'Authorization': token},
    );

    if (response.statusCode == 200) {
      final List<dynamic> messagesJson = json.decode(response.body);
      return messagesJson.map((json) => MessageModel.fromJson(json)).toList();
    } else {
      throw Exception('Error al obtener los mensajes. Código: ${response.statusCode}');
    }
  }
  // Enviar un mensaje
  Future<void> sendMessage(String senderId, String? receiverId, String? groupId, String content) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/messages/send'),
      headers: {
        'Authorization': token,
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'senderId': senderId,
        'receiverId': receiverId,
        'groupId': groupId,
        'content': content,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Error al enviar el mensaje. Código: ${response.statusCode}');
    }
  }

*/
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message_model.dart';
import '../models/user.dart';

class ChatService {
  final String baseUrl = 'http://localhost:3000/api';

  // Obtener el token desde SharedPreferences
  Future<String> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');
    if (token == null) {
      throw Exception('Token no encontrado. Inicia sesión nuevamente.');
    }
    return 'Bearer $token';
  }

  // Obtener el ID del usuario logueado desde SharedPreferences
  Future<String?> getCurrentUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id'); // Recupera el ID almacenado
  }

  // Obtener mensajes de una conversación o grupo
  Future<List<MessageModel>> getMessages(String conversationId,
      {bool isGroup = false}) async {
    final token = await getToken();
    final endpoint = isGroup
        ? '$baseUrl/messages/group/$conversationId'
        : '$baseUrl/messages/conversation/$conversationId';

    final response = await http.get(
      Uri.parse(endpoint),
      headers: {'Authorization': token},
    );

    if (response.statusCode == 200) {
      final List<dynamic> messagesJson = json.decode(response.body);
      return messagesJson.map((json) => MessageModel.fromJson(json)).toList();
    } else {
      throw Exception(
          'Error al obtener los mensajes. Código: ${response.statusCode}');
    }
  }

  // Enviar un mensaje
  Future<void> sendMessage(
      String content, String? receiverId, String? groupId) async {
    final String? senderId = await getCurrentUserId();
    if (senderId == null) {
      throw Exception('Usuario no logueado o ID no encontrado.');
    }

    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/messages/send'),
      headers: {
        'Authorization': token,
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'senderId': senderId, // Usa el ID del usuario logueado
        'receiverId': receiverId,
        'groupId': groupId,
        'content': content,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(
          'Error al enviar el mensaje. Código: ${response.statusCode}');
    }
  }

  // Obtener usuarios conectados
  Future<List<UserModel>> getOnlineUsers() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/user/online'),
      headers: {'Authorization': token},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => UserModel.fromJson(json)).toList();
    } else {
      throw Exception('Error al obtener usuarios conectados');
    }
  }

  // Obtener grupos
  Future<List<dynamic>> getGroups() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/user/groups'),
      headers: {'Authorization': token},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al obtener grupos');
    }
  }
}
