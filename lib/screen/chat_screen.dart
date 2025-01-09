//pantalla principal de chat (lista de usuarios conectados)

/*
import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import 'conversation_screen.dart';
import '../services/websocket_service.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService chatService = ChatService();
  late Future<List<dynamic>> onlineUsers;
  late Future<List<dynamic>> groups;

  @override
  void initState() {
    super.initState();
    onlineUsers = chatService.getOnlineUsers();
    groups = chatService.getGroups();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: onlineUsers,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No hay usuarios conectados'));
                } else {
                  final users = snapshot.data!;
                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return ListTile(
                        title: Text(user['name'] ?? 'Nombre no disponible'),
                        subtitle:
                            Text('Estado: ${user['status'] ?? 'Offline'}'),
                        leading: CircleAvatar(
                          child: Text(user['name']?[0] ?? '?'),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ConversationScreen(
                                conversationId: user['username'],
                                isGroup: false,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                }
              },
            ),
          ),
          Divider(),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: groups,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No hay grupos disponibles'));
                } else {
                  final groups = snapshot.data!;
                  return ListView.builder(
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      final group = groups[index];
                      return ListTile(
                        title: Text(group['name'] ?? 'Nombre no disponible'),
                        subtitle: Text('Grupo'),
                        leading: Icon(Icons.group),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ConversationScreen(
                                conversationId: group['username'],
                                isGroup: true,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
*/

/*
import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../services/websocket_service.dart';
import 'conversation_screen.dart';
import '../models/user.dart'; // Asegúrate de que este modelo esté correctamente implementado.

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService chatService = ChatService();
  late Future<List<UserModel>> onlineUsers;
  late Future<List<UserModel>> groups;

  @override
  void initState() {
    super.initState();
    // Carga inicial de usuarios y grupos
    onlineUsers = chatService.getOnlineUsers();
    groups = chatService.getGroups(); // Asegúrate de que `getGroups()` esté implementado.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<UserModel>>(
              future: onlineUsers,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No hay usuarios conectados'));
                } else {
                  final users = snapshot.data!;
                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return ListTile(
                        title: Text(user.name),
                        subtitle: Text(user.status == 'online'
                            ? 'Conectado'
                            : 'Desconectado'),
                        leading: CircleAvatar(
                          child: Text(user.name[0].toUpperCase()),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ConversationScreen(
                                conversationId: user.username,
                                isGroup: false,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                }
              },
            ),
          ),
          Divider(),
          Expanded(
            child: FutureBuilder<List<UserModel>>(
              future: groups,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No hay grupos disponibles'));
                } else {
                  final groupList = snapshot.data!;
                  return ListView.builder(
                    itemCount: groupList.length,
                    itemBuilder: (context, index) {
                      final group = groupList[index];
                      return ListTile(
                        title: Text(group.name),
                        subtitle: Text('Grupo'),
                        leading: Icon(Icons.group),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ConversationScreen(
                                conversationId: group.username,
                                isGroup: true,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

*/
import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import 'conversation_screen.dart';
import '../models/user.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService chatService = ChatService();
  late Future<List<UserModel>> onlineUsers;
  late Future<List<UserModel>> groups;

  @override
  void initState() {
    super.initState();
    onlineUsers = chatService.getOnlineUsers();
    groups = chatService.getGroups();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<UserModel>>(
              future: onlineUsers,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No hay usuarios conectados'));
                } else {
                  final users = snapshot.data!;
                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return ListTile(
                        title: Text(user.name),
                        subtitle: Text(user.status == 'online'
                            ? 'Conectado'
                            : 'Desconectado'),
                        leading: CircleAvatar(
                          child: Text(user.name[0].toUpperCase()),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ConversationScreen(
                                conversationId: user.username,
                                isGroup: false,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                }
              },
            ),
          ),
          Divider(),
          Expanded(
            child: FutureBuilder<List<UserModel>>(
              future: groups,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No hay grupos disponibles'));
                } else {
                  final groupList = snapshot.data!;
                  return ListView.builder(
                    itemCount: groupList.length,
                    itemBuilder: (context, index) {
                      final group = groupList[index];
                      return ListTile(
                        title: Text(group.name),
                        subtitle: Text('Grupo'),
                        leading: Icon(Icons.group),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ConversationScreen(
                                conversationId: group.username,
                                isGroup: true,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
