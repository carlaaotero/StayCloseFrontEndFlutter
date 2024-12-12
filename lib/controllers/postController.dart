import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/models/post.dart';
import 'package:flutter_application_1/services/postServices.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'package:image_picker_web/image_picker_web.dart';

class PostController extends GetxController {
  final PostService postService = Get.put(PostService());
  final TextEditingController ownerController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  var postType = ''.obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUsername();  // Carregar el username quan s'inicialitza el controlador
  }


  // Mètode per carregar l'username des de SharedPreferences
  void _loadUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = prefs.getString('username') ?? '';  // Recupera l'username o un string buit
    ownerController.text = username;  // Omplir el camp d'autor
  }

  // Mètode per crear un nou post
  Uint8List? selectedImage; // Bytes de la imatge seleccionada
  var uploadedImageUrl = ''.obs; // URL de la imatge pujada a Cloudinary

  // Seleccionar imatge des del dispositiu
  Future<void> pickImage() async {
    try {
      Uint8List? imageBytes = await ImagePickerWeb.getImageAsBytes();
      if (imageBytes != null) {
        selectedImage = imageBytes;
        uploadedImageUrl.value = ''; // Reinicia la URL de Cloudinary
        update(); // Actualitza la UI
        Get.snackbar('Èxit', 'Imatge seleccionada correctament');
      }
    } catch (e) {
      Get.snackbar('Error', 'No s\'ha pogut seleccionar la imatge: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  // Pujar imatge a Cloudinary
  Future<void> uploadImageToCloudinary() async {
    if (selectedImage == null) {
      Get.snackbar('Error', 'Selecciona una imatge primer',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      isLoading.value = true;
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/djen7vqby/image/upload'),
      );
      request.fields['upload_preset'] = 'nm1eu9ik';
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          selectedImage!,
          filename: 'image_${DateTime.now().millisecondsSinceEpoch}.png',
        ),
      );
      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var data = jsonDecode(responseData);
        uploadedImageUrl.value = data['secure_url'];
        Get.snackbar('Èxit', 'Imatge pujada correctament');
      } else {
        Get.snackbar('Error', 'Ha fallat la pujada de la imatge',
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('Error', 'Error al pujar la imatge: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  // Crear un nou post
  void createPost() async {
    if (ownerController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        postType.value.isEmpty) {
      Get.snackbar('Error', 'Tots els camps són obligatoris',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // Si la imatge no s'ha pujat, pujar-la primer
    if (uploadedImageUrl.isEmpty && selectedImage != null) {
      await uploadImageToCloudinary();
    }

    // Verifica si la imatge ha sigut pujada amb èxit
    if (uploadedImageUrl.value.isEmpty) {
      Get.snackbar('Error', 'La imatge no s\'ha pujat correctament.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final newPost = PostModel.fromJson({
      'author': ownerController.text,
      'postType': postType.value,
      'content': descriptionController.text,
      'image': uploadedImageUrl.value,
      'postDate': DateTime.now().toIso8601String(),
    });

    isLoading.value = true;
    errorMessage.value = '';
    try {
      final statusCode = await postService.createPost(newPost);
      if (statusCode == 201) {
        Get.snackbar('Èxit', 'Post creat amb èxit');
        Get.toNamed('/posts');
      } else {
        errorMessage.value = 'Error al crear el post';
      }
    } catch (e) {
      errorMessage.value = 'Error: No s\'ha pogut connectar amb l\'API';
    } finally {
      isLoading.value = false;
    }

  }
}