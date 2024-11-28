import 'package:get/get.dart';
import '../services/chat_service.dart';

class ChatController extends GetxController {
  final ChatService chatService = ChatService();
  final RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    chatService.connect();

    // Escuchar mensajes del servidor
    chatService.socket.on('chat-messages', (data) {
      messages.assignAll(List<Map<String, dynamic>>.from(data));
    });
  }

  // Enviar mensaje
  void sendMessage(String sender, String text) {
    if (text.trim().isEmpty) return;
    chatService.sendMessage(sender, text);
  }

  @override
  void onClose() {
    chatService.disconnect();
    super.onClose();
  }
}
