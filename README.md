# FRONTEND STAYCLOSE AMB FLUTTER

- funciona LogIn
 

to execute
- npm install
- flutter pub get
- flutter doctor
- flutter run

# Background Minim2 Carla Abascal
Per implementar aquesta funcionalitat, hem de tenir en compte les dues funcionalitats clau del nostre projecte: la geolocalització en temps real i les notificacions.

- Geolocalització en temps real
Visualitzar la ubicació: Utilitzant els serveis de localització del dispositiu per obtenir coordenades GPS actualitzades.
Compartir la ubicació: Enviar les coordenades actuals a altres usuaris a través del servidor backend mitjançant Web Sockets.

- Notificacions 
Notificar els usuaris de nous missatges o altres activitats de l'App (fòrum o esdeveniments).

Per la Configuració de la funcionalitat en Segon Pla
1. Permisos a AndroidManifest.xml
2. Canal de notificació a MainActivity.kt
3. Inicialitzar el servei del Segon Pla a main.dart


