import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:math' show cos, sqrt, asin;
import 'dart:async'; // Import for StreamSubscription

class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  _LocationPageState createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  late GoogleMapController mapController;
  loc.LocationData? currentLocation;
  double? userHeading; // User's current heading (compass direction)
  String? countryName;
  final FlutterTts flutterTts = FlutterTts();
  StreamSubscription? _compassSubscription; // Add a subscription variable

  // Define a list of places with their names and coordinates
  final List<Map<String, dynamic>> places = [
    {"name": "Library", "coordinates": LatLng(39.891234, 32.657890)},
    {"name": "Cafeteria", "coordinates": LatLng(39.892345, 32.659012)},
    {"name": "Gym", "coordinates": LatLng(39.893456, 32.660123)},
  ];

  // Coordinates of the Faculty of Engineering at Başkent University
  final LatLng facultyOfEngineering = LatLng(
    39.890437801682175,
    32.65820345375549,
  );

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  void _getCurrentLocation() async {
    loc.Location location = loc.Location();
    currentLocation = await location.getLocation();
    if (currentLocation != null) {
      List<String> messages = [];

      for (var place in places) {
        double distance = _calculateDistance(
          currentLocation!.latitude!,
          currentLocation!.longitude!,
          place["coordinates"].latitude,
          place["coordinates"].longitude,
        );

        if (distance <= 500) {
          String direction = _getRelativeDirection(
            currentLocation!.latitude!,
            currentLocation!.longitude!,
            place["coordinates"].latitude,
            place["coordinates"].longitude,
          );
          messages.add("$direction ${place['name']} bulunuyor.");
        }
      }

      if (messages.isNotEmpty) {
        for (String message in messages) {
          await _speakNotification(message);
        }
      }

      _getAddressFromLatLng(
        currentLocation!.latitude!,
        currentLocation!.longitude!,
      );
      print(
        "Coordinates: Latitude: ${currentLocation!.latitude}, Longitude: ${currentLocation!.longitude}",
      );
    }
    setState(() {});
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = 0.017453292519943295; // Pi/180
    final a =
        0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)) * 1000; // 2 * R; R = 6371 km
  }

  void _getAddressFromLatLng(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          countryName = place.country;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _speakNotification(String message) async {
    await flutterTts.setLanguage("tr-TR");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.speak(message);
  }

  String _getRelativeDirection(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    double deltaLat = lat2 - lat1;
    double deltaLon = lon2 - lon1;

    if (deltaLat.abs() > deltaLon.abs()) {
      return deltaLat > 0 ? "Kuzeyde" : "Güneyde";
    } else {
      return deltaLon > 0 ? "Doğuda" : "Batıda";
    }
  }

  Future<void> _speakLocation() async {
    if (countryName != null) {
      await flutterTts.setLanguage("tr-TR");
      await flutterTts.setSpeechRate(0.5);
      await flutterTts.speak(countryName!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: GestureDetector(
        onDoubleTap: () {
          Navigator.pop(context);
        },
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! < 0) {
            Navigator.pushNamed(context, '/navigation');
          }
        },
        child:
            currentLocation == null
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          currentLocation!.latitude!,
                          currentLocation!.longitude!,
                        ),
                        zoom: 15,
                      ),
                      onMapCreated: (GoogleMapController controller) {
                        mapController = controller;
                      },
                      markers: {
                        Marker(
                          markerId: MarkerId('currentLocation'),
                          position: LatLng(
                            currentLocation!.latitude!,
                            currentLocation!.longitude!,
                          ),
                          infoWindow: InfoWindow(
                            title: 'Current Location',
                            snippet: countryName,
                          ),
                        ),
                        Marker(
                          markerId: MarkerId('facultyOfEngineering'),
                          position: facultyOfEngineering,
                          infoWindow: InfoWindow(
                            title: 'Faculty of Engineering',
                          ),
                        ),
                      },
                    ),
                    if (countryName != null)
                      Positioned(
                        top: 50,
                        left: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          color: Colors.white,
                          child: Text(
                            countryName!,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _speakLocation,
        child: const Icon(Icons.volume_up),
      ),
    );
  }

  @override
  void dispose() {
    _compassSubscription?.cancel(); // Cancel the compass listener
    flutterTts.stop(); // Stop any ongoing TTS
    super.dispose();
  }
}
