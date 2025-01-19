/*import 'package:dio/dio.dart';

class MessageService {
  static final Dio _dio = Dio();
  static const String _baseUrl = 'http://127.0.0.1:3000/api/message';

  // Enviar un mensaje
  static Future<void> sendMessage({
    required String senderUsername,
    required String receiverUsername,
    required String content,
  }) async {
    try {
      final chatId = _generateChatId(senderUsername, receiverUsername);
      await _dio.post('$_baseUrl/send', data: {
        'chatId': chatId,
        'sender': senderUsername,
        'receiver': receiverUsername,
        'content': content,
      });
    } catch (e) {
      print('Error al enviar el mensaje: $e');
      throw e;
    }
  }

  // Generar un ID de chat único basado en los participantes
  static String _generateChatId(String sender, String receiver) {
    final participants = [sender, receiver];
    participants.sort(); // Orden alfabético para un ID consistente
    return participants.join('_');
  }

  static Future<List<Map<String, dynamic>>> getMessages(String chatId) async {
    try {
      final response = await _dio.get('$_baseUrl/$chatId/messages');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      print('Error al obtener mensajes: $e');
      throw e;
    }
  }
}

*/

import 'package:dio/dio.dart';

class MessageService {
  static final Dio _dio =
      Dio(BaseOptions(baseUrl: "http://147.83.7.155:3000/api/message"));

  // Método para enviar mensajes
  static Future<void> sendMessage({
    required String chatId,
    required String senderUsername,
    required String receiverUsername,
    required String content,
  }) async {
    try {
      await _dio.post(
        "/send",
        data: {
          "chatId": chatId,
          "sender": senderUsername,
          "receiver": receiverUsername,
          "content": content,
        },
      );
    } catch (e) {
      print("Error al enviar el mensaje: $e");
      throw Exception("No se pudo enviar el mensaje");
    }
  }

  // Método para obtener mensajes de un chat
  static Future<List<Map<String, dynamic>>> getMessages(String chatId) async {
    try {
      final response = await _dio.get("/$chatId/messages");
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      print("Error al obtener mensajes: $e");
      throw Exception("No se pudieron obtener los mensajes");
    }
  }
}



/*

import 'package:dio/dio.dart';
import '../models/message.dart';

class MessageService {
  static final Dio _dio =
      Dio(BaseOptions(baseUrl: "http://127.0.0.1:3000/api/message"));

  static Future<List<Message>> getMessages(String chatId) async {
    try {
      final response = await _dio.get("/$chatId/messages");
      return (response.data as List)
          .map((message) => Message.fromJson(message))
          .toList();
    } catch (e) {
      print("Error al obtener mensajes: $e");
      throw Exception("No se pudieron obtener los mensajes.");
    }
  }

  static Future<Message> sendMessage({
    required String chatId,
    required String senderUsername,
    required String receiverUsername,
    required String content,
  }) async {
    try {
      final response = await _dio.post(
        "/send",
        data: {
          "chatId": chatId,
          "sender": senderUsername,
          "receiver": receiverUsername,
          "content": content,
        },
      );
      return Message.fromJson(response.data);
    } catch (e) {
      print("Error al enviar el mensaje: $e");
      throw Exception("No se pudo enviar el mensaje.");
    }
  }
}

*/