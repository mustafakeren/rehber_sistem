import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:math' show asin, atan2, cos, pi, sin, sqrt;

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

  // List of places with their coordinates and messages
  final List<Map<String, dynamic>> places = [
    {
      "name": "Faculty of Engineering",
      "coordinates": LatLng(39.890437801682175, 32.65820345375549),
      "message": "Mühendislik fakültesine yakınsınız"
    },
    {
      "name": "Library",
      "coordinates": LatLng(39.887469, 32.657175),
      "message": "Kütüphaneye yakınsınız"
    },
    {
      "name": "Foreign Languages ​​Building",
      "coordinates": LatLng(39.888294, 32.655490),
      "message": "Yabancı diller binasına yakınsınız"
    },
    {
      "name": "Bus Stops",
      "coordinates": LatLng(39.890264, 32.653754),
      "message": "Otobüs duraklarına yakınsınız"
    },
    {
      "name": "Faculty of Fine Arts",
      "coordinates": LatLng(39.888315, 32.653456),
      "message": "Güzel sanatlar fakültesine yakınsınız"
    },
    {
      "name": "Faculty of Dentistry",
      "coordinates": LatLng(39.888177, 32.651295),
      "message": "Diş Hekimliği fakültesine yakınsınız"
    },
    {
      "name": "Faculty of Medicine and Pharmacy",
      "coordinates": LatLng(39.887636, 32.652367),
      "message": "Tıp ve Eczacılık fakültesine yakınsınız"
    },
    {
      "name": "Faculty of Education",
      "coordinates": LatLng(39.887093, 32.651729),
      "message": "Eğitim fakültesine yakınsınız"
    },
    {
      "name": "Faculty of Law and Communication",
      "coordinates": LatLng(39.886348, 32.653399),
      "message": "Hukuk ve İletişim fakültesine yakınsınız. Öğrenci işleri binasına da buradan ulaşabilirsiniz."
    },
    {
      "name": "Rectorship Building",
      "coordinates": LatLng(39.88604471325193, 32.65204374564296),
      "message": "Rektörlük binasına yakınsınız."
    }
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _listenToCompass();
  }

  void _listenToCompass() {
    FlutterCompass.events?.listen((event) {
      setState(() {
        userHeading = event.heading; // Update user's heading
      });
    });
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
          currentLocation!.latitude!, currentLocation!.longitude!);
      print(
          "Coordinates: Latitude: ${currentLocation!.latitude}, Longitude: ${currentLocation!.longitude}");
    }
    setState(() {});
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Pi/180
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)) * 1000; // 2 * R; R = 6371 km
  }

  String _getRelativeDirection(
      double userLat, double userLon, double placeLat, double placeLon) {
    if (userHeading == null) return "bilinmeyen";

    // Calculate the bearing to the place
    double bearing = _calculateBearing(userLat, userLon, placeLat, placeLon);

    // Calculate the relative direction
    double relativeBearing = (bearing - userHeading!) % 360;
    if (relativeBearing < 0) relativeBearing += 360;

    if (relativeBearing >= 315 || relativeBearing < 45) {
      return "önünüzde";
    } else if (relativeBearing >= 45 && relativeBearing < 135) {
      return "sağınızda";
    } else if (relativeBearing >= 135 && relativeBearing < 225) {
      return "arkanızda";
    } else {
      return "solunuzda";
    }
  }

  double _calculateBearing(
      double lat1, double lon1, double lat2, double lon2) {
    double dLon = (lon2 - lon1) * pi / 180;
    double y = sin(dLon) * cos(lat2 * pi / 180);
    double x = cos(lat1 * pi / 180) * sin(lat2 * pi / 180) -
        sin(lat1 * pi / 180) * cos(lat2 * pi / 180) * cos(dLon);
    double bearing = atan2(y, x) * 180 / pi;
    return (bearing + 360) % 360; 
  }

  void _getAddressFromLatLng(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
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
        child: currentLocation == null
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(currentLocation!.latitude!,
                          currentLocation!.longitude!),
                      zoom: 15,
                    ),
                    onMapCreated: (GoogleMapController controller) {
                      mapController = controller;
                    },
                    markers: {
                      Marker(
                        markerId: MarkerId('currentLocation'),
                        position: LatLng(currentLocation!.latitude!,
                            currentLocation!.longitude!),
                        infoWindow: InfoWindow(
                          title: 'Current Location',
                          snippet: countryName,
                        ),
                      ),
                      ...places.map((place) {
                        return Marker(
                          markerId: MarkerId(place["name"]),
                          position: place["coordinates"],
                          infoWindow: InfoWindow(
                            title: place["name"],
                          ),
                        );
                      }).toSet(),
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
                              fontSize: 20, fontWeight: FontWeight.bold),
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
}