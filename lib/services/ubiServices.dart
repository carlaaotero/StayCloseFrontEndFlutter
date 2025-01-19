import 'package:flutter_application_1/models/ubi.dart';
import 'package:dio/dio.dart';

class UbiService {
  //final String baseUrl = "http://127.0.0.1:3000"; // URL de tu backend web
  final String baseUrl = "http://147.83.7.155:3000"; // URL del backend de producción
  // final String baseUrl = "http://10.0.2.2:3000"; // URL del backend para Android
  final Dio dio = Dio(); // Instancia de Dio para hacer las peticiones HTTP

  var statusCode;
  var data;

  // Crear una nueva ubicación
  Future<int> createUbi(UbiModel newUbi) async {
    print('createUbi');
    try {
      Response response = await dio.post(
        '$baseUrl/api/ubi',
        data: newUbi.toJson(),
      );

      data = response.data.toString();
      statusCode = response.statusCode;
      print('Data: $data');
      print('Status code: $statusCode');

      if (statusCode == 201) {
        print('201');
        return 201; // Ubicación creada con éxito
      } else if (statusCode == 400) {
        print('400');
        return 400; // Error de datos no válidos
      } else if (statusCode == 500) {
        print('500');
        return 500; // Error del servidor
      } else {
        print('-1');
        return -1; // Error desconocido
      }
    } catch (e) {
      print('Error creating ubication: $e');
      return -1;
    }
  }

  // Obtener todas las ubicaciones
  Future<List<UbiModel>> getUbis() async {
    print('getUbis');
    try {
      var res = await dio.get('$baseUrl/api/ubi');
      print(res);
      List<dynamic> responseData = res.data;
      print("Totes les ubicacions: $responseData");

      List<UbiModel> ubis = responseData
          .map((data) => UbiModel.fromJson(data))
          .toList();
print("Totes les ubicacions JSON------------: $ubis");
      return ubis;
    } catch (e) {
      print('Error fetching ubications: $e');
      throw e;
    }
  }

  // Función para obtener la lista de ubis por tipo
  Future<List<UbiModel>> getUbisByType(String type) async {
    print('getubisByType');
    try {
      // Enviar solicitud GET para obtener las ubis
      var res = await dio.get('$baseUrl/api/ubi/type/$type');
      print(res);
      List<dynamic> responseData = res.data;
      print("respuesta: $responseData");
      // Convertir la respuesta en una lista de ubiModel
      List<UbiModel> ubis = []; // Asegúrate de inicializarla correctamente o vaciarla cada vez que necesites llenar nuevos datos.
      ubis = responseData
          .map((data) => UbiModel.fromJson(data))
          .toList();
      print("la ubi es: $ubis");
      return ubis;
    } catch (e) {
      print('Error fetching ubis: $e');
      throw e;
    }
  }

  // Editar una ubicación existente
  Future<int> editUbi(UbiModel updatedUbi, String id) async {
    print('editUbi');
    try {
      Response response = await dio.put(
        '$baseUrl/api/ubi/$id',
        data: updatedUbi.toJson(),
      );

      data = response.data.toString();
      statusCode = response.statusCode;
      print('Data: $data');
      print('Status code: $statusCode');

      if (statusCode == 200) {
        print('200');
        return 200; // Ubicación actualizada con éxito
      } else if (statusCode == 400) {
        print('400');
        return 400; // Error de datos no válidos
      } else if (statusCode == 500) {
        print('500');
        return 500; // Error del servidor
      } else {
        print('-1');
        return -1; // Error desconocido
      }
    } catch (e) {
      print('Error editing ubication: $e');
      return -1;
    }
  }

  // Eliminar una ubicación por ID
  Future<int> deleteUbiById(String id) async {
    print('deleteUbiById');
    try {
      Response response = await dio.delete('$baseUrl/api/ubi/$id');

      data = response.data.toString();
      statusCode = response.statusCode;
      print('Data: $data');
      print('Status code: $statusCode');

      if (statusCode == 200) {
        print('Ubication deleted successfully');
        return 200; // Ubicación eliminada con éxito
      } else if (statusCode == 404) {
        print('Ubication not found');
        return 404; // Ubicación no encontrada
      } else if (statusCode == 500) {
        print('Server error');
        return 500; // Error del servidor
      } else {
        print('Unexpected error');
        return -1; // Error desconocido
      }
    } catch (e) {
      print('Error deleting event: $e');
      return -1;
    }
  }

  // Buscar ubicaciones cercanas
  Future<List<UbiModel>> getNearbyUbis(double lat, double lon, double distance) async {
    print('getNearbyUbis');
    try {
      // Realiza la solicitud GET con los parámetros de latitud, longitud y distancia
      var res = await dio.get('$baseUrl/api/ubi/nearby/$lon/$lat/$distance');

      // Comprobamos la respuesta
      print('Response: ${res.data}');

      // Si la respuesta es válida, mapeamos los datos a la lista de UbiModel
      List<dynamic> responseData = res.data;
      List<UbiModel> ubis = responseData
          .map((data) => UbiModel.fromJson(data))
          .toList();

      return ubis;
    } catch (e) {
      print('Error fetching nearby ubications: $e');
      throw e; // Lanzamos el error para ser manejado más arriba
    }
  }

  


}
