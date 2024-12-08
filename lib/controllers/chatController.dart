import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatController {
  late IO.Socket socket;
  final StreamController<List<String>> _messagesController =
      StreamController<List<String>>.broadcast();
  List<String> _messages = []; // Lista para almacenar los mensajes

  Stream<List<String>> get messagesStream => _messagesController.stream;

  void connect() {
    // Conectar al servidor de Socket.IO
    socket = IO.io('http://127.0.0.1:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    // Escuchar el evento de conexión
    socket.onConnect((_) {
      print('Conectado al servidor');
    });

    // Escuchar el evento de recibir mensajes
    socket.on('receiveMessage', (data) {
      print('Mensaje recibido: $data');
      _handleReceivedMessage(data);
    });

    // Escuchar el evento de desconexión
    socket.onDisconnect((_) {
      print('Desconectado del servidor');
    });
  }

  void _handleReceivedMessage(String message) {
    _messages.add(message); // Agregar el mensaje a la lista
    _messagesController.add(_messages); // Emitir la lista actualizada
  }

  void sendMessage(String message, String sender) {
    // Emitir el evento de enviar mensaje
    socket.emit('sendMessage', {'message': message, 'sender': sender});
  }

  void dispose() {
    // Cerrar la conexión al socket cuando ya no sea necesario
    socket.dispose();
    _messagesController.close(); // Cerrar el StreamController
  }
}
