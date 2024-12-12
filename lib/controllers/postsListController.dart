import 'package:get/get.dart';
import 'package:flutter_application_1/models/post.dart';
import 'package:flutter_application_1/services/postServices.dart';

class PostsListController extends GetxController {
  var isLoading = true.obs;
  var postList = <PostModel>[].obs;
  final PostService postService = PostService();

  @override
  void onInit() {
    super.onInit();
    fetchPosts();  // Trucada a fetchExperiences al inicialitzar el controlador
  }

  // Mètode per obtenir els posts
  Future<void> fetchPosts() async {
    try {
      isLoading(true); 
      var post = await postService.getPosts();
      
      if (post != null) {
        postList.assignAll(post); // Assignem els posts a la llista
      }
    } catch (e) {
      print("Error fetching experiences: $e");
    } finally {
      isLoading(false); 
    }
  }

  // Mètode per editar un post
  Future<void> editPost(String id, PostModel updatedPost) async {  
    try {
      isLoading(true); 
      var statusCode = await postService.editPost(updatedPost, id);
      if (statusCode == 201) {
        Get.snackbar('Éxito', 'Post actualizado con éxito');
        await fetchPosts();  // Recarreguem la llista de posts desprès d'editar
      } else {
        Get.snackbar('Error', 'Error al actualizar la experiencia');
      }
    } catch (e) {
      print("Error editing experience: $e");
    } finally {
      isLoading(false);  
    }
  }

// Mètode per eliminar un post utilitzant l'ID
Future<void> postToDelete(String postId) async {
  try {
    isLoading(true);  

    // Busquem el pots en la llista local utilitzant l'ID
    var postToDelete = postList.firstWhere(
      (post) => post.id == postId,        
    );

    if (postToDelete != null) {
      // Trucada al servei per elimiar el post utilitzant l'ID
      var statusCode = await postService.deletePostById(postToDelete.id);  

      if (statusCode == 200) {  // Assegurem que el codi sigui 200
        Get.snackbar('Éxito', 'Post eliminado con éxito');
        fetchPosts();  // Recargamos la lista de posts después de eliminar
      } else {
        Get.snackbar('Error', 'Error al eliminar el post');
      }
    } else {
      Get.snackbar('Error', 'No se encontró el post a eliminar');
    }
  } catch (e) {
    print("Error deleting post: $e");
  } finally {
    isLoading(false);  // Establecemos el estado de carga a false una vez que termine
  }
}


}
