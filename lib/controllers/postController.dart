import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/models/post.dart';
import 'package:flutter_application_1/services/postServices.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
//import 'package:image_picker_web/image_picker_web.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart'; // Para Android/iOS

class PostController extends GetxController {
  final PostService postService = Get.put(PostService());
  final TextEditingController ownerController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  var postType = ''.obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var postsByType = <PostModel>[].obs;  // Nova variable per guardar els posts filtrats

  @override
  void onInit() {
    super.onInit();
    _loadUsername();  // Cargar el username cuando se inicializa el controlador
  }

  // Método para cargar el username desde SharedPreferences
  void _loadUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = prefs.getString('username') ?? '';  // Recupera el username o un string vacío
    ownerController.text = username;  // Rellenar el campo de autor
  }

  Uint8List? selectedImage; // Bytes de la imagen seleccionada
  var uploadedImageUrl = ''.obs; // URL de la imagen subida a Cloudinary

// Seleccionar imagen desde el dispositivo o navegador
Future<void> pickImage() async {
  try {
    Uint8List? imageBytes;
    
    if (kIsWeb) {
      // Código para la web
      //imageBytes = await ImagePickerWeb.getImageAsBytes();
    } else {
      // Código para móvil
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        imageBytes = await pickedFile.readAsBytes();
      }
    }

    if (imageBytes != null) {
      selectedImage = imageBytes;
      uploadedImageUrl.value = ''; // Reinicia la URL de Cloudinary
      update(); // Actualiza la UI
      Get.snackbar('Éxito', 'Imagen seleccionada correctamente');
    }
  } catch (e) {
    Get.snackbar('Error', 'No se pudo seleccionar la imagen: $e',
        snackPosition: SnackPosition.BOTTOM);
  }
}

  // Subir imagen a Cloudinary
  Future<void> uploadImageToCloudinary() async {
    if (selectedImage == null) {
      Get.snackbar('Error', 'Selecciona una imagen primero',
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
        Get.snackbar('Éxito', 'Imagen subida correctamente');
      } else {
        Get.snackbar('Error', 'Falló la subida de la imagen',
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('Error', 'Error al subir la imagen: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  // Mapeig entre categories i els seus codis
  final Map<String, String> categoryCodes = {
    'Película': 'P',
    'Libro': 'L',
    'Serie': 'S',
    'Música': 'M',
    'Podcast': 'Pod',
    'Otro': 'O',
  };

  // Funció per traduir la categoria seleccionada al codi
  String getCategoryCode(String category) {
    return categoryCodes[category] ?? 'O'; // Per defecte "O" (Otro)
  }

  // Crear un nuevo post
  void createPost() async {
    if (ownerController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        postType.value.isEmpty) {
      Get.snackbar('Error', 'Todos los campos son obligatorios',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // Si la imagen no se ha subido, subirla primero
    if (uploadedImageUrl.isEmpty && selectedImage != null) {
      await uploadImageToCloudinary();
    }

    // Verifica si la imagen fue subida con éxito
    if (uploadedImageUrl.value.isEmpty) {
      Get.snackbar('Error', 'La imagen no se subió correctamente.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // Tradueix el tipus de post al codi correcte abans d’enviar
    String translatedPostType = getCategoryCode(postType.value);
    print("Aquest es el codi per la categoria del post:" + translatedPostType);

    final newPost = PostModel.fromJson({
      'author': ownerController.text,
      'postType': translatedPostType,
      'content': descriptionController.text,
      'image': uploadedImageUrl.value,
      'postDate': DateTime.now().toIso8601String(),
    });

    isLoading.value = true;
    errorMessage.value = '';
    try {
      final statusCode = await postService.createPost(newPost);
      if (statusCode == 201) {
        Get.snackbar('Éxito', 'Post creado con éxito');
        Get.toNamed('/posts');
      } else {
        errorMessage.value = 'Error al crear el post';
      }
    } catch (e) {
      errorMessage.value = 'Error: No se pudo conectar con la API';
    } finally {
      isLoading.value = false;
    }
  }

  void clearFields() {
    descriptionController.clear();
    postType.value = ''; // Limpiar el tipo de post
    uploadedImageUrl.value = ''; // Limpiar la URL de la imagen
    selectedImage = null; // Limpiar la imagen seleccionada
  }

  // Método para obtener los posts del usuario actual
  Future<List<PostModel>> fetchMyPosts() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String username = prefs.getString('username') ?? '';

      if (username.isEmpty) {
        throw Exception('No se pudo recuperar el nombre de usuario.');
      }

      final myPosts = await postService.getPostsByAuthor(username);
      return myPosts;
    } catch (e) {
      throw Exception('Error al obtener los posts: $e');
    }
  }

  // Afegir la funció per obtenir els posts filtrats per tipus
  void fetchPostsByType(String type) async {
    isLoading.value = true;
    
    // Tradueix el tipus de post al codi correcte abans d’enviar
    String translatedPostType = getCategoryCode(type);
    try {
      var posts = await postService.getPostsByType(translatedPostType);
      postsByType.assignAll(posts);
    } finally {
      isLoading.value = false;
    }
  }
}
