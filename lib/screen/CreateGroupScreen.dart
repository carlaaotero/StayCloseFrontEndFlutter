import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/userController.dart';
import '../controllers/chatController.dart';
import '../models/user.dart';

class CreateGroupScreen extends StatefulWidget {
  @override
  _CreateGroupScreenState createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final UserController _userController = Get.find<UserController>();
  final ChatController _chatController = Get.find<ChatController>();
  final List<UserModel> _selectedUsers = []; // Lista de usuarios seleccionados

  @override
  void initState() {
    super.initState();
    _userController.fetchUsers(); // Cargar todos los usuarios al inicio
  }

  void _createGroup() async {
    if (_groupNameController.text.isNotEmpty && _selectedUsers.isNotEmpty) {
      final participantIds =
          _selectedUsers.map((user) => user.username).toList();
      await _chatController.createGroup(
        groupName: _groupNameController.text,
        participants: participantIds,
      );
      Navigator.pop(context); // Regresar a la lista de chats
    } else {
      Get.snackbar(
        "Error",
        "El nombre del grupo y los participantes son obligatorios.",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crear Grupo"),
      ),
      body: Column(
        children: [
          // Campo para el nombre del grupo
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _groupNameController,
              decoration: const InputDecoration(
                labelText: "Nombre del grupo",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar usuario...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  _userController.searchUser(value); // Buscar usuario
                } else {
                  _userController
                      .fetchUsers(); // Mostrar todos los usuarios si se limpia la búsqueda
                }
              },
            ),
          ),
          // Lista de usuarios seleccionados
          if (_selectedUsers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedUsers.map((user) {
                  return Chip(
                    label: Text(user.username),
                    deleteIcon: const Icon(Icons.close),
                    onDeleted: () {
                      setState(() {
                        _selectedUsers
                            .remove(user); // Eliminar usuario seleccionado
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          // Lista de usuarios (búsqueda o lista completa)
          Expanded(
            child: Obx(() {
              // Mostrar indicador de carga mientras se obtienen los datos
              if (_userController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              // Determinar qué lista mostrar: resultados de búsqueda o todos los usuarios
              final usersToDisplay = _searchController.text.isNotEmpty
                  ? _userController.searchResults
                  : _userController.users;

              // Si no hay usuarios, mostrar un mensaje
              if (usersToDisplay.isEmpty) {
                return const Center(child: Text("No se encontraron usuarios."));
              }

              // Mostrar la lista de usuarios o resultados de búsqueda
              return ListView.builder(
                itemCount: usersToDisplay.length,
                itemBuilder: (context, index) {
                  final user = usersToDisplay[index];
                  final isSelected = _selectedUsers.contains(user);

                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(user.username[0].toUpperCase()),
                    ),
                    title: Text(user.username),
                    subtitle: Text(user.email),
                    trailing: Checkbox(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            // Evitar duplicados en la selección
                            if (!_selectedUsers.contains(user)) {
                              _selectedUsers.add(user);
                              _searchController
                                  .clear(); // Limpiar el campo de búsqueda
                              _userController
                                  .fetchUsers(); // Mostrar todos los usuarios
                            }
                          } else {
                            _selectedUsers.remove(user);
                          }
                        });
                      },
                    ),
                  );
                },
              );
            }),
          ),
          // Botón para crear el grupo
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _createGroup,
              child: const Text("Crear Grupo"),
            ),
          ),
        ],
      ),
    );
  }
}
