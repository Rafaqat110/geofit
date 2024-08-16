



import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart' as location;
import 'package:geofence_service/geofence_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'fitness_centers.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  LatLng? _userLocation;
  final Set<Marker> _markers = {};
  String _searchText = '';
  List<FitnessCenter> _filteredCenters = fitnessCenters;
  Set<Polyline> _polylines = {};
  List<FitnessCenter> _suggestedCenters = [];
  bool _directionsRequested = false;

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final GeofenceService _geofenceService = GeofenceService.instance.setup(
    interval: 5000,
    accuracy: 100,
    loiteringDelayMs: 60000,
    statusChangeDelayMs: 10000,
    useActivityRecognition: true,
    allowMockLocations: false,
    printDevLog: false,
    geofenceRadiusSortType: GeofenceRadiusSortType.DESC,
  );

  final List<Geofence> _geofenceList = [
    Geofence(
      id: 'Student Safe Zone',
      latitude: 29.380730448881188,
      longitude: 71.7182007,
      radius: [
        GeofenceRadius(id: 'radius_100m', length: 100),
        GeofenceRadius(id: 'radius_25m', length: 25),
        GeofenceRadius(id: 'radius_250m', length: 250),
        GeofenceRadius(id: 'radius_200m', length: 200),
      ],
    ),
    Geofence(
      id: 'Student Safe Zone',
      latitude: 35.104971,
      longitude: 129.034851,
      radius: [
        GeofenceRadius(id: 'radius_25m', length: 25),
        GeofenceRadius(id: 'radius_100m', length: 100),
        GeofenceRadius(id: 'radius_200m', length: 200),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _initializeNotifications();
    _initializeGeofenceService();



  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'geofence_channel_id',
      'Geofence Notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: 'geofence_payload',
    );
  }

  void _initializeGeofenceService() {
    _geofenceService.addGeofenceStatusChangeListener((geofence, geofenceRadius, geofenceStatus, location) async {
      String status = '';
      if (geofenceStatus == GeofenceStatus.ENTER) {
        status = 'Entered';
        await _showNotification('Geofence Alert', 'You have entered ${geofence.id}');
      } else if (geofenceStatus == GeofenceStatus.EXIT) {
        status = 'Exited';
        await _showNotification('Geofence Alert', 'You have exited ${geofence.id}');
      }
      print('Geofence ${geofence.id} $status');
    });

    _geofenceService.start(_geofenceList).catchError((error) {
      print('Geofence error: $error');
    });
  }

  Future<void> _getUserLocation() async {
    location.Location locationService = location.Location();

    bool _serviceEnabled;
    location.PermissionStatus _permissionGranted;

    _serviceEnabled = await locationService.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await locationService.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await locationService.hasPermission();
    if (_permissionGranted == location.PermissionStatus.denied) {
      _permissionGranted = await locationService.requestPermission();
      if (_permissionGranted != location.PermissionStatus.granted) {
        return;
      }
    }

    location.LocationData locationData = await locationService.getLocation();
    setState(() {
      _userLocation = LatLng(locationData.latitude!, locationData.longitude!);
      _addFitnessCentersMarkers();
    });

    // Ensure the map controller is initialized before calling animateCamera
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_mapController != null && _userLocation != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_userLocation!, 14.0));
      }
    });
  }


  void _addFitnessCentersMarkers() {
    _markers.clear();
    for (var center in _filteredCenters) {
      _markers.add(
        Marker(
          markerId: MarkerId(center.name),
          position: LatLng(center.latitude, center.longitude),
          infoWindow: InfoWindow(
            title: center.name,
            snippet: center.address,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          onTap: () => _onMarkerTapped(center),
        ),
      );
    }
    setState(() {});
  }

  void _moveCameraToLocation(LatLng location) {
    if (_mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(location, 16.0));
    }
  }

  void _onMarkerTapped(FitnessCenter center) async {
    if (_userLocation == null) return;

    _directionsRequested = false;

    _moveCameraToLocation(LatLng(center.latitude, center.longitude));

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(center.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(center.address),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  _directionsRequested = true;
                  List<LatLng> polylineCoordinates = await _getDirections(
                    _userLocation!,
                    LatLng(center.latitude, center.longitude),
                  );

                  setState(() {
                    _polylines.clear();
                    _polylines.add(Polyline(
                      polylineId: PolylineId(center.name),
                      visible: true,
                      points: polylineCoordinates,
                      color: Colors.blue,
                      width: 6,
                    ));
                  });
                },
                child: Text('Get Directions'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<List<LatLng>> _getDirections(LatLng origin, LatLng destination) async {
    final String apiKey = 'AIzaSyC9SFrATkFgXo-sN2cP-zFFi0NrYywjtNw'; // Replace with your API key
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<LatLng> polylineCoordinates = [];

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          String encodedPolyline = data['routes'][0]['overview_polyline']['points'];
          polylineCoordinates = _decodePolyline(encodedPolyline);
        } else {
          print('No routes found in the response data.');
        }

        return polylineCoordinates;
      } else {
        print('Failed to fetch directions: ${response.statusCode}');
        throw Exception('Failed to fetch directions');
      }
    } catch (e) {
      print('Exception occurred: $e');
      throw Exception('Failed to fetch directions');
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      polyline.add(LatLng((lat / 1E5), (lng / 1E5)));
    }

    return polyline;
  }

  void _filterFitnessCenters(String query) {
    setState(() {
      _searchText = query;
      _filteredCenters = fitnessCenters.where((center) {
        return center.name.toLowerCase().contains(query.toLowerCase()) ||
            center.address.toLowerCase().contains(query.toLowerCase());
      }).toList();
      _suggestedCenters = _filteredCenters;
      _addFitnessCentersMarkers();
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GeoFit Training Routes'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search Fitness Centers',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _filterFitnessCenters(value),
            ),
          ),
          _searchText.isNotEmpty
              ? Expanded(
            child: ListView.builder(
              itemCount: _suggestedCenters.length,
              itemBuilder: (context, index) {
                final center = _suggestedCenters[index];
                return ListTile(
                  title: Text(center.name),
                  subtitle: Text(center.address),
                  onTap: () {
                    _moveCameraToLocation(LatLng(center.latitude, center.longitude));
                    setState(() {
                      _searchText = '';
                      _suggestedCenters.clear();
                    });
                    _onMarkerTapped(center);
                  },
                );
              },
            ),
          )
              : Expanded(
            child: GoogleMap(
              onMapCreated: (controller) {
                _mapController = controller;
                if (_userLocation != null) {
                  _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_userLocation!, 14.0));
                }
              },
              initialCameraPosition: CameraPosition(
                target: _userLocation ?? LatLng(35.103422, 129.036023), // Default location
                zoom: 14.0,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              markers: _markers,
              polylines: _polylines,
            ),
          ),
        ],
      ),
    );
  }
}





