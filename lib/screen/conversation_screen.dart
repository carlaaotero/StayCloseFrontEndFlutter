import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';

class ConversationScreen extends StatefulWidget {
  final String
      conversationId; // ID de la conversación (puede ser usuario o grupo)
  final bool isGroup; // Define si la conversación es grupal

  ConversationScreen({required this.conversationId, required this.isGroup});

  @override
  _ConversationScreenState createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final ChatService chatService = ChatService();
  final TextEditingController messageController = TextEditingController();
  late Future<List<MessageModel>> messages; // Lista de mensajes cargados

  @override
  void initState() {
    super.initState();
    // Cargar los mensajes iniciales dependiendo si es grupo o individual
    messages =
        chatService.getMessages(widget.conversationId, isGroup: widget.isGroup);
  }

  void sendMessage() async {
    // Validar que no se envíen mensajes vacíos
    if (messageController.text.trim().isEmpty) return;

    // Simulación del ID del usuario logueado
    final senderId =
        'currentUserId'; // Reemplaza esto por el ID real del usuario logueado

    // Enviar mensaje
    await chatService.sendMessage(
      senderId,
      widget.isGroup
          ? null
          : widget.conversationId, // receiverId solo para individuales
      widget.isGroup
          ? widget.conversationId
          : null, // groupId solo para grupales
      messageController.text,
    );

    // Limpiar el campo de texto
    messageController.clear();

    // Recargar los mensajes
    setState(() {
      messages = chatService.getMessages(widget.conversationId,
          isGroup: widget.isGroup);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isGroup ? 'Chat del Grupo' : 'Chat Individual'),
      ),
      body: Column(
        children: [
          // Mensajes de la conversación
          Expanded(
            child: FutureBuilder<List<MessageModel>>(
              future: messages,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No hay mensajes aún'));
                } else {
                  final messages = snapshot.data!;
                  return ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isCurrentUser =
                          message.senderId == 'currentUserId'; // Simulación
                      return Align(
                        alignment: isCurrentUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin:
                              EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color:
                                isCurrentUser ? Colors.blue : Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isCurrentUser)
                                Text(
                                  'De: ${message.senderId}',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.black54),
                                ),
                              Text(
                                message.content,
                                style: TextStyle(fontSize: 16),
                              ),
                              SizedBox(height: 5),
                              Text(
                                message.timestamp.toString(),
                                style: TextStyle(
                                    fontSize: 12, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),

          // Campo de texto para enviar mensajes
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
