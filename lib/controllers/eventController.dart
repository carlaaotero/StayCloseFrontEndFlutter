import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_application_1/models/event.dart';
import 'package:flutter_application_1/services/eventServices.dart';
import 'package:shared_preferences/shared_preferences.dart';


class EventController extends GetxController {
  final eventService = EventService();
  var events = <EventModel>[].obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;

  // Variables per gestionar el calendari
  var focusedDay = DateTime.now().obs; // El dia actual per centrar el calendari
  var selectedDay = DateTime.now().obs; // El dia seleccionat

  // Controladors per al formulari de creació
  TextEditingController nameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController creatorController = TextEditingController();
  Uint8List? selectedImage;

  @override
  void onInit() {
    super.onInit();
    fetchEvents();
    _loadId();
  }

   // Mètode per carregar el id des de SharedPreferences
  void _loadId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String id = prefs.getString('user_id') ?? '';  
    creatorController.text = id;  // Rellenar el campo de autor
  }

  Future<void> fetchEvents() async {
    isLoading.value = true;
    try {
      final fetchedEvents = await eventService.getEvents();
      events.value = fetchedEvents;
    } catch (e) {
      errorMessage.value = 'Error al carregar els esdeveniments.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createEvent() async {
    final name = nameController.text.trim();
    final description = descriptionController.text.trim();
    final eventDate = dateController.text.trim();
    final creator = creatorController.text.trim();
  
    if (name.isEmpty || description.isEmpty || eventDate.isEmpty  || creator.isEmpty) {
      Get.snackbar("Error", "Tots els camps són obligatoris");
      return;
    }

    try {
      isLoading.value = true;
      final eventDate2=DateTime.parse(eventDate); // Converteix el text a DateTime
      final eventDate3=eventDate2.add(Duration(hours: 2));
      
      await eventService.createEvent(EventModel(
        name: name,
        description: description,
        eventDate:eventDate3, // Converteix el text a DateTime
        creator: creator,
      ));
      fetchEvents(); // Refresca la llista d'esdeveniments
      clearForm();
      Get.snackbar("Èxit", "Esdeveniment creat correctament");
    } catch (e) {
      Get.snackbar("Error", "No s'ha pogut crear l'esdeveniment");
    } finally {
      isLoading.value = false;
    }
  }

  void clearForm() {
    nameController.clear();
    descriptionController.clear();
    dateController.clear();
    creatorController.clear();
    selectedImage = null;
  }
   // Mètode per obtenir els esdeveniments per a un dia en concret
  List<EventModel> getEventsForDay(DateTime day) {
    return events.where((event) {
      // Comprovem si la data de l'esdeveniment coincideix amb el dia seleccionat
      return event.eventDate.year == day.year &&
          event.eventDate.month == day.month &&
          event.eventDate.day == day.day;
    }).toList();
  }

  // Mètode per gestionar la selecció d'un dia
  void onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    this.selectedDay.value = selectedDay;
    this.focusedDay.value = focusedDay; // Actualitzar el mes quan es selecciona un dia
  }
}