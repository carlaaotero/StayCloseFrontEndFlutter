import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:get/get.dart';

class SocketService extends GetxService {
  late IO.Socket _socket; // Instancia del socket
  RxList<Map<String, dynamic>> messages =
      <Map<String, dynamic>>[].obs; // Mensajes observables

  @override
  void onInit() {
    super.onInit();
    _initConfig(); // Inicializar configuración
  }

  void _initConfig() {
    _socket = IO.io(
      'http://localhost:3000',
      IO.OptionBuilder()
          .setTransports(['websocket']) // Usar transporte websocket
          .disableAutoConnect() // Deshabilitar auto conexión
          .build(),
    );

    // Evento de conexión
    _socket.onConnect((_) {
      print('Conectado al servidor');
    });

    // Evento de desconexión
    _socket.onDisconnect((_) {
      print('Desconectado del servidor');
    });

    // Escuchar nuevos mensajes desde el servidor
    _socket.on('newMessage', (data) {
      messages.add(data
          as Map<String, dynamic>); // Agregar mensaje a la lista observable
    });
  }

  // Método para conectar el socket manualmente
  void connect() {
    if (!_socket.connected) {
      _socket.connect();
    }
  }

  // Método para desconectar el socket
  void disconnect() {
    if (_socket.connected) {
      _socket.disconnect();
    }
  }

  // Método para enviar un mensaje privado
  void sendPrivateMessage(String message, String sender, String recipient) {
    final data = {
      'content': message,
      'sender': sender,
      'recipient': recipient, // Especifica el destinatario
    };

    _socket.emit('message', data); // Emitir evento al servidor
    messages.add(data); // Agregar mensaje enviado a la lista local
  }

  IO.Socket get socket => _socket; // Getter para la instancia del socket
}
