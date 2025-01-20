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
  LatLng? realTimeLocation;
  final UserService _userService = UserService();
  final UbiController _ubiController = UbiController();
  StreamSubscription<Position>? _positionStreamSubscription;

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
      // Evitar mensajes duplicados
      if (_messages.any((msg) => msg['_id'] == data['_id'])) return;

      if (data['chat'] == widget.chatId) {
        setState(() {
          _messages.add(data);

          // Actualizar ubicación si el mensaje es de tipo ubicación
          if (data['content'].startsWith('location:')) {
            final parts = data['content'].split(':')[1].split(',');
            final latitude = double.parse(parts[0]);
            final longitude = double.parse(parts[1]);
            realTimeLocation = LatLng(latitude, longitude);
          }
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
        _messages.add(newMessage);
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

      String locationContent =
          'location:${position.latitude},${position.longitude}';

      await MessageService.sendMessage(
        chatId: widget.chatId,
        senderUsername: Get.find<UserController>().currentUserName.value,
        receiverUsername: widget.receiverUsername,
        content: locationContent,
      );

      print('Ubicación enviada: $locationContent');
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
        Map<String, double> homeCoordinates =
            await _ubiController.getCoordinatesFromAddress(homeAddress);

        await MessageService.sendMessage(
          chatId: widget.chatId,
          senderUsername: currentUsername,
          receiverUsername: widget.receiverUsername,
          content: 'Me dirijo a casa',
        );

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
            await MessageService.sendMessage(
              chatId: widget.chatId,
              senderUsername: currentUsername,
              receiverUsername: widget.receiverUsername,
              content: 'Ya estoy en casa',
            );
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
            style: TextStyle(color: Color(0xFF89AFAF), fontSize: 14),
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
        backgroundColor: Color(0xFF89AFAF),
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
                  child: Column(
                    crossAxisAlignment: isSender
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      if (widget.isGroupChat && !isSender)
                        Text(
                          message['sender'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      if (message['content'].startsWith('location:'))
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SizedBox(
                            height: 200,
                            width: double.infinity,
                            child: FlutterMap(
                              options: MapOptions(
                                center: realTimeLocation ??
                                    LatLng(41.3851, 2.1734), // Default location
                                zoom: 15.0,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  subdomains: ['a', 'b', 'c'],
                                ),
                                if (realTimeLocation != null)
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: realTimeLocation!,
                                        builder: (ctx) => Icon(
                                          Icons.location_on,
                                          color: Colors.red,
                                          size: 40,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          margin: EdgeInsets.symmetric(
                              vertical: 4.0, horizontal: 8.0),
                          padding: EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: isSender
                                ? Color(0xFF89AFAF)
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            message['content'],
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                    ],
                  ),
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
}



/*import 'dart:async';
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
  LatLng? realTimeLocation;
  final UserService _userService = UserService();
  final UbiController _ubiController = UbiController();
  StreamSubscription<Position>? _positionStreamSubscription;

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
      // Evitar duplicados
      if (_messages.any((msg) => msg['_id'] == data['_id'])) return;

      if (data['chat'] == widget.chatId) {
        setState(() {
          _messages.add(data);

          // Actualizar ubicación si el mensaje es de tipo ubicación
          if (data['content'].startsWith('location:')) {
            final parts = data['content'].split(':')[1].split(',');
            final latitude = double.parse(parts[0]);
            final longitude = double.parse(parts[1]);
            realTimeLocation = LatLng(latitude, longitude);
          }
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
        _messages.add(newMessage);
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

      String locationContent =
          'location:${position.latitude},${position.longitude}';

      await MessageService.sendMessage(
        chatId: widget.chatId,
        senderUsername: Get.find<UserController>().currentUserName.value,
        receiverUsername: widget.receiverUsername,
        content: locationContent,
      );

      print('Ubicación enviada: $locationContent');
    } catch (e) {
      print('Error al obtener la ubicación: $e');
      Get.snackbar('Error', 'No se pudo obtener la ubicación');
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isGroupChat
            ? widget.receiverUsername
            : 'Chat con ${widget.receiverUsername}'),
        backgroundColor: Color(0xFF89AFAF),
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
                  child: Column(
                    crossAxisAlignment: isSender
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      if (widget.isGroupChat && !isSender)
                        Text(
                          message['sender'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      if (message['content'].startsWith('location:'))
                        Container(
                          height: 200,
                          width: 300,
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: FlutterMap(
                            options: MapOptions(
                              center: realTimeLocation ??
                                  LatLng(
                                      41.3851, 2.1734), // Barcelona por defecto
                              zoom: 15.0,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                subdomains: ['a', 'b', 'c'],
                              ),
                              if (realTimeLocation != null)
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: realTimeLocation!,
                                      builder: (ctx) => Icon(
                                        Icons.location_on,
                                        color: Colors.red,
                                        size: 40,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        )
                      else
                        Container(
                          margin: EdgeInsets.symmetric(
                              vertical: 4.0, horizontal: 8.0),
                          padding: EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: isSender
                                ? Color(0xFF89AFAF)
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            message['content'],
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                    ],
                  ),
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
}

*/


/*import 'dart:async';
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
  LatLng? realTimeLocation;
  final UserService _userService = UserService();
  final UbiController _ubiController = UbiController();
  StreamSubscription<Position>? _positionStreamSubscription;

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
      // Evitar duplicados en la lista de mensajes
      if (_messages.any((msg) => msg['_id'] == data['_id'])) return;

      if (data['chat'] == widget.chatId) {
        setState(() {
          _messages.add(data);

          // Actualizar ubicación en tiempo real si el mensaje es de tipo ubicación
          if (data['content'].startsWith('location:')) {
            final parts = data['content'].split(':')[1].split(',');
            final latitude = double.parse(parts[0]);
            final longitude = double.parse(parts[1]);
            realTimeLocation = LatLng(latitude, longitude);
          }
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
        _messages.add(newMessage);
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

      String locationContent =
          'location:${position.latitude},${position.longitude}';

      await MessageService.sendMessage(
        chatId: widget.chatId,
        senderUsername: Get.find<UserController>().currentUserName.value,
        receiverUsername: widget.receiverUsername,
        content: locationContent,
      );

      print('Ubicación enviada: $locationContent');
    } catch (e) {
      print('Error al obtener la ubicación: $e');
      Get.snackbar('Error', 'No se pudo obtener la ubicación');
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isGroupChat
            ? widget.receiverUsername
            : 'Chat con ${widget.receiverUsername}'),
        backgroundColor: Color(0xFF89AFAF),
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
                  child: Column(
                    crossAxisAlignment: isSender
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      if (widget.isGroupChat && !isSender)
                        Text(
                          message['sender'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      if (message['content'].startsWith('location:'))
                        Container(
                          height: 200,
                          width: 300,
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: FlutterMap(
                            options: MapOptions(
                              center: realTimeLocation ??
                                  LatLng(
                                      41.3851, 2.1734), // Barcelona por defecto
                              zoom: 15.0,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                subdomains: ['a', 'b', 'c'],
                              ),
                              if (realTimeLocation != null)
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: realTimeLocation!,
                                      builder: (ctx) => Icon(
                                        Icons.location_on,
                                        color: Colors.red,
                                        size: 40,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        )
                      else
                        Container(
                          margin: EdgeInsets.symmetric(
                              vertical: 4.0, horizontal: 8.0),
                          padding: EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: isSender
                                ? Color(0xFF89AFAF)
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            message['content'],
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                    ],
                  ),
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
}

*/

/*import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/messageService.dart';
import '../services/userServices.dart';
import '../controllers/userController.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
        _messages.add(newMessage);
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

      print('Ubicación enviada: $locationMessage');
    } catch (e) {
      print('Error al obtener la ubicación: $e');
      Get.snackbar('Error', 'No se pudo obtener la ubicación');
    }
  }

  Widget _buildMessage(Map<String, dynamic> message, bool isSender) {
    final content = message['content'];
    if (content.startsWith('location:')) {
      final parts = content.split(':')[1].split(',');
      final latitude = double.parse(parts[0]);
      final longitude = double.parse(parts[1]);

      return Container(
        height: 200,
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

*/


/*
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/messageService.dart';
import '../services/userServices.dart';
import '../controllers/userController.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/ubiController.dart';

class SendMessageScreen extends StatefulWidget {
  final String receiverUsername;
  final String chatId;
  final bool isGroupChat; // Nueva propiedad para indicar si es un chat grupal

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
  final UserService _userService = UserService();
  final UbiController _ubiController = UbiController();
  StreamSubscription<Position>? _positionStreamSubscription;

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
      final currentUser = Get.find<UserController>().currentUserName.value;
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
        _messages.add(newMessage);
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

      String locationLink =
          'https://www.google.com/maps?q=${position.latitude},${position.longitude}';

      await MessageService.sendMessage(
        chatId: widget.chatId,
        senderUsername: Get.find<UserController>().currentUserName.value,
        receiverUsername: widget.receiverUsername,
        content:
            '¡Estoy Aquí! <a href="$locationLink">¡Estoy Aquí!</a>',
      );

      print('Ubicación enviada: $locationLink');
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
        Map<String, double> homeCoordinates =
            await _ubiController.getCoordinatesFromAddress(homeAddress);

        await MessageService.sendMessage(
          chatId: widget.chatId,
          senderUsername: currentUsername,
          receiverUsername: widget.receiverUsername,
          content: 'Me dirijo a casa',
        );

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
            await MessageService.sendMessage(
              chatId: widget.chatId,
              senderUsername: currentUsername,
              receiverUsername: widget.receiverUsername,
              content: 'Ya estoy en casa',
            );
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

  Future<void> _openMap(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      Get.snackbar("Error", "No se pudo abrir el enlace");
    }
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
            style: TextStyle(color: Color(0xFF89AFAF), fontSize: 14),
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
        backgroundColor: Color(0xFF89AFAF),
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
                  child: Column(
                    crossAxisAlignment: isSender
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      if (widget.isGroupChat && !isSender)
                        Text(
                          message['sender'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      Container(
                        margin: EdgeInsets.symmetric(
                            vertical: 4.0, horizontal: 8.0),
                        padding: EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: isSender
                              ? Color(0xFF89AFAF)
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          message['content'],
                          style: TextStyle(color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
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
}

*/


/*import 'dart:async'; // Importar dart:async para StreamSubscription
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/messageService.dart';
import '../services/userServices.dart'; // Importar UserService
import '../controllers/userController.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:geolocator/geolocator.dart'; // Importar Geolocator
import 'package:url_launcher/url_launcher.dart'; // Importar URL Launcher
import '../controllers/ubiController.dart'; // Importar UbiController

class SendMessageScreen extends StatefulWidget {
  final String receiverUsername;
  final String chatId;

  SendMessageScreen({
    required this.receiverUsername,
    required this.chatId,
    this.isGroupChat = false,//predeterminado
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
  final ScrollController _scrollController = ScrollController();///-----
 


  @override
  void initState() {
    super.initState();
    _connectToSocket();
    _loadMessages();
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

  Future<void> _sendLocation() async {
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

  Future<void> _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      final Map<String, String> newMessage = {
        'sender': Get.find<UserController>().currentUserName.value,
        'receiver': widget.isGroupChat ? '' : widget.receiverUsername,
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

  /*

  Future<void> _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      
      
      try {
        await MessageService.sendMessage(
          chatId: widget.chatId,
          senderUsername: Get.find<UserController>().currentUserName.value,
          receiverUsername: widget.receiverUsername,
          content: _messageController.text,
        );
        _messageController.clear();

        // Desplazar automáticamente al final
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      } catch (e) {
        Get.snackbar("Error", "No se pudo enviar el mensaje");
      }
      
    }
  }
  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isGroupChat
            ? widget.receiverUsername
            : 'Chat con ${widget.receiverUsername}'),
        backgroundColor: Color(0xFF89AFAF),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController, // Asigna el ScrollController aquí
              itemCount: _messages.length,
              itemBuilder: (context, index) {
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
            style: TextStyle(color: Color(0xFF89AFAF), fontSize: 14),
          ),
        ],
      ),
    );
  }
}

*/

/*import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/messageService.dart';
import '../services/userServices.dart';
import '../controllers/userController.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/ubiController.dart';

class SendMessageScreen extends StatefulWidget {
  final String receiverUsername;
  final String chatId;
  final bool isGroupChat; // Nueva propiedad para indicar si es un chat grupal

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
  final UserService _userService = UserService();
  final UbiController _ubiController = UbiController();
  StreamSubscription<Position>? _positionStreamSubscription;

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
        'receiver': widget.isGroupChat
            ? ''
            : widget.receiverUsername, // Receiver en chats individuales
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

  // Método para abrir enlaces de Google Maps
  Future<void> _openMap(String url) async {
    if (await canLaunch(url)) {
      await launch(url); // Abrir el enlace
    } else {
      Get.snackbar("Error", "No se pudo abrir el enlace");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isGroupChat
            ? widget.receiverUsername
            : 'Chat con ${widget.receiverUsername}'),
        backgroundColor: Color(0xFF89AFAF),
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
                  child: Column(
                    crossAxisAlignment: isSender
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      // Mostrar el nombre del remitente en chats grupales
                      if (widget.isGroupChat && !isSender)
                        Text(
                          message['sender'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      Container(
                        margin: EdgeInsets.symmetric(
                            vertical: 4.0, horizontal: 8.0),
                        padding: EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: isSender
                              ? Color(0xFF89AFAF)
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          message['content'],
                          style: TextStyle(color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
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
}

*/

/*import 'dart:async'; // Importar dart:async para StreamSubscription
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/messageService.dart';
import '../services/userServices.dart'; // Importar UserService
import '../controllers/userController.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:geolocator/geolocator.dart'; // Importar Geolocator
import 'package:url_launcher/url_launcher.dart'; // Importar URL Launcher
import '../controllers/ubiController.dart'; // Importar UbiController

class SendMessageScreen extends StatefulWidget {
  final String receiverUsername;
  final String chatId;
  final bool isGroupChat; // Nueva propiedad

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
  final List<Map<String, dynamic>> _messages = [];
  late IO.Socket _socket;
  final UserService _userService = UserService(); // Instanciar UserService
  final UbiController _ubiController =
      UbiController(); // Instanciar UbiController
  StreamSubscription<Position>?
      _positionStreamSubscription; // Subscription para el stream de ubicación
  final ScrollController _scrollController = ScrollController();

  ///-----

  @override
  void initState() {
    super.initState();
    _connectToSocket();
    _loadMessages();
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

  Future<void> _sendLocation() async {
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
*/
/////////////////////******************FUNCIONA PARA ARRIBA */

  /*

  Future<void> _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      
      
      try {
        await MessageService.sendMessage(
          chatId: widget.chatId,
          senderUsername: Get.find<UserController>().currentUserName.value,
          receiverUsername: widget.receiverUsername,
          content: _messageController.text,
        );
        _messageController.clear();

        // Desplazar automáticamente al final
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      } catch (e) {
        Get.snackbar("Error", "No se pudo enviar el mensaje");
      }
      
    }
  }
  */
/*--------------------------------------------------------FUNCIONA---------------
//FUNCIONA
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
              controller: _scrollController, // Asigna el ScrollController aquí
              itemCount: _messages.length,
              itemBuilder: (context, index) {
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
              },
            ),
          ), //okkkk
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
            style: TextStyle(color: Color(0xFF89AFAF), fontSize: 14),
          ),
        ],
      ),
    );
  }
}


///FUNCIONAA
///
*/

/*

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/messageService.dart';
import '../controllers/userController.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/message.dart';

class SendMessageScreen extends StatefulWidget {
  final String receiverUsername;
  final String chatId;

  const SendMessageScreen({
    required this.receiverUsername,
    required this.chatId,
  });

  @override
  _SendMessageScreenState createState() => _SendMessageScreenState();
}

class _SendMessageScreenState extends State<SendMessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [];
  late IO.Socket _socket;

  @override
  void initState() {
    super.initState();
    _connectToSocket();
    _loadMessages();
  }

  @override
  void dispose() {
    _socket.disconnect();
    _messageController.dispose();
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
      final message = Message.fromJson(data);
      setState(() {
        _messages.add(message);
      });
      _scrollToBottom();
    });

    _socket.onConnect((_) => print('Conectado al servidor de WebSocket'));
    _socket
        .onDisconnect((_) => print('Desconectado del servidor de WebSocket'));
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await MessageService.getMessages(widget.chatId);
      setState(() {
        _messages.addAll(messages);
      });
      _scrollToBottom();
    } catch (e) {
      print('Error al cargar mensajes: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      try {
        await MessageService.sendMessage(
          chatId: widget.chatId,
          senderUsername: Get.find<UserController>().currentUserName.value,
          receiverUsername: widget.receiverUsername,
          content: _messageController.text,
        );
        _messageController.clear();
      } catch (e) {
        Get.snackbar("Error", "No se pudo enviar el mensaje");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat con ${widget.receiverUsername}'),
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
                final isSender = message.sender ==
                    Get.find<UserController>().currentUserName.value;
                return Align(
                  alignment:
                      isSender ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.all(8.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: isSender
                          ? const Color(0xFF89AFAF)
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.content,
                          style: TextStyle(
                              color: isSender ? Colors.white : Colors.black87),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          message.formattedTime,
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          _buildMessageInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageInputBar() {
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

*/