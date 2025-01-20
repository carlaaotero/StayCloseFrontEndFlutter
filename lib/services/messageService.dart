
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


