import 'package:dio/dio.dart';
import '../models/chat.dart';

class ChatService {
  static final Dio _dio =
      Dio(BaseOptions(baseUrl: "http://147.83.7.155:3000/api/chat"));

  // Método para obtener o crear un chat
  static Future<String> createOrGetChat({
    required String sender,
    required String receiver,
  }) async {
    try {
      final response = await _dio.post(
        "/createOrGetChat",
        data: {"sender": sender, "receiver": receiver},
      );

      return response.data['chatId']; // Retornar el chatId
    } catch (e) {
      print("Error al buscar o crear chat: $e");
      throw Exception("No se pudo obtener el chatId");
    }
  }

  // Método para obtener los chats del usuario
  static Future<List<Chat>> getUserChats(String userId) async {
    try {
      final response = await _dio.get("/user/$userId");
      return (response.data as List)
          .map((chat) => Chat.fromJson(chat))
          .toList();
    } catch (e) {
      print("Error al obtener los chats: $e");
      throw Exception("No se pudieron obtener los chats.");
    }
  }
}
