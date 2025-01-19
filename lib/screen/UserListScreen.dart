import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/userController.dart';
import '../controllers/chatController.dart';
import 'sendMessageScreen.dart';
import 'CreateGroupScreen.dart';

class UserListScreen extends StatelessWidget {
  final UserController _userController = Get.put(UserController());
  final ChatController _chatController = Get.put(ChatController());
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Cargar los chats existentes al iniciar
    _chatController.fetchUserChats(_userController.currentUserName.value);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add),
            onPressed: () {
              // Navegar a la pantalla para crear un grupo
              Get.to(() => CreateGroupScreen());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por username...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _userController.searchUser(value);
                }
              },
            ),
          ),
          // Lista de chats existentes
          Obx(() {
            if (_chatController.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            } else if (_chatController.userChats.isNotEmpty) {
              return Expanded(
                child: ListView.builder(
                  itemCount: _chatController.userChats.length,
                  itemBuilder: (context, index) {
                    final chat = _chatController.userChats[index];
                    final isGroupChat = chat.isGroupChat ?? false;

                    final title = isGroupChat
                        ? chat.groupName ?? "Grupo"
                        : chat.participants.firstWhere(
                            (participant) =>
                                participant !=
                                _userController.currentUserName.value,
                            orElse: () => 'Desconocido',
                          );

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          title[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor:
                            isGroupChat ? Colors.blue : Colors.green,
                      ),
                      title: Text(title),
                      subtitle: isGroupChat
                          ? const Text("Chat grupal")
                          : const Text("Chat individual"),
                      onTap: () {
                        if (chat.id.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SendMessageScreen(
                                chatId: chat.id,
                                receiverUsername: title,
                                isGroupChat: isGroupChat,
                              ),
                            ),
                          );
                        } else {
                          Get.snackbar(
                            "Error",
                            "El chat no tiene un ID válido",
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        }
                      },
                    );
                  },
                ),
              );
            } else {
              return const Center(child: Text('No tienes chats activos.'));
            }
          }),
          // Resultados de búsqueda
          Obx(() {
            if (_userController.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            } else if (_userController.searchResults.isNotEmpty) {
              return Expanded(
                child: ListView.builder(
                  itemCount: _userController.searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _userController.searchResults[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(user.username[0].toUpperCase()),
                      ),
                      title: Text(user.username),
                      subtitle: Text(user.email),
                      onTap: () async {
                        final sender = _userController.currentUserName.value;
                        final receiver = user.username;

                        try {
                          await _chatController.getOrCreateChat(
                            sender: sender,
                            receiver: receiver,
                          );

                          if (_chatController.chatId.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SendMessageScreen(
                                  receiverUsername: receiver,
                                  chatId: _chatController.chatId.value,
                                  isGroupChat: false,
                                ),
                              ),
                            );
                          } else {
                            Get.snackbar(
                              "Error",
                              "No se pudo iniciar el chat",
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          }
                        } catch (e) {
                          Get.snackbar(
                            "Error",
                            "No se pudo iniciar el chat",
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        }
                      },
                    );
                  },
                ),
              );
            } else if (_searchController.text.isNotEmpty) {
              return const Center(child: Text('No se encontraron usuarios.'));
            } else {
              return Container();
            }
          }),
        ],
      ),
    );
  }
}





/*import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/userController.dart';
import '../controllers/chatController.dart';
import 'sendMessageScreen.dart';
import 'CreateGroupScreen.dart';

class UserListScreen extends StatelessWidget {
  final UserController _userController = Get.put(UserController());
  final ChatController _chatController = Get.put(ChatController());
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Cargar los chats existentes al iniciar
    _chatController.fetchUserChats(_userController.currentUserName.value);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add),
            onPressed: () {
              // Navegar a la pantalla para crear un grupo
              //Navigator.pushNamed(context, '/createGroup');
              Get.to(() => CreateGroupScreen());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por username...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _userController.searchUser(value);
                }
              },
            ),
          ),
          // Lista de chats existentes
          Obx(() {
            if (_chatController.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            } else if (_chatController.userChats.isNotEmpty) {
              return Expanded(
                child: ListView.builder(
                  itemCount: _chatController.userChats.length,
                  itemBuilder: (context, index) {
                    final chat = _chatController.userChats[index];
                    final isGroupChat = chat.participants.length > 2;

                    final title = isGroupChat
                        ? "Grupo"
                        : chat.participants.firstWhere(
                            (participant) =>
                                participant !=
                                _userController.currentUserName.value,
                            orElse: () => 'Desconocido',
                          );

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          title[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor:
                            isGroupChat ? Colors.blue : Colors.green,
                      ),
                      title: Text(title),
                      subtitle: isGroupChat
                          ? const Text("Chat grupal")
                          : const Text("Chat individual"),
                      onTap: () {
                        if (chat.id.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SendMessageScreen(
                                chatId: chat.id,
                                receiverUsername: title,
                                isGroupChat: isGroupChat,
                              ),
                            ),
                          );
                        } else {
                          Get.snackbar(
                            "Error",
                            "El chat no tiene un ID válido",
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        }
                      },
                    );
                  },
                ),
              );
            } else {
              return const Center(child: Text('No tienes chats activos.'));
            }
          }),
          // Resultados de búsqueda
          Obx(() {
            if (_userController.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            } else if (_userController.searchResults.isNotEmpty) {
              return Expanded(
                child: ListView.builder(
                  itemCount: _userController.searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _userController.searchResults[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(user.username[0].toUpperCase()),
                      ),
                      title: Text(user.username),
                      subtitle: Text(user.email),
                      onTap: () async {
                        final sender = _userController.currentUserName.value;
                        final receiver = user.username;

                        try {
                          await _chatController.getOrCreateChat(
                            sender: sender,
                            receiver: receiver,
                          );

                          if (_chatController.chatId.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SendMessageScreen(
                                  receiverUsername: receiver,
                                  chatId: _chatController.chatId.value,
                                  isGroupChat: false,
                                ),
                              ),
                            );
                          } else {
                            Get.snackbar(
                              "Error",
                              "No se pudo iniciar el chat",
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          }
                        } catch (e) {
                          Get.snackbar(
                            "Error",
                            "No se pudo iniciar el chat",
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        }
                      },
                    );
                  },
                ),
              );
            } else if (_searchController.text.isNotEmpty) {
              return const Center(child: Text('No se encontraron usuarios.'));
            } else {
              return Container();
            }
          }),
        ],
      ),
    );
  }
}


*/

/*import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/userController.dart';
import '../controllers/chatController.dart';
import 'sendMessageScreen.dart';

class UserListScreen extends StatelessWidget {
  final UserController _userController =
      Get.put(UserController()); // Instancia del controlador de usuarios
  final ChatController _chatController =
      Get.put(ChatController()); // Instancia del controlador de chat
  final TextEditingController _searchController =
      TextEditingController(); // Controlador del campo de búsqueda

  @override
  Widget build(BuildContext context) {
    // Cargar los chats existentes al iniciar
    _chatController.fetchUserChats(_userController.currentUserName.value);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add),
            onPressed: () {
              // Navegar a la pantalla para crear un grupo
              Navigator.pushNamed(context, '/createGroup');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por username...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _userController
                      .searchUser(value); // Llama al método para buscar usuario
                }
              },
            ),
          ),
          // Lista de chats existentes
          Obx(() {
            if (_chatController.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            } else if (_chatController.userChats.isNotEmpty) {
              return Expanded(
                child: ListView.builder(
                  itemCount: _chatController.userChats.length,
                  itemBuilder: (context, index) {
                    final chat = _chatController.userChats[index];
                    final isGroupChat = chat.participants.length > 2;

                    // Título para el chat: nombre del grupo o usuario
                    final title = isGroupChat
                        ? "Grupo"
                        : chat.participants.firstWhere(
                            (participant) =>
                                participant !=
                                _userController.currentUserName.value,
                                orElse: () => 'Desconocido',
                          );

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          title[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor:
                            isGroupChat ? Colors.blue : Colors.green,
                      ),
                      title: Text(title),
                      subtitle: isGroupChat
                          ? const Text("Chat grupal")
                          : const Text("Chat individual"),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SendMessageScreen(
                              chatId: chat.id,
                              receiverUsername: title,
                              isGroupChat: isGroupChat,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            } else {
              return const Center(child: Text('No tienes chats activos.'));
            }
          }),
          // Resultados de búsqueda
          Obx(() {
            if (_userController.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            } else if (_userController.searchResults.isNotEmpty) {
              return Expanded(
                child: ListView.builder(
                  itemCount: _userController.searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _userController.searchResults[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(user.username[0].toUpperCase()),
                      ),
                      title: Text(user.username),
                      subtitle: Text(user.email),
                      onTap: () async {
                        final sender = _userController.currentUserName.value;
                        final receiver = user.username;

                        try {
                          // Inicia la creación o búsqueda del chat
                          await _chatController.getOrCreateChat(
                            sender: sender,
                            receiver: receiver,
                          );

                          // Si se obtiene un chatId, navegar a la pantalla del chat
                          if (_chatController.chatId.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SendMessageScreen(
                                  receiverUsername: receiver,
                                  chatId: _chatController.chatId.value,
                                  isGroupChat: false, // Es un chat individual
                                ),
                              ),
                            );
                          } else {
                            Get.snackbar(
                              "Error",
                              "No se pudo iniciar el chat",
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          }
                        } catch (e) {
                          Get.snackbar(
                            "Error",
                            "No se pudo iniciar el chat",
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        }
                      },
                    );
                  },
                ),
              );
            } else if (_searchController.text.isNotEmpty) {
              return const Center(child: Text('No se encontraron usuarios.'));
            } else {
              return Container(); // Mostrar vacío si no hay búsqueda activa
            }
          }),
        ],
      ),
    );
  }
}
*/

/*
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/userController.dart';
import '../controllers/chatController.dart'; // Importar el controlador del chat
import 'sendMessageScreen.dart';
import 'CreateGroupScreen.dart';

class UserListScreen extends StatelessWidget {
  final UserController _userController =
      Get.put(UserController()); // Instancia del controlador de usuarios
  final ChatController _chatController =
      Get.put(ChatController()); // Instancia del controlador de chat
  final TextEditingController _searchController =
      TextEditingController(); // Controlador del campo de búsqueda
      
  @override
  Widget build(BuildContext context) {
    // Cargar los chats existentes al iniciar
    _chatController.fetchUserChats(_userController.currentUserName.value);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Chats'),
        actions: [
          // Botón para crear un grupo
          IconButton(
            icon: const Icon(Icons.group_add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        CreateGroupScreen()), // Ir a la pantalla de creación de grupo
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por username...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _userController.searchUser(value);
                }
              },
            ),
          ),

          // Lista de chats existentes
          Obx(() {
            if (_chatController.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            } else if (_chatController.userChats.isNotEmpty) {
              return Expanded(
                child: ListView.builder(
                  itemCount: _chatController.userChats.length,
                  itemBuilder: (context, index) {
                    final chat = _chatController.userChats[index];
                    final isGroupChat = chat.participants.length >
                        2; // Verificar si es un grupo
                    final title = isGroupChat
                        ? "Grupo"
                        : chat.participants.firstWhere(
                            (p) => p != _userController.currentUserName.value);

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(title[0].toUpperCase()),
                      ),
                      title: Text(title),
                      subtitle: Text(
                        isGroupChat ? 'Grupo' : 'Chat individual',
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SendMessageScreen(
                              chatId: chat['id'],
                              receiverUsername: title,
                              isGroupChat: isGroupChat,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            } else {
              return const Center(child: Text('No tienes chats activos.'));
            }
          }),

          // Resultados de búsqueda
          Obx(() {
            if (_userController.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            } else if (_userController.searchResults.isNotEmpty) {
              return Expanded(
                child: ListView.builder(
                  itemCount: _userController.searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _userController.searchResults[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(user.username[0].toUpperCase()),
                      ),
                      title: Text(user.username),
                      subtitle: Text(user.email),
                      onTap: () async {
                        final sender = _userController.currentUserName.value;
                        final receiver = user.username;

                        try {
                          await _chatController.getOrCreateChat(
                            sender: sender,
                            receiver: receiver,
                          );

                          if (_chatController.chatId.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SendMessageScreen(
                                  receiverUsername: receiver,
                                  chatId: _chatController.chatId.value,
                                  isGroupChat: false,
                                ),
                              ),
                            );
                          } else {
                            Get.snackbar(
                              "Error",
                              "No se pudo iniciar el chat",
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          }
                        } catch (e) {
                          Get.snackbar(
                            "Error",
                            "No se pudo iniciar el chat",
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        }
                      },
                    );
                  },
                ),
              );
            } else if (_searchController.text.isNotEmpty) {
              return const Center(child: Text('No se encontraron usuarios.'));
            } else {
              return Container();
            }
          }),
        ],
      ),
    );
  }
}

*/

/*
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/userController.dart';
import '../controllers/chatController.dart';
import 'sendMessageScreen.dart';

class UserListScreen extends StatefulWidget {
  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final UserController _userController = Get.put(UserController());
  final ChatController _chatController = Get.put(ChatController());
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _userController
        .initializeUser(); // Inicializa el usuario actual desde SharedPreferences
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Usuario'),
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por username...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _userController
                      .searchUser(value); // Llama al método para buscar usuario
                }
              },
            ),
          ),

          // Resultados de búsqueda
          Obx(() {
            if (_userController.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            } else if (_userController.searchResults.isNotEmpty) {
              return Expanded(
                child: ListView.builder(
                  itemCount: _userController.searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _userController.searchResults[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(user.username[0].toUpperCase()),
                      ),
                      title: Text(user.username),
                      subtitle: Text(user.email),
                      onTap: () async {
                        final sender = _userController.currentUserName.value;
                        final receiver = user.username;

                        try {
                          // Inicia la creación o búsqueda del chat
                          await _chatController.getOrCreateChat(
                            sender: sender,
                            receiver: receiver,
                          );

                          // Si se obtiene un chatId, navegar a la pantalla del chat
                          if (_chatController.chatId.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SendMessageScreen(
                                  receiverUsername: receiver,
                                  chatId: _chatController.chatId.value,
                                ),
                              ),
                            );
                          } else {
                            Get.snackbar(
                              "Error",
                              "No se pudo obtener el chatId",
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          }
                        } catch (e) {
                          Get.snackbar(
                            "Error",
                            "No se pudo iniciar el chat",
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        }
                      },
                    );
                  },
                ),
              );
            } else if (_searchController.text.isNotEmpty) {
              return const Center(child: Text('No se encontraron usuarios.'));
            } else {
              return Container(); // Mostrar vacío si no hay búsqueda activa
            }
          }),
        ],
      ),
    );
  }
}

*/