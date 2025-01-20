import 'package:dio/dio.dart';
import '../models/chat.dart';

class ChatService {
  static final Dio _dio =
      Dio(BaseOptions(baseUrl: "http://127.0.0.1:3000/api/chat"));

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

  // Método para crear un grupo
  static Future<dynamic> createGroup({
    required String groupName,
    required List<String> participants,
  }) async {
    try {
      final response = await _dio.post(
        "/group/create",
        data: {"groupName": groupName, "participants": participants},
      );

      if (response.statusCode == 201) {
        return response.data; // Retorna el grupo recién creado
      } else {
        print("Error al crear grupo: ${response.data}");
        return null;
      }
    } catch (e) {
      print("Error al crear grupo: $e");
      throw Exception("No se pudo crear el grupo.");
    }
  }

/*
  static Future<dynamic> createGroup({
    required String groupName,
    required List<String> participants,
  }) async {
    try {
      final response = await _dio.post(
        "/createGroup",
        data: {"groupName": groupName, "participants": participants},
      );

      return response.data; // Retornar la respuesta del backend
    } catch (e) {
      print("Error al crear grupo: $e");
      throw Exception("No se pudo crear el grupo.");
    }
  }

  */
}
