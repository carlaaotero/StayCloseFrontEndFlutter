import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_application_1/models/ubi.dart';
import 'package:flutter_application_1/services/ubiServices.dart';
import 'package:shared_preferences/shared_preferences.dart';
//Ubi user
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';




class UbiController extends GetxController {
  final ubiService = UbiService();
  var ubis = <UbiModel>[].obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;
  Rx<LatLng?> userLocation = Rx<LatLng?>(null); // Ubicació de l'usuari


  // Controladors per al formulari de creació i edició
  TextEditingController nameController = TextEditingController();
  TextEditingController latitudeController = TextEditingController();
  TextEditingController longitudeController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController tipoController = TextEditingController();
  TextEditingController comentariController = TextEditingController();
  TextEditingController horariController = TextEditingController();

  

  @override
  void onInit() {
    super.onInit();
    fetchUbis();
    //getUserLocation();
    fetchUserLocation();
  }

  //Obtenir totes les ubicacions
  Future<void> fetchUbis() async {
    isLoading.value = true;
    try {
      final fetchedUbis = await ubiService.getUbis();
      ubis.value = fetchedUbis;
    } catch (e) {
      errorMessage.value = 'Error al carregar les ubicacions.';
    } finally {
      isLoading.value = false;
    }
  }

  //Crear una nova ubicació
  Future<void> createUbi() async {
    final name = nameController.text.trim();
    final latitud = latitudeController.text.trim();
    final longitud = longitudeController.text.trim();
    final address = addressController.text.trim();
    final comentari = comentariController.text.trim();
    final tipo = tipoController.text.trim();
    final horari = horariController.text.trim();

  
    if (name.isEmpty || latitud.isEmpty || longitud.isEmpty || address.isEmpty || comentari.isEmpty  || tipo.isEmpty || horari.isEmpty) {
      Get.snackbar("Error", "Tots els camps són obligatoris");
      return;
    }

    try {
      isLoading.value = true;

      final ubication = {
        'latitud': double.parse(latitud),
        'longitud': double.parse(longitud),
      };
        
      await ubiService.createUbi(UbiModel(
        name: name,
        horari: horari,
        tipo: tipo,
        ubication: ubication,
        address: address,
        comentari: comentari,
      ));

      fetchUbis(); // Refresca la llista d'ubicacions
      clearForm();
      Get.snackbar("Èxit", "Ubicació creada correctament");
    
    } catch (e) {
      Get.snackbar("Error", "No s'ha pogut crear la ubicació");
    } finally {
      isLoading.value = false;
    }
  }

  // Editar una ubicació existent
  Future<void> editUbi(String id) async {
    final name = nameController.text.trim();
    final latitude = latitudeController.text.trim();
    final longitude = longitudeController.text.trim();
    final address = addressController.text.trim();
    final comentari = comentariController.text.trim();
    final tipo = tipoController.text.trim();
    final horari = horariController.text.trim();

    if (name.isEmpty || latitude.isEmpty || longitude.isEmpty || address.isEmpty || comentari.isEmpty  || tipo.isEmpty || horari.isEmpty) {
      Get.snackbar("Error", "Tots els camps són obligatoris");
      return;
    }

    try {
      isLoading.value = true;

      final ubication = {
        'latitude': double.parse(latitude),
        'longitude': double.parse(longitude),
      };

      await ubiService.editUbi(UbiModel(
        name: name,
        horari: horari,
        tipo: tipo,
        address: address,
        ubication: ubication,
        comentari: comentari,
      ), id);
      fetchUbis(); // Refresca la llista d'ubicacions
      clearForm();
      Get.snackbar("Èxit", "Ubicació editada correctament");
    } catch (e) {
      Get.snackbar("Error", "No s'ha pogut editar la ubicació");
    } finally {
      isLoading.value = false;
    }
  }

  // Eliminar una ubicació
  Future<void> deleteUbi(String id) async {
    try {
      isLoading.value = true;
      await ubiService.deleteUbiById(id);
      fetchUbis(); // Refresca la llista d'ubicacions
      Get.snackbar("Èxit", "Ubicació eliminada correctament");
    } catch (e) {
      Get.snackbar("Error", "No s'ha pogut eliminar la ubicació");
    } finally {
      isLoading.value = false;
    }
  }


  // Netejar els camps del formulari
  void clearForm() {
    nameController.clear();
    latitudeController.clear();
    longitudeController.clear();
    addressController.clear();
    comentariController.clear();
    tipoController.clear();
    horariController.clear();

  }

  // Funció per obtenir la ubicació actual
  /*Future<void> getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar("Error", "El servei de localització està desactivat");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar("Error", "El permís de localització ha estat denegat");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Get.snackbar(
          "Error",
          "El permís de localització ha estat denegat permanentment",
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      userLocation.value = LatLng(position.latitude, position.longitude);
    } catch (e) {
      Get.snackbar("Error", "No s'ha pogut obtenir la ubicació: $e");
    }
  }*/

  // Obtenir la ubicació actual de l'usuari
  Future<void> fetchUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        userLocation.value = LatLng(position.latitude, position.longitude);
      }
    } catch (e) {
      print("Error obtenint la ubicació de l'usuari: $e");
    }
  }


}