//import 'dart:convert';
import 'package:flutter_application_1/models/ubi.dart';
import 'package:dio/dio.dart';


class UbiService {
  final String baseUrl = "http://127.0.0.1:3000"; // URL del teu backend web
  //final String baseUrl = "http://147.83.7.155:3000"; // URL del teu backenda producció
  // final String baseUrl = "http://10.0.2.2:3000"; // URL del teu backend Android
  final Dio dio = Dio(); // Instància de Dio per fer les peticions HTTP
  var statusCode;
  var data;

  // Crear una nova ubicació
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
        return 201; // Ubicació creada amb èxit
      } else if (statusCode == 400) {
        print('400');
        return 400; // Error de dades no vàlides
      } else if (statusCode == 500) {
        print('500');
        return 500; // Error del servidor
      } else {
        print('-1');
        return -1; // Error desconegut
      }
    } catch (e) {
      print('Error creating ubication: $e');
      return -1;
    }
  }

  // Obtenir totes les ubicacions
  Future<List<UbiModel>> getUbis() async {
    print('getUbis');
    try {
      var res = await dio.get('$baseUrl/api/ubi');
      print(res);
      List<dynamic> responseData = res.data;
      print(responseData);

      List<UbiModel> ubis = responseData
          .map((data) => UbiModel.fromJson(data))
          .toList();

      return ubis;
    } catch (e) {
      print('Error fetching ubications: $e');
      throw e;
    }
  }

  // Editar una ubicació existent
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
        return 200; // Ubicació actualitzada amb èxit
      } else if (statusCode == 400) {
        print('400');
        return 400; // Error de dades no vàlides
      } else if (statusCode == 500) {
        print('500');
        return 500; // Error del servidor
      } else {
        print('-1');
        return -1; // Error desconegut
      }
    } catch (e) {
      print('Error editing ubication: $e');
      return -1;
    }
  }

  // Eliminar una ubicació per ID
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
        return 200; // Ubicació eliminada 
      } else if (statusCode == 404) {
        print('Ubication not found');
        return 404; // Ubicació no trobada
      } else if (statusCode == 500) {
        print('Server error');
        return 500; // Error del servidor
      } else {
        print('Unexpected error');
        return -1; // Error desconegut
      }
    } catch (e) {
      print('Error deleting event: $e');
      return -1;
    }
  }
}
