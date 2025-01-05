import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';

class ConversationScreen extends StatefulWidget {
  final String conversationId; // ID de la conversación (usuario o grupo)
  final bool isGroup; // Define si la conversación es grupal

  ConversationScreen({required this.conversationId, required this.isGroup});

  @override
  _ConversationScreenState createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final ChatService chatService = ChatService();
  final TextEditingController messageController = TextEditingController();
  List<MessageModel> messages = []; // Lista de mensajes cargados
  bool isLoading = true; // Para controlar el estado de carga

  @override
  void initState() {
    super.initState();
    loadMessages();
  }

  Future<void> loadMessages() async {
    try {
      final loadedMessages = await chatService.getMessages(
        widget.conversationId,
        isGroup: widget.isGroup,
      );
      setState(() {
        messages = loadedMessages;
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar los mensajes: $error')),
      );
    }
  }

  Future<void> sendMessage() async {
    if (messageController.text.trim().isEmpty) return;

    final senderId =
        'currentUserId'; // Reemplaza con el ID real del usuario logueado

    try {
      await chatService.sendMessage(
        senderId,
        widget.isGroup
            ? null
            : widget.conversationId, // receiverId solo para individuales
        widget.isGroup
            ? widget.conversationId
            : null, // groupId solo para grupales
        messageController.text.trim(),
      );

      // Limpiar el campo de texto
      messageController.clear();

      // Agregar mensaje a la lista y recargar la UI
      setState(() {
        messages.add(MessageModel(
          senderId: senderId,
          receiverId: widget.isGroup ? '' : widget.conversationId,
          groupId: widget.isGroup ? widget.conversationId : '',
          content: messageController.text.trim(),
          timestamp: DateTime.now(),
        ));
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar el mensaje: $error')),
      );
    }
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
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : messages.isEmpty
                    ? Center(child: Text('No hay mensajes aún'))
                    : ListView.builder(
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
                              margin: EdgeInsets.symmetric(
                                  vertical: 5, horizontal: 10),
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isCurrentUser
                                    ? Colors.blue
                                    : Colors.grey[300],
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
