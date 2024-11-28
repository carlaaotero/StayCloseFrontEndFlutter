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

  // Constructor
  UserModel({
    required String username,
    required String name,
    required String email,
    required String password,
    required List<dynamic> actualUbication,
    bool inHome = false,
    bool admin = false, //No todos los usuarios seran admins consultar******
    bool disabled = false,
  })  : _username = username,
        _name = name,
        _email = email,
        _password = password,
        _actualUbication = actualUbication,
        _inHome = inHome,
        _admin = admin,
        _disabled = disabled;

  // Getters
  String get username => _username;
  String get name => _name;
  String get email => _email;
  String get password => _password;
  List<dynamic> get actualUbication => _actualUbication;
  bool get inHome => _inHome;
  bool get admin => _admin;
  bool get disabled => _disabled;

//Setters

  // Setters con notificación para actualizar los datos
  set username(String value) {
    _username = value;
    notifyListeners();
  }

  set name(String value) {
    _name = value;
    notifyListeners();
  }

  set email(String value) {
    _email = value;
    notifyListeners();
  }

  set password(String value) {
    _password = value;
    notifyListeners();
  }

  set actualUbication(List<dynamic> value) {
    _actualUbication = value;
    notifyListeners();
  }

  set inHome(bool value) {
    _inHome = value;
    notifyListeners();
  }

  set admin(bool value) {
    _admin = value;
    notifyListeners();
  }

  set disabled(bool value) {
    _disabled = value;
    notifyListeners();
  }

  // Método para actualizar el usuario
  void setUser(String username, String name, String email, String password,
      List<dynamic> actualUbication, bool inHome, bool admin, bool disabled) {
    _username = username;
    _name = name;
    _email = email;
    _password = password;
    _actualUbication = actualUbication;
    _inHome = inHome;
    _disabled = disabled;
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
      inHome: json['inHome'] ?? false,
      admin: json['admin'] ?? false,
      disabled: json['disabled'] ?? false,
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
    };
  }
}
