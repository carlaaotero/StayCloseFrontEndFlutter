import 'package:web_socket_channel/web_socket_channel.dart';

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
