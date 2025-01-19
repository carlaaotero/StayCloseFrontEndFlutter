import 'dart:convert';
import 'package:flutter_application_1/models/user.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart'; // Para decodificar el JWT

class UserService {
  //final String baseUrl = "http://127.0.0.1:3000/api"; // URL de tu backend Web
  final String baseUrl = "http://147.83.7.155:3000/api"; // URL del teu backenda producció
  //final String baseUrl = "http://10.0.2.2:3000"; // URL de tu backend Android
  final Dio dio = Dio(BaseOptions(
    validateStatus: (status) {
      return status! <
          500; // Permite respuestas con códigos de estado 2xx y 3xx
    },
    followRedirects: true, // Habilitar seguir redirecciones
    maxRedirects: 5, // Limitar la cantidad de redirecciones
  ));
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

  // Método para cerrar sesión
  Future<void> logOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token'); // Eliminar el token
    await prefs.remove('user_id'); // Eliminar el ID del usuario
    await prefs.remove('username'); // Eliminar el nombre del usuario
    await prefs.remove('email'); // Eliminar el email del usuario
    await prefs.remove('is_admin'); // Eliminar el estado de admin

    print('Usuario cerrado sesión y datos eliminados de SharedPreferences.');
  }

  Future<int> logIn(logIn) async {
    try {
      print('Enviando solicitud de LogIn');
      Response response =
          await dio.post('$baseUrl/user/login', data: logInToJson(logIn));

      if (response.statusCode == 200) {
        String token = response.data['token'];
        if (token == null) {
          return -1; // Si el token es null, no se puede continuar
        }
        // Decodificar el token JWT
        Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
        print('Token decodificado: $decodedToken');

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString(
            'user_id', decodedToken['id'] ?? ''); // Manejar null
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
    return {'username': logIn.username, 'password': logIn.password};
  }

  Future<int> createUser(UserModel newUser) async {
    print('createUser');

    try {
      Response response =
          await dio.post('$baseUrl/user/', data: newUser.toJson());

      print('Respuesta completa del servidor: ${response.data}');
      print('Respuesta del servidor: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('200: usuario creado');
        return 201;
      } else if (response.statusCode == 301) {
        print('301: El nombre de usuario ya está en uso');
        return 301;
      } else if (response.statusCode == 302) {
        print('302: El correo electrónico ya está en uso');
        return 302;
      } else if (response.statusCode == 400) {
        print('400: Campos faltantes');
        return 400;
      } else if (response.statusCode == 500) {
        print('500: Error interno del servidor');
        return 500;
      } else {
        print('-1: Código de error desconocido');
        return -1;
      }
    } catch (e) {
      print('Error al hacer la solicitud: $e');
      return -1;
    }
  }

/*
  Future<List<UserModel>> getUsers(int page, int limit) async {
    print('getUsers');
    print('Obteniendo usuarios desde el backend');
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
  */ //usuarios paginados como los conectados
  Future<List<UserModel>> getUsers(
      {int page = 1, int limit = 20, bool connectedOnly = false}) async {
    try {
      if (connectedOnly) {
        // Obtener usuarios conectados
        print('Obteniendo usuarios conectados desde el backend');
        Response response = await dio.get("$baseUrl/connected-users");
        if (response.statusCode == 200) {
          List<dynamic> data = response.data;
          return data.map((user) => UserModel.fromJson(user)).toList();
        } else {
          throw Exception("Failed to fetch connected users");
        }
      } else {
        // Obtener usuarios con paginación
        print('Obteniendo usuarios desde el backend con paginación');
        var res = await dio.get('$baseUrl/getUsers/$page/$limit');
        List<dynamic> responseData = res.data;

        // Convertir los datos en una lista de objetos UserModel
        return responseData.map((data) => UserModel.fromJson(data)).toList();
      }
    } catch (e) {
      print("Error al obtener usuarios: $e");
      throw e;
    }
  }

  Future<int> editUser(UserModel newUser, String id, String password) async {
    print('EditUser');
    print('try');

    // Llamar a _setAuthHeaders() para asegurarnos de que el token esté configurado
    await _setAuthHeaders();

    print('request');
    // Realizar la solicitud PUT para editar los datos del usuario, incluyendo la contraseña en la URL
    Response response = await dio.put(
      '$baseUrl/user/update/$id/$password', // Añadimos la contraseña a la URL
      data: newUser.toJson(),
    );

    // Obtener los datos de la respuesta
    data = response.data.toString();
    print('Data: $data');

    // Obtener el status code de la respuesta
    statusCode = response.statusCode;
    print('Status code: $statusCode');

    // Manejar las posibles respuestas del servidor
    if (statusCode == 200) {
      // Si el usuario se edita correctamente
      print('User edited successfully');
      return 200; // Devolvemos el código de éxito
    } else if (statusCode == 400) {
      // Si hay un error con la solicitud
      print('400 - Bad request');
      return 400;
    } else if (statusCode == 500) {
      // Si hay un error interno del servidor
      print('500 - Server error');
      return 500;
    } else {
      // Si hay un error desconocido
      print('-1 - Unknown error');
      return -1;
    }
  }

  /*Future<int> EditUser(UserModel newUser, String id) async {
    print('EditUser');
    print('try');
    
    // Llamar a _setAuthHeaders() para asegurarnos de que el token esté configurado
    await _setAuthHeaders();

    print('request');
    // Realizar la solicitud PUT para editar los datos del usuario
    Response response = await dio.put('$baseUrl/user/update/$id', data: newUser.toJson());

    // Obtener los datos de la respuesta
    data = response.data.toString();
    print('Data: $data');
    
    // Obtener el status code de la respuesta
    statusCode = response.statusCode;
    print('Status code: $statusCode');

    // Manejar las posibles respuestas del servidor
    if (statusCode == 200) {
      // Si el usuario se edita correctamente
      print('User edited successfully');
      return 200;  // Devolvemos el código de éxito
    } else if (statusCode == 400) {
      // Si hay un error con la solicitud
      print('400 - Bad request');
      return 400;
    } else if (statusCode == 500) {
      // Si hay un error interno del servidor
      print('500 - Server error');
      return 500;
    } else {
      // Si hay un error desconocido
      print('-1 - Unknown error');
      return -1;
    }
  }*/

  Future<int> deleteUser(String id) async {
    print('deleteUser');
    print('try');

    // Llamar a _setAuthHeaders() para asegurarnos de que el token esté configurado
    await _setAuthHeaders();

    print('request');
    // Realizar la solicitud DELETE para eliminar al usuario
    //Response response = await dio.delete('$baseUrl/user/$id');

    // Deshabilitar usuario
    Response response = await dio.patch('$baseUrl/user/disable/$id');

    // Obtener los datos de la respuesta
    data = response.data.toString();
    print('Data: $data');

    // Obtener el status code de la respuesta
    statusCode = response.statusCode;
    print('Status code: $statusCode');

    // Manejar las posibles respuestas del servidor
    if (statusCode == 200) {
      // Si el usuario se elimina correctamente
      print('User deleted successfully');
      return 200; // Devolvemos el código de éxito
    } else if (statusCode == 400) {
      // Si hay un error con la solicitud
      print('400 - Bad request');
      return 400;
    } else if (statusCode == 500) {
      // Si hay un error interno del servidor
      print('500 - Server error');
      return 500;
    } else {
      // Si hay un error desconocido
      print('-1 - Unknown error');
      return -1;
    }
  }

  Future<UserModel?> getUser(String id) async {
    try {
      print('Fetching user with ID: $id');

      // Llamar a _setAuthHeaders() para asegurarnos de que el token esté configurado
      await _setAuthHeaders();

      // Realizar la solicitud GET para obtener los datos del usuario
      final response = await dio.get('$baseUrl/user/getUser/$id');

      if (response.statusCode == 200) {
        // Si la respuesta es exitosa, se retorna el modelo de usuario
        print('User data fetched successfully: ${response.data}');
        return UserModel.fromJson(response.data);
      } else {
        // Si el código de estado no es 200, retornamos null y mostramos el código de error
        print('Failed to fetch user. Status code: ${response.statusCode}');
        return null;
      }
    } on DioError catch (e) {
      // Manejo de errores específicos de Dio
      if (e.response != null) {
        print(
            'Error fetching user: ${e.response?.statusCode}, ${e.response?.data}');
        // Aquí puedes procesar los errores de red o de servidor
        if (e.response?.statusCode == 404) {
          print('User not found.');
        } else if (e.response?.statusCode == 500) {
          print('Server error. Please try again later.');
        }
      } else {
        print('Error fetching user: No response from server. ${e.message}');
      }
      return null;
    } catch (e) {
      // Captura cualquier otro tipo de error
      print('Unexpected error fetching user: $e');
      return null;
    }
  }

  //Buscar un usuario por su username

  Future<UserModel?> getUserByUsername(String username) async {
    try {
      final response =
          await dio.get('$baseUrl/user/getUserByUsername/$username');
      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      } else {
        print('Error al obtener usuario: ${response.data}');
        return null;
      }
    } catch (e) {
      print('Error al obtener usuario: $e');
      return null;
    }
  }

  //Obtenir la direcció de casa d'un usuari
  Future<String?> getHomeUser(String username) async {
    try {
      print('Fetching home address for user with username: $username');

      // Llamar a _setAuthHeaders() para asegurarnos de que el token esté configurado
      await _setAuthHeaders();

      // Realizar la solicitud GET para obtener la dirección de la casa del usuario
      final response = await dio.get('$baseUrl/user/home/$username');

      if (response.statusCode == 200) {
        // Si la respuesta es exitosa, se retorna la dirección de la casa directamente
        print('Home address fetched successfully: ${response.data}');
        return response.data;
      } else {
        // Si el código de estado no es 200, retornamos null y mostramos el código de error
        print('Failed to fetch home address. Status code: ${response.statusCode}');
        return null;
      }
    } on DioError catch (e) {
      // Manejo de errores específicos de Dio
      if (e.response != null) {
        print('Error fetching home address: ${e.response?.statusCode}, ${e.response?.data}');
        // Aquí puedes procesar los errores de red o de servidor
        if (e.response?.statusCode == 404) {
          print('Home address not found.');
        } else if (e.response?.statusCode == 500) {
          print('Server error. Please try again later.');
        }
      } else {
        print('Error fetching home address: No response from server. ${e.message}');
      }
      return null;
    } catch (e) {
      // Captura cualquier otro tipo de error
      print('Unexpected error fetching home address: $e');
      return null;
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
