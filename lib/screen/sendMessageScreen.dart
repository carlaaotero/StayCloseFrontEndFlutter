import 'dart:async'; // Importar dart:async para StreamSubscription
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/messageService.dart';
import '../services/userServices.dart'; // Importar UserService
import '../controllers/userController.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:geolocator/geolocator.dart'; // Importar Geolocator
import 'package:url_launcher/url_launcher.dart'; // Importar URL Launcher
import '../controllers/ubiController.dart'; // Importar UbiController
import 'package:flutter_map/flutter_map.dart'; // Importar Flutter Map
import 'package:latlong2/latlong.dart'; // Importar LatLong

class SendMessageScreen extends StatefulWidget {
  final String receiverUsername;
  final String chatId;

  SendMessageScreen({
    required this.receiverUsername,
    required this.chatId,
  });

  @override
  _SendMessageScreenState createState() => _SendMessageScreenState();
}

class _SendMessageScreenState extends State<SendMessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  late IO.Socket _socket;
  final UserService _userService = UserService(); // Instanciar UserService
  final UbiController _ubiController =
      UbiController(); // Instanciar UbiController
  StreamSubscription<Position>?
      _positionStreamSubscription; // Subscription para el stream de ubicación
  final ScrollController _scrollController = ScrollController();

  late MapController _mapController;
  LatLng _currentLocation = LatLng(0.0, 0.0);

  bool _isLocationSharing = false;

  @override
  void initState() {
    super.initState();
    _connectToSocket();
    _loadMessages();
    _mapController = MapController();
    _startLocationUpdates();
    
  }

  @override
  void dispose() {
    _socket.disconnect();
    _positionStreamSubscription
        ?.cancel(); // Cancelar la suscripción al stream de ubicación
    _scrollController.dispose(); // Liberar el controlador de scroll
    super.dispose();
  }

  Future<void> _connectToSocket() async {
    _socket = IO.io(
      'http://127.0.0.1:3000',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket.connect();
    _socket.emit('joinChat', widget.chatId);
    /*

    _socket.on('newMessage', (data) {
      setState(() {
        _messages.add(data);
      });
      
    });
    */
    _socket.on('newMessage', (data) {
      final currentUser = Get.find<UserController>().currentUserName.value;
      // Verificar que el mensaje no esté duplicado
      if (_messages.any((msg) => msg['_id'] == data['_id'])) return;
      // Agregar el mensaje solo si pertenece al chat actual
      if (data['chat'] == widget.chatId) {
        setState(() {
          _messages.add(data);
        });

        // Desplazar automáticamente al final
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      }
    });

    _socket.onConnect((_) => print('Conectado al servidor de WebSocket'));
    _socket
        .onDisconnect((_) => print('Desconectado del servidor de WebSocket'));
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await MessageService.getMessages(widget.chatId);
      setState(() {
        _messages.clear();
        _messages.addAll(messages);
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
    } catch (e) {
      print('Error al cargar mensajes: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      final Map<String, String> newMessage = {
        'sender': Get.find<UserController>().currentUserName.value,
        'receiver': widget.receiverUsername,
        'content': _messageController.text,
        'timestamp': DateTime.now().toIso8601String(),
      };

      setState(() {
        _messages.add(newMessage); // Agregar mensaje localmente
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });

      try {
        // Enviar el mensaje al backend
        await MessageService.sendMessage(
          chatId: widget.chatId,
          senderUsername: newMessage['sender']!,
          receiverUsername: newMessage['receiver']!,
          content: newMessage['content']!,
        );
      } catch (e) {
        Get.snackbar("Error", "No se pudo enviar el mensaje");
      }

      _messageController.clear(); // Limpiar el campo de texto
    }
  }

  Future<void> _sendHomeStatus() async {
    try {
      String currentUsername = Get.find<UserController>().currentUserName.value;
      String? homeAddress = await _userService.getHomeUser(currentUsername);

      if (homeAddress != null) {
        // Obtener coordenadas de la dirección de casa
        Map<String, double> homeCoordinates =
            await _ubiController.getCoordinatesFromAddress(homeAddress);

        // Enviar mensaje "Me dirijo a casa"
        await MessageService.sendMessage(
          chatId: widget.chatId,
          senderUsername: currentUsername,
          receiverUsername: widget.receiverUsername,
          content: 'Me dirijo a casa',
        );

        // Comprobar la ubicación continuamente
        _positionStreamSubscription = Geolocator.getPositionStream(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((Position position) async {
          double distanceInMeters = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            homeCoordinates['latitude']!,
            homeCoordinates['longitude']!,
          );

          if (distanceInMeters < 100) {
            // Enviar mensaje "Ya estoy en casa" cuando se detecta que el usuario ha llegado a casa
            await MessageService.sendMessage(
              chatId: widget.chatId,
              senderUsername: currentUsername,
              receiverUsername: widget.receiverUsername,
              content: 'Ya estoy en casa',
            );

            // Cancelar la suscripción al stream de ubicación
            _positionStreamSubscription?.cancel();
          }
        });
      } else {
        Get.snackbar('Error', 'No se pudo obtener la dirección de casa');
      }
    } catch (e) {
      print('Error al obtener la dirección de casa: $e');
      Get.snackbar('Error', 'No se pudo obtener la dirección de casa');
    }
  }

  // Método para abrir el enlace de Google Maps
  Future<void> _openMap(String url) async {
    if (await canLaunch(url)) {
      await launch(url); // Abrir el enlace en Google Maps
    } else {
      Get.snackbar("Error", "No se pudo abrir el enlace");
    }
  }

  //FUNCIONS UBICACIÓ

  // Funció per actualitzar la ubicació en temps real
  void _startLocationUpdates() {
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter:
            10, // Actualitzar només si la ubicació canvia més de 10 metres
      ),
    ).listen((Position position) async {
      /*// Crear l'enllaç de OpenStreetMap amb la nova ubicació
    String locationLink = 'https://www.openstreetmap.org/?mlat=${position.latitude}&mlon=${position.longitude}#map=15/${position.latitude}/${position.longitude}';

    // Enviar el missatge amb l'enllaç de la nova ubicació
    await MessageService.sendMessage(
      chatId: widget.chatId,
      senderUsername: Get.find<UserController>().currentUserName.value,
      receiverUsername: widget.receiverUsername,
      content: '¡Estoy Aquí! <a href="$locationLink">¡Mira el mapa!</a>',
    );

    print('Ubicación actualizada enviada: $locationLink');*/

      // Actualitzar la ubicació cada vegada que canviï
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

      // Actualitzar la vista del mapa per centrar-se en la nova ubicació
      _mapController.move(
          _currentLocation, 15); // Moure el mapa a la nova ubicació

          // Enviar la ubicació al servidor a través de Socket.io
    _socket.emit('sendLocation', {
      'chatId': widget.chatId,
      'username': Get.find<UserController>().currentUserName.value,
      'latitude': position.latitude,
      'longitude': position.longitude,
    });

      print(
          'Ubicación actualizada: ${_currentLocation.latitude}, ${_currentLocation.longitude}');
    });
  }

  /*//funcions per si ho volem amb timer
  Timer? _locationUpdateTimer;

void _startLocationUpdates() {
  _locationUpdateTimer = Timer.periodic(Duration(seconds: 5), (_) {
    _sendLocation();  // Enviar actualitzacions de la ubicació cada 5 segons
  });
}

void _stopLocationUpdates() {
  _locationUpdateTimer?.cancel();  // Aturar les actualitzacions de la ubicació
}
*/

  // Enviar la ubicació com a missatge de text amb GoogleMaps
  Future<void> _sendLocationGoogle() async {
    try {
      // Obtener la ubicación actual
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // Crear el enlace de Google Maps
      String locationLink =
          'https://www.google.com/maps?q=${position.latitude},${position.longitude}';

      // Enviar el mensaje con el texto "¡Estoy Aquí!" y el enlace de ubicación
      await MessageService.sendMessage(
        chatId: widget.chatId,
        senderUsername: Get.find<UserController>().currentUserName.value,
        receiverUsername: widget.receiverUsername,
        content:
            '¡Estoy Aquí! <a href="$locationLink">¡Estoy Aquí!</a>', // Mensaje con el enlace
      );

      print('Ubicación enviada: $locationLink');
    } catch (e) {
      print('Error al obtener la ubicación: $e');
      Get.snackbar('Error', 'No se pudo obtener la ubicación');
    }
  }

  // Enviar la ubicació com a missatge de text amb OpenStreetMap
  Future<void> _sendLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // Crear el link d'OpenStreetMap
      String locationLink =
          'https://www.openstreetmap.org/?mlat=${position.latitude}&mlon=${position.longitude}#map=15/${position.latitude}/${position.longitude}';

      await MessageService.sendMessage(
        chatId: widget.chatId,
        senderUsername: Get.find<UserController>().currentUserName.value,
        receiverUsername: widget.receiverUsername,
        content: '¡Estoy Aquí! <a href="$locationLink">¡Mira el mapa!</a>',
      );

      print('Ubicación enviada: $locationLink');

      // Activar la visualització del mapa
      setState(() {
        _isLocationSharing = true;
      });
    } catch (e) {
      print('Error al obtener la ubicación: $e');
      Get.snackbar('Error', 'No se pudo obtener la ubicación');
    }
  }

  // Construir el mapa con FlutterMap
  Widget _buildMap() {
    return Container(
      height: 150, // Alçada del mapa
      width: 150, 
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          center: _currentLocation, // Estableix la ubicació inicial
          zoom: 15,
        ),
        children: [
          TileLayer(
            urlTemplate:
                "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", // URL d'OpenStreetMap
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayer(
            markers: [
              Marker(
                width: 40.0,
                height: 40.0,
                point: _currentLocation,
                builder: (ctx) => Container(
                  child: Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 30.0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat con ${widget.receiverUsername}'),
        backgroundColor: Color(0xFF89AFAF),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
                controller:
                    _scrollController, // Asigna el ScrollController aquí
                itemCount: _messages.length,
                /*itemBuilder: (context, index) {
                final message = _messages[index];
                final isSender = message['sender'] ==
                    Get.find<UserController>().currentUserName.value;
                return Align(
                  alignment:
                      isSender ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.all(8.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color:
                          isSender ? Color(0xFF89AFAF) : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: message['content'].contains('<a href="')
                        ? GestureDetector(
                        onTap: () => _openMap(message['content'].substring(
                                message['content'].indexOf('"') + 1,
                                message['content'].lastIndexOf('"'))),
                            child: Text(
                              '¡Estoy Aquí!',
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          )
                        : Text(
                            message['content'],
                            style: TextStyle(color: Colors.black87),
                          ),
                  ),
                );
              },*/
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isSender = message['sender'] ==
                      Get.find<UserController>().currentUserName.value;

                  // Si el missatge és un enllaç de la ubicació, mostrar el mapa
                  if (message['content'].contains('<a href="')) {
                    String url = message['content'].substring(
                      message['content'].indexOf('"') + 1,
                      message['content'].lastIndexOf('"'),
                    );
                    return Align(
                      alignment: isSender
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => _openMap(url),
                        child: Container(
                          margin: const EdgeInsets.all(8.0),
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: isSender
                                ? Color(0xFF89AFAF)
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            '¡Estic Aquí!',
                            style: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  // Si s'està compartint la ubicació, mostrar el mapa
                  if (_isLocationSharing) {
                    return Align(
                      alignment: isSender
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.all(8.0),
                        child: _buildMap(), // Aquí es mostra el mapa
                      ),
                    );
                  }

                  return Align(
                    alignment:
                        isSender ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.all(8.0),
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color:
                            isSender ? Color(0xFF89AFAF) : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        message['content'],
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                  );
                }),
          ),
          _buildMessageInputBar(context),
        ],
      ),
    );
  }

  Widget _buildMessageInputBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: Color(0xFF89AFAF)),
            onPressed: () {
              _showAttachmentMenu(context);
            },
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Escribe un mensaje...',
                border: InputBorder.none,
              ),
              onSubmitted: (value) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: Color(0xFF89AFAF)),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  void _showAttachmentMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              _buildAttachmentOption(
                context,
                icon: Icons.location_on,
                label: 'Localización',
                onTap: () {
                  Navigator.pop(context);
                  _sendLocation();
                  setState(() {
                    _isLocationSharing =
                        true; // Activar l'opció de compartir ubicació
                  });
                },
              ),
              _buildAttachmentOption(
                context,
                icon: Icons.home,
                label: 'En Casa',
                onTap: () {
                  Navigator.pop(context);
                  _sendHomeStatus();
                },
              ),
              _buildAttachmentOption(
                context,
                icon: Icons.map,
                label: 'Compartir Google',
                onTap: () {
                  Navigator.pop(context);
                  _sendLocationGoogle();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Color(0xFF89AFAF).withOpacity(0.2),
            child: Icon(icon, color: Color(0xFF89AFAF), size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(color: Color(0xFF89AFAF), fontSize: 14),
          ),
        ],
      ),
    );
  }
}
