/*import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';

class ConversationScreen extends StatefulWidget {
  final String conversationId; // ID de la conversación (puede ser usuario o grupo)
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
    messages = chatService.getMessages(widget.conversationId, isGroup: widget.isGroup);
  }

  void sendMessage() async {
    // Validar que no se envíen mensajes vacíos
    if (messageController.text.trim().isEmpty) return;

    // Simulación del ID del usuario logueado
    final senderId = 'currentUserId'; // Reemplaza esto por el ID real del usuario logueado

    // Enviar mensaje
    await chatService.sendMessage(
      senderId,
      widget.isGroup ? null : widget.conversationId, // receiverId solo para individuales
      widget.isGroup ? widget.conversationId : null, // groupId solo para grupales
      messageController.text,
    );

    // Limpiar el campo de texto
    messageController.clear();

    // Recargar los mensajes
    setState(() {
      messages = chatService.getMessages(widget.conversationId, isGroup: widget.isGroup);
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
                      final isCurrentUser = message.senderId == 'currentUserId'; // Simulación
                      return Align(
                        alignment: isCurrentUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isCurrentUser ? Colors.blue : Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isCurrentUser)
                                Text(
                                  'De: ${message.senderId}',
                                  style: TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                              Text(
                                message.content,
                                style: TextStyle(fontSize: 16),
                              ),
                              SizedBox(height: 5),
                              Text(
                                message.timestamp.toString(),
                                style: TextStyle(fontSize: 12, color: Colors.black54),
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
///06/01/2024
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
  List<MessageModel> messages = []; // Lista de mensajes cargados

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final fetchedMessages = await chatService.getMessages(
        widget.conversationId,
        isGroup: widget.isGroup,
      );
      setState(() {
        messages = fetchedMessages;
      });
    } catch (e) {
      print('Error al cargar los mensajes: $e');
    }
  }

  void sendMessage() async {
    // Validar que no se envíen mensajes vacíos
    if (messageController.text.trim().isEmpty) return;

    try {
      // Obtén el ID del usuario logueado desde ChatService
      final senderId = await chatService.getCurrentUserId();
      if (senderId == null) {
        print('Usuario no logueado. No se puede enviar el mensaje.');
        return;
      }

      // Envía el mensaje
      await chatService.sendMessage(
        messageController.text, // Contenido del mensaje
        widget.isGroup
            ? null
            : widget.conversationId, // receiverId solo para individuales
        widget.isGroup
            ? widget.conversationId
            : null, // groupId solo para grupales
      );

      // Limpiar el campo de texto
      messageController.clear();

      // Recargar los mensajes
      _loadMessages();
    } catch (e) {
      print('Error al enviar mensaje: $e');
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
            child: ListView.builder(
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
                    margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isCurrentUser ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isCurrentUser)
                          Text(
                            'De: ${message.senderId}',
                            style:
                                TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        Text(
                          message.content,
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 5),
                        Text(
                          message.timestamp.toString(),
                          style: TextStyle(fontSize: 12, color: Colors.black54),
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
*/

/*

//06/01
import 'package:flutter/material.dart';
import '../services/websocket_service.dart';
import '../models/message_model.dart';

class ConversationScreen extends StatefulWidget {
  final String
      conversationId; // ID de la conversación (puede ser usuario o grupo)
  final bool isGroup; // Define si la conversación es grupal

  ConversationScreen({required this.conversationId, required this.isGroup});

  @override
  _ConversationScreenState createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  late WebSocketService webSocketService;
  final TextEditingController messageController = TextEditingController();
  List<MessageModel> messages = [];

  @override
  void initState() {
    super.initState();

    // Inicializar conexión WebSocket
    webSocketService = WebSocketService('ws://localhost:8080');

    // Escuchar mensajes en tiempo real
    webSocketService.messages.listen((data) {
      setState(() {
        messages.add(MessageModel.fromJson(data));
      });
    });

    // Notificar al backend que el usuario está conectado
    webSocketService.notifyStatus('online');
  }

  void sendMessage() async {
    if (messageController.text.trim().isEmpty) return;

    final String? userId = await webSocketService.getUserId();
    if (userId == null) {
      print('Usuario no logueado. No se puede enviar el mensaje.');
      return;
    }

    // Enviar mensaje
    webSocketService.sendMessage({
      'type': 'message',
      'senderId': userId,
      'receiverId': widget.isGroup ? null : widget.conversationId,
      'groupId': widget.isGroup ? widget.conversationId : null,
      'content': messageController.text,
    });

    // Limpiar el campo de texto
    messageController.clear();
  }

  @override
  void dispose() {
    // Notificar que el usuario está desconectado
    webSocketService.notifyStatus('offline');
    webSocketService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isGroup ? 'Chat del Grupo' : 'Chat Individual'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isCurrentUser =
                    message.senderId == 'userId'; // Simulación

                return Align(
                  alignment: isCurrentUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isCurrentUser ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isCurrentUser)
                          Text(
                            'De: ${message.senderId}',
                            style:
                                TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        Text(
                          message.content,
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 5),
                        Text(
                          message.timestamp.toString(),
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
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

*/

import 'package:flutter/material.dart';
import '../services/websocket_service.dart';
import '../models/message_model.dart';

class ConversationScreen extends StatefulWidget {
  final String conversationId;
  final bool isGroup;

  ConversationScreen({required this.conversationId, required this.isGroup});

  @override
  _ConversationScreenState createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  late WebSocketService webSocketService;
  final TextEditingController messageController = TextEditingController();
  List<MessageModel> messages = [];

  @override
  void initState() {
    super.initState();

    webSocketService = WebSocketService('ws://localhost:8080');

    webSocketService.messages.listen((data) {
      setState(() {
        messages.add(MessageModel.fromJson(data));
      });
    });

    webSocketService.notifyStatus('online');
  }

  void sendMessage() async {
    if (messageController.text.trim().isEmpty) return;

    final String? userId = await webSocketService.getUserId();
    if (userId == null) {
      print('Usuario no logueado.');
      return;
    }

    webSocketService.sendMessage({
      'type': 'message',
      'senderId': userId,
      'receiverId': widget.isGroup ? null : widget.conversationId,
      'groupId': widget.isGroup ? widget.conversationId : null,
      'content': messageController.text,
    });

    messageController.clear();
  }

  @override
  void dispose() {
    webSocketService.notifyStatus('offline');
    webSocketService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isGroup ? 'Grupo' : 'Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isCurrentUser = message.senderId == 'userId';

                return Align(
                  alignment: isCurrentUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.all(8),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isCurrentUser ? Colors.blue : Colors.grey,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(message.content),
                  ),
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: messageController,
                  decoration:
                      InputDecoration(hintText: 'Escribe un mensaje...'),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send),
                onPressed: sendMessage,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
