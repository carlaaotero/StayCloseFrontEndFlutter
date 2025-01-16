import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Añadido para traducción
import '../models/post.dart'; 

class PostCard extends StatelessWidget {
  final PostModel post;

  PostCard({
    Key? key,
    required this.post,
  }) : super(key: key);

  // Mapa de traducció de categories
  final Map<String, String> categoryTranslations = {
    'P': 'Película',
    'L': 'Libro',
    'S': 'Serie',
    'M': 'Música',
    'Pod': 'Podcast',
    'O': 'Otro',
  };

  // Métode per obtenir la descripció completa de la categoria
  String getCategoryDescription(String code) {
    return categoryTranslations[code] ?? 'Otro'; // Per defecte "Otro"
  }

  // Método para determinar el color del círculo según el tipo de publicación
  Color _getPostTypeColor(String postType) {
    switch (postType) {
      case 'P':
        return const Color(0xFF002F49); // Azul
      case 'L':
        return const Color(0xFF002F49); // Naranja suave
      case 'S':
        return const Color(0xFF002F49); // Verde suave
      case 'M':
        return const Color(0xFF002F49); // Gris
      case 'Pod':
        return const Color(0xFF002F49); // Gris
      default:
        return const Color(0xFF002F49); // Gris por defecto
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8), // Mayor margen horizontal
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      color: const Color(0xFF89AFAF), // Fondo verde claro
      elevation: 5, // Sombra suave
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.author, // Primer el nombre del usuario
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getPostTypeColor(post.postType),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    getCategoryDescription(post.postType).tr, // Traduir i mostrar el tipus de post
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _getPostTypeColor(post.postType),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  post.content, // Contenido debajo del tipo de post
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          // Imagen al final
          if (post.image != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // Ajustar márgenes
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8), // Esquinas redondeadas
                child: Image.network(
                  post.image!,
                  fit: BoxFit.cover,
                  width: double.infinity, // Ajusta el ancho para ocupar todo el espacio disponible
                  height: 300,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.broken_image,
                    size: 100,
                    color: Color.fromARGB(194, 162, 204, 204),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}