import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_application_1/controllers/ubiController.dart';
import 'package:flutter_application_1/models/ubi.dart';

class MapScreen extends StatelessWidget {
  final UbiController ubiController = Get.put(UbiController());
  Rx<UbiModel?> hoveredUbi = Rx<UbiModel?>(null); // Per mostrar detalls d'un únic marcador

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa'),
        backgroundColor: const Color(0xFF89AFAF),
      ),
      body: Obx(() {
        if (ubiController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (ubiController.ubis.isEmpty) {
          return const Center(child: Text('No hi ha ubicacions disponibles'));
        }

        return Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                center: ubiController.userLocation.value ??
                    LatLng(41.382395521312176, 2.1567611541534366),
                zoom: 13.0,
                onPositionChanged: (position, hasGesture) {
                  // Reinicialitzar l'element "hoveredUbi" quan es mogui el mapa
                  if (hasGesture) {
                    hoveredUbi.value = null;
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: ubiController.ubis.map((ubi) {
                    final latitude =
                        ubi.ubication['latitud'] ?? 41.382395521312176;
                    final longitude =
                        ubi.ubication['longitud'] ?? 2.1567611541534366;

                    return Marker(
                      key: ValueKey('${ubi.ubication['latitud']}_${ubi.ubication['longitud']}'),
                      point: LatLng(latitude, longitude),
                      builder: (ctx) => MouseRegion(
                        onEnter: (_) => hoveredUbi.value = ubi,
                        onExit: (_) => hoveredUbi.value = null,
                        child: Icon(
                          Icons.place,
                          color: const Color.fromARGB(255, 133, 160, 160),
                          size: 35.0,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                // Cercle per la ubicació de l'usuari
                if (ubiController.userLocation.value != null)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: ubiController.userLocation.value!,
                        color: Colors.purple.withOpacity(0.7),
                        radius: 10.0,
                      ),
                    ],
                  ),
              ],
            ),

            // Mostra una caixa amb els detalls de la ubicació seleccionada amb "hover"
            Obx(() {
              final ubi = hoveredUbi.value;
              if (ubi == null) return const SizedBox.shrink();
              return Positioned(
                left: 16.0,
                top: 16.0,
                child: Container(
                  width: 220.0,
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB2D5D5),
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6.0,
                        offset: const Offset(3, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detalls',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nom: ${ubi.name}',
                        style:
                            const TextStyle(fontSize: 14, color: Colors.black),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tipus: ${ubi.tipo}',
                        style:
                            const TextStyle(fontSize: 14, color: Colors.black),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Horari: ${ubi.horari}',
                        style:
                            const TextStyle(fontSize: 14, color: Colors.black),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Adreça: ${ubi.address}',
                        style:
                            const TextStyle(fontSize: 14, color: Colors.black),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Comentari: ${ubi.comentari}',
                        style:
                            const TextStyle(fontSize: 14, color: Colors.black),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddUbiDialog(context);
        },
        backgroundColor: const Color(0xFF89AFAF),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddUbiDialog(BuildContext context) {
    // Funció per afegir una ubicació
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
                  const Center(
                    child: Text(
                      'Nova Ubicació',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF89AFAF),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: ubiController.nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: ubiController.addressController,
                    decoration: const InputDecoration(
                      labelText: 'Adreça',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: ubiController.horariController,
                    decoration: const InputDecoration(
                      labelText: 'Horari',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: ubiController.tipoController,
                    decoration: const InputDecoration(
                      labelText: 'Tipus',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: ubiController.comentariController,
                    decoration: const InputDecoration(
                      labelText: 'Comentari',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: ubiController.latitudeController,
                    decoration: const InputDecoration(
                      labelText: 'Latitud',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: ubiController.longitudeController,
                    decoration: const InputDecoration(
                      labelText: 'Longitud',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: ElevatedButton(
                      onPressed: () {
                        ubiController.createUbi();
                        Navigator.pop(context);
                      },
                      child: const Text('Afegir'),
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
