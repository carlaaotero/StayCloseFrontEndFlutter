import 'package:flutter/material.dart';

class UserModel with ChangeNotifier {
  String _username;
  String _name;
  String _email;
  String _password;
  List<dynamic> _actualUbication = []; // en mes de fica dinamic podriem ficar
  //Ubicació i fer una interficie d'ubicacio que tingui, pais, codi postal, provincia, població, carrer, numero. (el que calgui per fer la funció)
  bool _inHome;
  bool _admin;
  bool _disabled;
  String _status; // Para indicar si esta online o offline
  bool _isGrup; //para identificar si es un grupo o no

  // Constructor
  UserModel({
    required String username,
    required String name,
    required String email,
    required String password,
    required List<dynamic> actualUbication,
    bool inHome = false,
    bool admin = true,
    bool disabled = false,
    String status =
        "offline", //Indicamos como su valor por defecto usuario desconectado
    bool isGrup = false, //Valor predeterminado indicar no grupo
  })  : _username = username,
        _name = name,
        _email = email,
        _password = password,
        _actualUbication = actualUbication,
        _inHome = inHome,
        _admin = admin,
        _disabled = disabled,
        _status = status,
        _isGrup = isGrup;

  // Getters
  String get username => _username;
  String get name => _name;
  String get email => _email;
  String get password => _password;
  List<dynamic> get actualUbication => _actualUbication;
  bool get inHome => _inHome;
  bool get admin => _admin;
  bool get disabled => _disabled;
  String get status => _status;
  bool get isGroup => _isGrup;

//Setters  **opcional
  void setStatus(String status) {
    _status = status;
    notifyListeners();
  }

  // Método para actualizar el usuario
  void setUser(
      String username,
      String name,
      String email,
      String password,
      List<dynamic> actualUbication,
      bool inHome,
      bool admin,
      bool disabled,
      String status,
      bool isGroup) {
    _username = username;
    _name = name;
    _email = email;
    _password = password;
    _actualUbication = actualUbication;
    _inHome = inHome;
    _disabled = disabled;
    _status = status;
    _isGrup = isGroup;
    notifyListeners();
  }

  // Método fromJson para crear una instancia de UserModel desde un Map
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      username: json['username'] ?? 'Username ?',
      name: json['name'] ?? 'Usuario desconocido',
      email: json['email'] ?? 'No especificado',
      password: json['password'] ?? 'Sin contraseña',
      actualUbication: json['actualUbication'] ?? 'ubi desconocida',
      inHome: json['inHome'],
      admin: json['admin'],
      disabled: json['disabled'],
      status: json['status'] ?? 'offline',
      isGrup: json['isGroup'] ??
          false, // valor predeterminado si no esta especificado
    );
  }

  // Método toJson para convertir una instancia de UserModel en un Map
  Map<String, dynamic> toJson() {
    return {
      'username': _username,
      'name': _name,
      'email': _email,
      'password': _password,
      'actualUbication': _actualUbication,
      'inHome': _inHome,
      'admin': _admin,
      'disabled': _disabled,
      'status': _status,
      'isGroup': _isGrup,
    };
  }
}
