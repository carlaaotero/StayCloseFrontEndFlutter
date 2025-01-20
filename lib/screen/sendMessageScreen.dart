import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/messageService.dart';
import '../services/userServices.dart';
import '../controllers/userController.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../controllers/ubiController.dart';

class SendMessageScreen extends StatefulWidget {
  final String receiverUsername;
  final String chatId;
  final bool isGroupChat;

  SendMessageScreen({
    required this.receiverUsername,
    required this.chatId,
    this.isGroupChat = false,
  });

  @override
  _SendMessageScreenState createState() => _SendMessageScreenState();
}

class _SendMessageScreenState extends State<SendMessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  late IO.Socket _socket;
  StreamSubscription<Position>? _positionStreamSubscription;
  final UserService _userService = UserService(); // Instanciar UserService
  final UbiController _ubiController =
      UbiController(); // Instanciar UbiController

  @override
  void initState() {
    super.initState();
    _connectToSocket();
    _loadMessages();
  }

  @override
  void dispose() {
    _socket.disconnect();
    _positionStreamSubscription?.cancel();
    _scrollController.dispose();
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

    _socket.on('newMessage', (data) {
      if (_messages.any((msg) => msg['_id'] == data['_id'])) return;

      if (data['chat'] == widget.chatId) {
        setState(() {
          _messages.add(data);
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      }
    });

    /*  // Escoltar canvis de posició
    _positionStreamSubscription =
      Geolocator.getPositionStream(locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3, // Només actualitzar si es mou més de 10 metres
      )).listen((Position position) {
    // Enviar la ubicació al servidor
    String locationMessage =
        'location:${position.latitude},${position.longitude}';

    _socket.emit('sendLocation', {
      'chatId': widget.chatId,
      'sender': Get.find<UserController>().currentUserName.value,
      'content': locationMessage,
    });

    print('Ubicació enviada: $locationMessage');
  });*/

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
        'receiver': widget.isGroupChat ? '' : widget.receiverUsername,
        'content': _messageController.text,
        'timestamp': DateTime.now().toIso8601String(),
      };

      setState(() {
        //_messages.add(newMessage);
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });

      try {
        await MessageService.sendMessage(
          chatId: widget.chatId,
          senderUsername: newMessage['sender']!,
          receiverUsername: newMessage['receiver']!,
          content: newMessage['content']!,
        );
      } catch (e) {
        Get.snackbar("Error", "No se pudo enviar el mensaje");
      }

      _messageController.clear();
    }
  }

  Future<void> _sendLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      String locationMessage =
          'location:${position.latitude},${position.longitude}';

      await MessageService.sendMessage(
        chatId: widget.chatId,
        senderUsername: Get.find<UserController>().currentUserName.value,
        receiverUsername: widget.receiverUsername,
        content: locationMessage,
      );
      // Escoltar canvis de posició
      _positionStreamSubscription = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3, // Només actualitzar si es mou més de 10 metres
      )).listen((Position position) {
        // Enviar la ubicació al servidor
        String locationMessage =
            'location:${position.latitude},${position.longitude}';

        _socket.emit('sendLocation', {
          'chatId': widget.chatId,
          'sender': Get.find<UserController>().currentUserName.value,
          'content': locationMessage,
        });

        print('Ubicació enviada: $locationMessage');
      });
    } catch (e) {
      print('Error al obtener la ubicación: $e');
      Get.snackbar('Error', 'No se pudo obtener la ubicación');
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
        print('estas son mis coordenadas de casa: $homeCoordinates');
        // Enviar mensaje "Me dirijo a casa"
        await MessageService.sendMessage(
          chatId: widget.chatId,
          senderUsername: currentUsername,
          receiverUsername: widget.receiverUsername,
          content: 'Me dirijo a casa',
        );
        print('Comparo distancia');
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
          print('La distancia en metros es: $distanceInMeters');
          if (distanceInMeters < 200) {
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

  Widget _buildMessage(Map<String, dynamic> message, bool isSender) {
    final content = message['content'];
    if (content.startsWith('location:')) {
      final parts = content.split(':')[1].split(',');
      final latitude = double.parse(parts[0]);
      final longitude = double.parse(parts[1]);

      return Container(
        height: 190,
        width: 250,
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        child: FlutterMap(
          options: MapOptions(
            center: LatLng(latitude, longitude),
            zoom: 15.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: ['a', 'b', 'c'],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(latitude, longitude),
                  builder: (context) =>
                      Icon(Icons.location_on, color: Colors.red, size: 40),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Renderizar texto normal
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: isSender ? Color(0xFF89AFAF) : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        content,
        style: const TextStyle(color: Colors.black87),
      ),
    );
  }

  void _showAttachmentMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
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
            style: const TextStyle(color: Color(0xFF89AFAF), fontSize: 14),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isGroupChat
            ? widget.receiverUsername
            : 'Chat con ${widget.receiverUsername}'),
        backgroundColor: const Color(0xFF89AFAF),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isSender = message['sender'] ==
                    Get.find<UserController>().currentUserName.value;
                return Align(
                  alignment:
                      isSender ? Alignment.centerRight : Alignment.centerLeft,
                  child: _buildMessage(message, isSender),
                );
              },
            ),
          ),
          _buildMessageInputBar(context),
        ],
      ),
    );
  }

  Widget _buildMessageInputBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      decoration: const BoxDecoration(
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
            icon:
                const Icon(Icons.add_circle_outline, color: Color(0xFF89AFAF)),
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
            icon: const Icon(Icons.send, color: Color(0xFF89AFAF)),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
