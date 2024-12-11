import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/socketService.dart';

class ChatScreen extends StatelessWidget {
  final String currentUser; // Usuario actual
  final String recipient; // Destinatario

  ChatScreen({required this.currentUser, required this.recipient});

  final TextEditingController _controller = TextEditingController();
  final socketService = Get.find<SocketService>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat con $recipient'),
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Obx(() {
              // Filtrar mensajes entre el usuario actual y el destinatario
              final relevantMessages = socketService.messages.where((msg) {
                return (msg['sender'] == currentUser &&
                        msg['recipient'] == recipient) ||
                    (msg['sender'] == recipient &&
                        msg['recipient'] == currentUser);
              }).toList();

              return ListView.builder(
                itemCount: relevantMessages.length,
                itemBuilder: (context, index) {
                  final message = relevantMessages[index];
                  final isMe = message['sender'] == currentUser;
                  return ListTile(
                    title: Text(
                      message['content'],
                      style:
                          TextStyle(color: isMe ? Colors.white : Colors.black),
                    ),
                    tileColor: isMe ? Colors.blueAccent : Colors.grey[300],
                    subtitle: Text(isMe ? 'Yo' : recipient),
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
                      hintText: 'Escribe tu mensaje...',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    final message = _controller.text.trim();
                    if (message.isNotEmpty) {
                      socketService.sendPrivateMessage(
                          message, currentUser, recipient);
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
