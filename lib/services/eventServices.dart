//import 'dart:convert';
import 'package:flutter_application_1/models/event.dart';
import 'package:dio/dio.dart';

class EventService {
  //final String baseUrl = "http://127.0.0.1:3000"; // URL del teu backend web
  //final String baseUrl = "http://147.83.7.155:3000"; // URL del teu backenda producció
  final String baseUrl = "http://10.0.2.2:3000"; // URL del teu backend Android
  final Dio dio = Dio(); // Instància de Dio per fer les peticions HTTP
  var statusCode;
  var data;

  // Crear un nou esdeveniment
  Future<int> createEvent(EventModel newEvent) async {
    print('createEvent');
    try {
      Response response = await dio.post(
        '$baseUrl/api/events',
        data: newEvent.toJson(),
      );

      data = response.data.toString();
      statusCode = response.statusCode;
      print('Data: $data');
      print('Status code: $statusCode');

      if (statusCode == 201) {
        print('201');
        return 201; // Esdeveniment creat amb èxit
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
      print('Error creating event: $e');
      return -1;
    }
  }

  // Obtenir tots els esdeveniments
  Future<List<EventModel>> getEvents() async {
    print('getEvents');
    try {
      var res = await dio.get('$baseUrl/api/events');
      print(res);
      List<dynamic> responseData = res.data;
      print(responseData);

      List<EventModel> events = responseData
          .map((data) => EventModel.fromJson(data))
          .toList();

      return events;
    } catch (e) {
      print('Error fetching events: $e');
      throw e;
    }
  }

  // Editar un esdeveniment existent
  Future<int> editEvent(EventModel updatedEvent, String id) async {
    print('editEvent');
    try {
      Response response = await dio.put(
        '$baseUrl/api/events/$id',
        data: updatedEvent.toJson(),
      );

      data = response.data.toString();
      statusCode = response.statusCode;
      print('Data: $data');
      print('Status code: $statusCode');

      if (statusCode == 200) {
        print('200');
        return 200; // Esdeveniment actualitzat amb èxit
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
      print('Error editing event: $e');
      return -1;
    }
  }

  // Eliminar un esdeveniment per ID
  Future<int> deleteEventById(String id) async {
    print('deleteEventById');
    try {
      Response response = await dio.delete('$baseUrl/api/events/$id');

      data = response.data.toString();
      statusCode = response.statusCode;
      print('Data: $data');
      print('Status code: $statusCode');

      if (statusCode == 200) {
        print('Event deleted successfully');
        return 200; // Esdeveniment eliminat
      } else if (statusCode == 404) {
        print('Event not found');
        return 404; // Esdeveniment no trobat
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
