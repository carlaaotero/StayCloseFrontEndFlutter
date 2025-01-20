import 'package:get/get.dart';
import '../models/chat.dart';
import '../services/chatService.dart';
import 'userController.dart';

class ChatController extends GetxController {
  var isLoading = false.obs; // Indicador de carga
  var chatId = ''.obs; // Almacena el chatId actual
  var userChats = <Chat>[].obs; // Lista de chats existentes

  // Instancia de UserController
  final UserController userController = Get.find<UserController>();

  // Método para obtener o crear un chat
  Future<void> getOrCreateChat({
    required String sender,
    required String receiver,
  }) async {
    // Prevenir solicitudes múltiples simultáneas
    if (isLoading.value) return;
    try {
      isLoading.value = true;

      // Llamada al servicio para obtener o crear el chat
      final result = await ChatService.createOrGetChat(
        sender: sender,
        receiver: receiver,
      );
      if (result.isNotEmpty) {
        chatId.value = result; // Guardar el chatId obtenido
        print("Chat creado u obtenido con ID: $result");
      } else {
        throw Exception("El servicio devolvió un chatId vacío.");
      }
    } catch (e) {
      print("Error al obtener o crear el chat: $e");
      Get.snackbar("Error", "No se pudo obtener o crear el chat");
    } finally {
      isLoading.value = false;
    }
  }

  // Método para obtener los chats del usuario
  Future<void> fetchUserChats(String userId) async {
    if (isLoading.value) return;
    try {
      isLoading.value = true;

      // Llamada al servicio para obtener los chats
      final chats = await ChatService.getUserChats(userId);
      userChats.value = chats;
    } catch (e) {
      print("Error al obtener los chats del usuario: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // Método para crear un grupo

  Future<void> createGroup({
    required String groupName,
    required List<String> participants,
  }) async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;

      // Llamar al servicio para crear el grupo
      final response = await ChatService.createGroup(
        groupName: groupName,
        participants: participants,
      );

      if (response != null) {
        print("Grupo creado con éxito: $response");

        Get.snackbar("Éxito", "Grupo creado correctamente.");
        // Actualizar la lista de chats del usuario
        await fetchUserChats(userController.currentUserName.value);
      } else {
        throw Exception("Error al crear el grupo.");
      }
    } catch (e) {
      print("Error al crear grupo: $e");
      Get.snackbar("Error", "No se pudo crear el grupo.");
    } finally {
      isLoading.value = false;
    }
  }

/*
  Future<void> createGroup({
    required String groupName,
    required List<String> participants,
  }) async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;

      // Llamar al servicio para crear el grupo
      final response = await ChatService.createGroup(
        groupName: groupName,
        participants: participants,
      );

      if (response != null) {
        print("Grupo creado con éxito: $response");
        Get.snackbar("Éxito", "Grupo creado correctamente.");
      } else {
        throw Exception("Error al crear el grupo.");
      }
    } catch (e) {
      print("Error al crear grupo: $e");
      Get.snackbar("Error", "No se pudo crear el grupo.");
    } finally {
      isLoading.value = false;
    }
  }

  */
}
