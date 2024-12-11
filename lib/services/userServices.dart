import 'dart:convert';
import 'package:flutter_application_1/models/user.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart'; // Para decodificar el JWT

class UserService {
  //final String baseUrl = "http://127.0.0.1:3000/api"; // URL de tu backend Web
  final String baseUrl = "http://147.83.7.155:3000/api"; // URL backend a producció
  //final String baseUrl = "http://10.0.2.2:3000"; // URL de tu backend Android
  final Dio dio = Dio(); // Usa el prefijo 'Dio' para referenciar la clase Dio
  var statusCode;
  var data;

  // Obtener el token desde SharedPreferences
  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Configurar las cabeceras con el token
  Future<void> _setAuthHeaders() async {
    String? token = await _getToken();
    if (token != null) {
      dio.options.headers['auth-token'] = token;
    } else {
      print('No se encontró un token en SharedPreferences.');
    }
  }

  Future<int> logIn(logIn) async {
    try {
      print('Enviando solicitud de LogIn');
      Response response = await dio.post('$baseUrl/user/login', data: logInToJson(logIn));

      if (response.statusCode == 200) {
        String token = response.data['token'];
        if (token == null) {
          return -1;  // Si el token es null, no se puede continuar
        }
        // Decodificar el token JWT
        Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
        print('Token decodificado: $decodedToken');

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('user_id', decodedToken['id'] ?? ''); // Manejar `null`
        await prefs.setString('username', decodedToken['username'] ?? '');
        await prefs.setString('email', decodedToken['email'] ?? '');
        await prefs.setBool('is_admin', decodedToken['admin'] ?? true);

        print('Token y datos guardados en SharedPreferences.');
        return 200;
      } else {
        print('Error en logIn: ${response.statusCode}');
        return response.statusCode!;
      }
    } catch (e) {
      print('Error en logIn: $e');
      return -1;
    }
  }
  Map<String, dynamic> logInToJson(logIn) {
    return {'username': logIn.username, 
    'password': logIn.password};
  }
  
  //Función createUser
  Future<int> createUser(UserModel newUser) async {
    print('createUser');
    print('try');
    //Aquí llamamos a la función request
    print('request');
    // Utilizar Dio para enviar la solicitud POST a http://127.0.0.1:3000/user
    Response response =
        await dio.post('$baseUrl/user/', data: newUser.toJson());
    print('response');
    //En response guardamos lo que recibimos como respuesta
    //Printeamos los datos recibidos

    data = response.data.toString();
    print('Data: $data');
    //Printeamos el status code recibido por el backend

    statusCode = response.statusCode;
    print('Status code: $statusCode');

    if (statusCode == 200) {
      // Si el usuario se crea correctamente, retornamos el código 201
      print('200: usuario creado');
      return 201;
    } else if (statusCode == 400) {
      // Si hay campos faltantes, retornamos el código 400
      print('400');

      return 400;
    } else if (statusCode == 500) {
      // Si hay un error interno del servidor, retornamos el código 500
      print('500');

      return 500;
    } else {
      // Otro caso no manejado
      print('-1');

      return -1;
    }
  }

  Future<List<UserModel>> getUsers(int page, int limit) async {
    print('getUsers');
    try {
      // Passar els paràmetres de pàgina i límit a la URL
      var res = await dio.get('$baseUrl/getUsers/$page/$limit');
      List<dynamic> responseData =
          res.data; // Obtener los datos de la respuesta

      // Convertir los datos en una lista de objetos UserModel
      List<UserModel> users =
          responseData.map((data) => UserModel.fromJson(data)).toList();

      return users; // Devolver la lista de usuarios
    } catch (e) {
      // Manejar cualquier error que pueda ocurrir durante la solicitud
      print('Error fetching data: $e');
      throw e; // Relanzar el error para que el llamador pueda manejarlo
    }
  }


  Future<int> EditUser(UserModel newUser, String id) async {
    print('createUser');
    print('try');
    //Aquí llamamos a la función request
    print('request');

    // Utilizar Dio para enviar la solicitud POST a http://127.0.0.1:3000/user
    Response response =
        await dio.put('$baseUrl/user/$id', data: newUser.toJson());
    //En response guardamos lo que recibimos como respuesta
    //Printeamos los datos recibidos

    data = response.data.toString();
    print('Data: $data');
    //Printeamos el status code recibido por el backend

    statusCode = response.statusCode;
    print('Status code: $statusCode');

    if (statusCode == 201) {
      // Si el usuario se crea correctamente, retornamos el código 201
      print('201');
      return 201;
    } else if (statusCode == 400) {
      // Si hay campos faltantes, retornamos el código 400
      print('400');

      return 400;
    } else if (statusCode == 500) {
      // Si hay un error interno del servidor, retornamos el código 500
      print('500');

      return 500;
    } else {
      // Otro caso no manejado
      print('-1');

      return -1;
    }
  }

  Future<int> deleteUser(String id) async {
    print('createUser');
    print('try');
    //Aquí llamamos a la función request
    print('request');

    // Utilizar Dio para enviar la solicitud POST a http://127.0.0.1:3000/user
    Response response = await dio.delete('$baseUrl/user/$id');
    //En response guardamos lo que recibimos como respuesta
    //Printeamos los datos recibidos

    data = response.data.toString();
    print('Data: $data');
    //Printeamos el status code recibido por el backend

    statusCode = response.statusCode;
    print('Status code: $statusCode');

    if (statusCode == 201) {
      // Si el usuario se crea correctamente, retornamos el código 201
      print('201');
      return 201;
    } else if (statusCode == 400) {
      // Si hay campos faltantes, retornamos el código 400
      print('400');

      return 400;
    } else if (statusCode == 500) {
      // Si hay un error interno del servidor, retornamos el código 500
      print('500');

      return 500;
    } else {
      // Otro caso no manejado
      print('-1');

      return -1;
    }
  }

  // Método para obtener un usuario por su ID
  /*Future<UserModel?> getUserById(String id) async {
    try {
      // Configurar las cabeceras con el token antes de la solicitud
      await _setAuthHeaders();

      // Realizar la solicitud GET
      Response response = await dio.get('$baseUrl/user/getUser/$id');

      if (response.statusCode == 200 && response.data != null) {
        return UserModel.fromJson(response.data); // Convertir la respuesta en un objeto UserModel
      } else {
        print('Error: ${response.statusCode} al obtener el usuario');
        return null;
      }
    } catch (e) {
      print('Error en getUserById: $e');
      return null;
    }
  }*/
}
