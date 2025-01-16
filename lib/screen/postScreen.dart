import 'package:flutter/material.dart';
import 'package:flutter_application_1/controllers/postsListController.dart';
import 'package:flutter_application_1/controllers/postController.dart';
import 'package:flutter_application_1/Widgets/postCard.dart';
import 'package:get/get.dart';

class PostsScreen extends StatefulWidget {
  @override
  _PostsScreenState createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  final PostController postController = Get.put(PostController());
  final PostsListController postsListController = Get.put(PostsListController());

  String selectedType = 'Todos';

  @override
  void initState() {
    super.initState();
    postsListController.fetchPosts();
  }

  void _filterPostsByType(String type) {
    setState(() {
      selectedType = type;
    });
    if (type == 'Todos') {
      postsListController.fetchPosts();
    } else {
      postController.fetchPostsByType(type);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Foro de Posts'.tr,
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF89AFAF),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String languageCode) {
              if (languageCode == 'ca') {
                Get.updateLocale(Locale('ca', 'ES'));
              } else if (languageCode == 'es') {
                Get.updateLocale(Locale('es', 'ES'));
              } else if (languageCode == 'en') {
                Get.updateLocale(Locale('en', 'US'));
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(value: 'ca', child: Text('Català')),
                PopupMenuItem(value: 'es', child: Text('Español')),
                PopupMenuItem(value: 'en', child: Text('English')),
              ];
            },
          ),
          Container(
            margin: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                _fetchMyPosts();
              },
              icon: const Icon(Icons.account_circle),
              label: Text('Mis Posts'.tr),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                backgroundColor: const Color.fromARGB(187, 255, 255, 255),
                foregroundColor: const Color.fromARGB(255, 84, 91, 111),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0), // Ajustem el padding lateral
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['Todos', 'Película', 'Serie', 'Libro', 'Podcast', 'Música']
                    .map((type) {
                  return Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _filterPostsByType(type);
                      },
                      child: Text(
                        type.tr,
                        style: TextStyle(fontSize: 12), // Font més petit
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedType == type
                            ? const Color.fromRGBO(137, 175, 175, 1)
                            : const Color.fromARGB(255, 178, 178, 178),
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          color: Colors.white,
                        ),
                        padding: EdgeInsets.symmetric(vertical: 8), // Més petit per un botó més compacte
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Obx(() {
                if (postController.isLoading.value) {
                  return Center(child: CircularProgressIndicator());
                } else if (selectedType != 'Todos' && postController.postsByType.isEmpty) {
                  return Center(
                    child: Text(
                      "No hay posts disponibles para esta categoría".tr,
                      style: TextStyle(fontSize: 16, color: Color(0xFF89AFAF)),
                    ),
                  );
                } else if (selectedType == 'Todos' && postsListController.postList.isEmpty) {
                  return Center(
                    child: Text(
                      "No hay posts disponibles".tr,
                      style: TextStyle(fontSize: 16, color: Color(0xFF89AFAF)),
                    ),
                  );
                } else {
                  var postsToDisplay = selectedType == 'Todos'
                      ? postsListController.postList
                      : postController.postsByType;
                  return Expanded(
                    child: ListView.builder(
                      itemCount: postsToDisplay.length,
                      itemBuilder: (context, index) {
                        final post = postsToDisplay[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: PostCard(post: post),
                        );
                      },
                    ),
                  );
                }
              }),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddPostDialog(context);
        },
        backgroundColor: Color(0xFF89AFAF),
        child: Icon(Icons.add),
      ),
    );
  }

  void _fetchMyPosts() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: GetBuilder<PostController>(
            init: postController,
            builder: (controller) {
              return FutureBuilder(
                future: postController.fetchMyPosts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  } else if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Center(
                        child: Text(
                          'Error al cargar los posts: ${snapshot.error}'.tr,
                          style: const TextStyle(fontSize: 16, color: Colors.red),
                        ),
                      ),
                    );
                  } else {
                    final myPosts = snapshot.data ?? [];
                    return Container(
                      padding: const EdgeInsets.all(16.0),
                      width: MediaQuery.of(context).size.width * 0.6,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mis Posts'.tr,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF89AFAF),
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (myPosts.isEmpty)
                            Center(
                              child: Text(
                                "No tienes posts todavía.".tr,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF89AFAF),
                                ),
                              ),
                            )
                          else
                            Expanded(
                              child: ListView.builder(
                                itemCount: myPosts.length,
                                itemBuilder: (context, index) {
                                  final post = myPosts[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: PostCard(post: post),
                                  );
                                },
                              ),
                            ),
                          const SizedBox(height: 20),
                          Center(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF89AFAF),
                              ),
                              child: Text('Cerrar'.tr),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                },
              );
            },
          ),
        );
      },
    );
  }


  // Mostrar el cuadro de diálogo para crear un nuevo post
  void _showAddPostDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return GetBuilder<PostController>(
          builder: (postController) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          'Nuevo Post'.tr,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF89AFAF),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Campo para el autor (owner)
                      TextField(
                        controller: postController.ownerController,
                        decoration: InputDecoration(
                          labelText: 'Autor'.tr,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Campo para la descripción
                      TextField(
                        controller: postController.descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Descripción'.tr,
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      // Campo para el tipo de post (Dropdown)
                      // Dropdown para seleccionar el tipo de post
                      Obx(() {
                        return DropdownButton<String>(
                          value: postController.postType.value.isEmpty ? null : postController.postType.value,
                          hint: Text(
                            'Selecciona el tipo de post'.tr,
                            style: TextStyle(color: Color(0xFF89AFAF)),
                          ),
                          onChanged: (String? newValue) {
                            postController.postType.value = newValue ?? '';
                          },
                          items: <String>['', 'Libro'.tr, 'Película'.tr, 'Música'.tr, 'Serie'.tr, 'Otro'.tr]
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value.tr),
                            );
                          }).toList(),
                          dropdownColor: Colors.white,  // Fondo blanco para el dropdown
                          underline: Container(),  // Eliminar línea de subrayado
                        );
                      }),
                      const SizedBox(height: 16),
                      // Botón para seleccionar imagen
                      ElevatedButton(
                        onPressed: () async {
                          await postController.pickImage();
                        },
                        child: Text('Seleccionar Imagen'.tr),
                      ),
                      const SizedBox(height: 16),
                      // Vista previa de la imagen seleccionada
                      if (postController.selectedImage != null)
                        Center(
                          child: Image.memory(
                            postController.selectedImage!,
                            height: 150,
                            width: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                      const SizedBox(height: 20),
                      // Botón para guardar el post
                      Center(
                        child: ElevatedButton(
                          onPressed: () async {
                            // Llamar al método para crear el post
                            postController.createPost();
                            postsListController.fetchPosts(); 
                            Navigator.of(context).pop();  // Cerrar el cuadro de diálogo después de crear el post
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF89AFAF),
                          ),
                          child: Text('Crear Post'.tr),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}