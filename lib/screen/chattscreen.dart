import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/socketService.dart';

class ChatScreen extends StatelessWidget {
  final TextEditingController _controller = TextEditingController();
  final String _currentUser =
      'User${DateTime.now().millisecondsSinceEpoch}'; // Simulación de usuario único
  final socketService =
      Get.find<SocketService>(); // Obtén el servicio de sockets con GetX

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat'),
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Obx(() {
              // Usar Obx para observar los mensajes en tiempo real
              return ListView.builder(
                itemCount: socketService.messages.length,
                itemBuilder: (context, index) {
                  final message = socketService.messages[index];
                  return ListTile(
                    title: Text(message['content']),
                    subtitle: Text('Enviado por: ${message['sender']}'),
                  );
                },
              );
            }),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Enter a message',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    final message = _controller.text;
                    if (message.isNotEmpty) {
                      socketService.sendMessage(message, _currentUser);
                      _controller.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
