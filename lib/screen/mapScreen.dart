//V1.2

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_application_1/controllers/ubiController.dart';
import 'package:flutter_application_1/controllers/ubiListController.dart';
import 'package:flutter_application_1/Widgets/ubiCard.dart';
import 'package:geolocator/geolocator.dart'; // Paquete para geolocalización
import 'package:flutter_application_1/controllers/themeController.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final UbiController ubiController = Get.put(UbiController());
  final UbiListController ubiListController = Get.put(UbiListController());
  String selectedType = 'Todos';
  
  double? userLatitude;
  double? userLongitude;

  double? homeLatitude;
  double? homeLongitude;

  @override
  void initState() {
    super.initState();
    _getUserLocation(); // Obtener la ubicación del usuario al entrar al mapa
    _loadHomeLocation();
    // Inicializar selectedType en el controlador 
    WidgetsBinding.instance.addPostFrameCallback((_) { ubiController.selectedType.value = 'Todos'; ubiController.fetchUbis(); });// Cargar todas las ubicaciones al iniciar });
  }

  // Funció per obtenir la ubicació de la casa de l'usuari
  Future<void> _loadHomeLocation() async {
    try {
      final coordinates = await ubiController.loadUserAddress();

      homeLatitude = coordinates['latitude'];
      homeLongitude = coordinates['longitude'];

      setState(() {});
      print('Ubicació de la casa: Lat: $homeLatitude, Lon: $homeLongitude');
    } catch (e) {
      print('Error al obtenir la ubicació de la casa: $e');
    }
  }

  // Función para obtener la ubicación del usuario
  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verificar si los servicios de ubicación están habilitados
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Los servicios de ubicación no están habilitados.");
      return;
    }

    // Verificar si se tiene permiso para acceder a la ubicación
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("Permiso de ubicación denegado.");
        return;
      }
    }

    // Obtener la ubicación actual del usuario
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        userLatitude = position.latitude;
        userLongitude = position.longitude;
      });

      // Llamamos a la función para obtener las ubicaciones cercanas
      if (userLatitude != null && userLongitude != null) {
        await ubiListController.getNearbyUbis(userLatitude!, userLongitude!, 10); // Buscar ubicaciones cercanas a 10 km de distancia
      }

      // Añadir el marcador en el mapa
      if (userLatitude != null && userLongitude != null) {
        final userMarker = Marker(
          point: LatLng(userLatitude!, userLongitude!),
          builder: (ctx) => const Icon(
            Icons.location_on,
            color: Colors.red, // Color rojo para la ubicación del usuario
            size: 38.0,
          ),
        );

        print("Marcador añadido en la ubicación del usuario.");
      }
    } catch (e) {
      print("Error al obtener la ubicación: $e");
    }
  }


// Funció per filtrar ubicacions segons tipus
void _filterLocationsByType(String type) {
  setState(() {
    selectedType = type; // Actualitza la variable per filtrar
    if (type == 'Todos') {
      ubiController.fetchUbis(); // Mostra totes les ubicacions
    } else {
      ubiController.fetchUbisByType(type); // Filtra les ubicacions segons el tipus seleccionat
    }
  });
}

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(
            kToolbarHeight), // Usamos el tamaño predeterminado del AppBar
        child: Obx(() {
          return AppBar(
            title: Text('Mapa'.tr, // Traducción dinámica
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), // Tamaño y estilo fijo del texto
            backgroundColor: themeController.isDarkMode.value
                ? Color(0xFF555A6F) // Color para el modo oscuro
                : Color(0xFF89AFAF), // Color para el modo claro
            toolbarHeight: 70.0, // Altura fija del AppBar
            actions: [
              IconButton(
                icon: Icon(Icons.brightness_6),
                onPressed: () {
                  themeController.toggleTheme(); // Cambiar tema
                },
                color: Colors
                    .white, // El color debe coincidir con el estilo del tema
              ),
              PopupMenuButton<String>( // Menú para cambio de idioma
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
            ],
          );
        }),
      ),
      body: Obx(() {
        bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

        if (ubiController.isLoading.value || ubiController.isLoadingByType.value) {
          return Center(child: CircularProgressIndicator());
        }

        if (ubiController.ubis.isEmpty) {
          return Center(child: Text('No hay ubicaciones disponibles'.tr));
        }

        return Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                center: userLatitude != null && userLongitude != null
                    ? LatLng(userLatitude!, userLongitude!)
                    : LatLng(41.382395521312176, 2.1567611541534366),
                zoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: isDarkMode
                      ? "https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
                      : "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: [

                    // Marcador de la ubicación del usuario (en rojo)
                    if (userLatitude != null && userLongitude != null)
                      Marker(
                        point: LatLng(userLatitude!, userLongitude!),
                        builder: (ctx) => const Icon(
                          Icons.location_on,
                          color: Colors
                              .red, // Color rojo para la ubicación del usuario
                          size: 38.0,
                        ),
                      ),

                    // Marcador de la casa del usuario (en azul)
                    if (homeLatitude != null && homeLongitude != null)
                      Marker(
                        point: LatLng(homeLatitude!, homeLongitude!),
                        builder: (ctx) => const Icon(
                          Icons.home,
                          color: Color.fromARGB(255, 103, 158, 132), // Color azul para la casa
                          size: 38.0,
                        ),
                      ),
                      //Marcador de todos
                    if(ubiController.selectedType.value == 'Todos')
// Otros marcadores para las ubicaciones
                    ...ubiController.ubis.map((ubi) {
                      final latitude =
                          ubi.ubication.latitud ?? 41.382395521312176;
                      final longitude =
                          ubi.ubication.longitud ?? 2.1567611541534366;
                    
                      return Marker(
                        point: LatLng(latitude, longitude),
                        builder: (ctx) => GestureDetector(
                          onTap: () {
                            ubiController.selectUbi(ubi);
                          },
                          child: const Icon(
                            Icons.place,
                            color: Color.fromARGB(255, 84, 91, 111),
                            size: 38.0,
                          ),
                        ),
                    );
                    }).toList(),

                    if(ubiController.selectedType.value != 'Todos')
                      // Otros marcadores para las ubicaciones
                    ...ubiController.ubisByType.map((ubi) {
                      final latitude = ubi.ubication.latitud ?? 41.382395521312176;
                      final longitude = ubi.ubication.longitud ?? 2.1567611541534366;

                      return Marker(
                        point: LatLng(latitude, longitude),
                        builder: (ctx) => GestureDetector(
                          onTap: () {
                            ubiController.selectUbi(ubi);
                          },
                          child: const Icon(
                            Icons.place,
                            color: Color.fromARGB(255, 84, 91, 111),
                            size: 38.0,
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ],
            ),

          // Barra de filtros
          Positioned(
            top: 30,
            left: 8,
            right: 8,
            child: Container(
              //height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              decoration: BoxDecoration(
                color: const Color.fromARGB(0, 255, 255, 255),
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(0, 158, 158, 158),
                    spreadRadius: 2,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Wrap(
                spacing: 100.0, // Espacio entre los botones
                runSpacing: 10.0, // Espacio entre las filas si los botones se dividen
                alignment: WrapAlignment.center, // Alinea los botones al centro
                
                children: ['Punto lila' .tr, 'Hospital' .tr, 'Centro' .tr, 'Otros' .tr, 'Todos' .tr]
                    .map((type) {
                  return ElevatedButton(
                    onPressed: () {
                      selectedType = type;
                      _filterLocationsByType(type);
                      
                    },
                    child: Text(type.tr),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedType == type
                          ? const Color(0xFF89AFAF)
                          : const Color.fromARGB(255, 178, 178, 178),
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(color: Colors.white),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
            // Elementos adicionales, como el título y las ubicaciones cercanas
            Positioned(
              top: 8, 
              right: 27, 
              child: Container(
                width: 290, 
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(191, 255, 255, 255), 
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: Color.fromARGB(255, 84, 91, 111), width: 1.5), 
                ),
                child: Center(
                  child: Text(
                    'Puntos cercanos a ti'.tr,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 84, 91, 111),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 58,
              right: 10,
              child: Container(
                width: 320, 
                height: 450, 
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Obx(() {
                        return ListView.builder(
                          controller: ubiListController.scrollController,
                          itemCount: ubiListController.ubis.length + 1,
                          itemBuilder: (context, index) {
                            if (index == ubiListController.ubis.length) {
                              return ubiListController.isLoading.value
                                  ? const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 16.0),
                                      child: Center(child: CircularProgressIndicator()),
                                    )
                                  : const SizedBox.shrink();
                            } else {
                              var ubi = ubiListController.ubis[index];
                              return UbiCard(ubi: ubi);
                            }
                          },
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
            // Card de la información de los puntos de ubicación
            Obx(() {
              final selectedUbi = ubiController.selectedUbi.value;
              if (selectedUbi != null) {
                return Positioned(
                  top: 7,
                  right: 323,
                  child: Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Container(
                      padding: EdgeInsets.all(10),
                      width: 250,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${selectedUbi.name}',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: Icon(Icons.close, color: Colors.red),
                                iconSize: 20,
                                onPressed: () {
                                  ubiController.selectedUbi.value = null;
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 5),
                          Text('· Dirección: ${selectedUbi.address}'.tr),
                          SizedBox(height: 5),
                          if (selectedUbi.tipo=='P')
                          Text('· Tipo: Punto lila'.tr),
                          if (selectedUbi.tipo=='H')
                          Text('· Tipo: Hospital'.tr),
                          if (selectedUbi.tipo=='C')
                          Text('· Tipo: Centro'.tr),
                          if (selectedUbi.tipo=='O')
                          Text('· Tipo: Otro'.tr),
                          SizedBox(height: 5),
                          Text('· Comentario: ${selectedUbi.comentari}'.tr),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return Container();
            }),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddUbiDialog(context);
        },
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800] // Color para modo oscuro
            : Color(0xFF89AFAF), // Color para modo claro
        child: Icon(
          Icons.add,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white // Ícono blanco en modo oscuro
              : Colors.black, // Ícono negro en modo claro
        ),
      ),
    );
  }

   void _showAddUbiDialog(BuildContext context) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                   // const Center(
                     Text(
                        'Nueva ubicación'.tr,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF89AFAF),
                        ),
                      ),
                    //),
                    const SizedBox(height: 20),
                    TextField(
                      controller: ubiController.nameController,
                      decoration: InputDecoration(
                        labelText: 'Nombre'.tr,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: ubiController.addressController,
                      decoration: InputDecoration(
                        labelText: 'Dirección (calle, número de portería, localidad)'.tr,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: ubiController.horariController,
                      decoration: InputDecoration(
                        labelText: 'Horario'.tr,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: ubiController.tipoController.text.isEmpty ? null : ubiController.tipoController.text,
                      decoration: InputDecoration(
                        labelText: 'Tipo'.tr,
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(value: 'Hospital', child: Text('Hospital')),
                        DropdownMenuItem(value: 'Punto lila', child: Text('Punto lila')),
                        DropdownMenuItem(value: 'Centro', child: Text('Centro')),
                        DropdownMenuItem(value: 'Otros', child: Text('Otros')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          ubiController.tipoController.text = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: ubiController.comentariController,
                      decoration: InputDecoration(
                        labelText: 'Comentario'.tr,
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: () async {
                        //ubiController.getCoordinatesFromAddress(ubiController.addressController.text);
                          await ubiController.createUbi();  // Llamar a la función de creación
                          Navigator.of(context).pop();  // Cerrar el diálogo después de crear
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[800] // Color para modo oscuro
                                : Color(0xFF89AFAF), // Color para modo claro
                        foregroundColor: Theme.of(context).brightness ==
                                Brightness.dark
                            ? Colors.white // Texto en blanco para modo oscuro
                            : Colors.black, // Texto en negro para modo claro
                        ),
                        child: Text(
                        'Crear ubicación'.tr,
                         style: TextStyle(color: Colors.white), // Texto en blanco
                      ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
      },
    );
  }
}
