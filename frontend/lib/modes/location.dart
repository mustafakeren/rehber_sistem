import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  State<LocationPage> createState() {
    return _LocationPageState();
  }
}

class _LocationPageState extends State<LocationPage> {
  Location? _pickedLocation;
  var _isGettingLocation = false;
  late GoogleMapController _mapController;
  LatLng _currentPosition = LatLng(0.0, 0.0); // Başlangıçta 0,0 koordinatını ayarlıyoruz

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // Harita ilk açıldığında konum almak için bu fonksiyonu çağırıyoruz.
  }

  void _getCurrentLocation() async {
    Location location = Location();

    bool serviceEnabled;
    PermissionStatus permissionGranted;
    LocationData locationData;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    setState(() {
      _isGettingLocation = true;
    });

    locationData = await location.getLocation();
    final lat = locationData.latitude!;
    final lng = locationData.longitude!;

    print('Current location: ($lat, $lng)'); // Debug print

    // Geocode API ile adres alma
    final url = Uri.parse('https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=AIzaSyBzgLjpSxe5KosFZGl-h-9kcuZQZJbZ1gw');
    final response = await http.get(url);
    final resData = json.decode(response.body);
    final address = resData['results'][0]['formatted_address'];

    setState(() {
      _isGettingLocation = false;
      _currentPosition = LatLng(lat, lng);
    });

    print('Updated map position: ($_currentPosition.latitude, $_currentPosition.longitude)'); // Debug print

    // Harita konumunu güncelle
    _mapController.animateCamera(CameraUpdate.newLatLng(_currentPosition));
  }

  @override
  Widget build(BuildContext context) {
    Widget previewContent = Text(
      'No location selected yet',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );

    if (_isGettingLocation) {
      previewContent = const CircularProgressIndicator();
    }

    return GestureDetector(
      onDoubleTap: () {
        Navigator.pop(context);
      },
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            previewContent,
            SizedBox(
              height: 400,
              width: double.infinity,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentPosition,
                  zoom: 15,
                ),
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                },
                markers: {
                  Marker(
                    markerId: MarkerId('current_location'),
                    position: _currentPosition,
                  ),
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.location_on),
                  label: const Text('Get Current Location'),
                  onPressed: _getCurrentLocation,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}