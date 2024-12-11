import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'dart:convert'; // For JSON decoding
import 'package:flutter/services.dart'; // For loading asset files
import 'package:latlong2/latlong.dart'; // For LatLng
import 'package:geolocator/geolocator.dart'; // For GPS location

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: Color(0xFF8B1E3F),
        scaffoldBackgroundColor: Color(0xFFF5F0F2),
        textTheme: TextTheme(
          displayLarge: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF8B1E3F)),
          bodyLarge: TextStyle(fontSize: 16, color: Colors.black),
        ),
      ),
      darkTheme: ThemeData.dark(),
      home: HomePage(), // Start with the HomePage
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int? selectedFloor; // Stores the selected floor

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF8B1E3F),
        title: Text('UNI-WAY', style: Theme.of(context).textTheme.displayLarge),
      ),
      body: Column(
        children: [
          SizedBox(height: 20),
          Text(
            "Select Floor",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // Number of columns in the grid
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2, // Adjust to make tiles wider or taller
              ),
              itemCount: 10, // Floors 0 to 9
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedFloor = index;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: selectedFloor == index ? Color(0xFF8B1E3F) : Colors.grey,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        "Floor $index",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: selectedFloor == 3
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MapScreen()),
                    );
                  }
                : null, // Disable button if the selected floor is not 3
            child: Text("Where am I?"),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              backgroundColor:
                  selectedFloor == 3 ? Color(0xFFCA2C5C) : Colors.grey,
              shadowColor: Colors.grey,
              elevation: 8,
              textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? studentLocation;
  final LatLng defaultLocation = LatLng(39.9689266, 32.7435812); // Default to university
  List<dynamic> locations = []; // Store loaded locations
  final double proximityThreshold = 5.0; // Threshold in meters

  @override
  void initState() {
    super.initState();
    _getRealTimeLocation();
    _loadLocations(); // Load the locations from JSON
  }

  Future<void> _loadLocations() async {
    try {
      String data = await rootBundle.loadString('assets/locations.json'); // Load JSON file
      locations = json.decode(data); // Parse the JSON data
      setState(() {}); // Refresh the UI after loading
    } catch (e) {
      print("Error loading locations: $e");
    }
  }

  Future<void> _getRealTimeLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showAlertDialog(
          'Location Disabled',
          'Please enable location services to use this feature.',
        );
        setState(() {
          studentLocation = defaultLocation;
        });
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever) {
          _showAlertDialog(
            'Permission Denied',
            'Location permissions are permanently denied. Please enable them in settings.',
          );
          setState(() {
            studentLocation = defaultLocation;
          });
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        studentLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      _showAlertDialog('Error', 'Failed to fetch location. Using default location.');
      setState(() {
        studentLocation = defaultLocation;
      });
    }
  }

  Map<String, dynamic> findNearestLocation() {
    if (studentLocation == null || locations.isEmpty) {
      return {"name": "Unknown Location"};
    }

    double shortestDistance = double.infinity;
    Map<String, dynamic> nearest = {"name": "Unknown Location"};

    for (var loc in locations) {
      double distance = Geolocator.distanceBetween(
        studentLocation!.latitude,
        studentLocation!.longitude,
        loc['latitude'],
        loc['longitude'],
      );
      if (distance < shortestDistance) {
        shortestDistance = distance;
        nearest = loc;
      }
    }

    if (shortestDistance <= proximityThreshold) {
      return nearest;
    } else {
      return {"name": "No nearby location"};
    }
  }

  void _showAlertDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nearestLocation = findNearestLocation();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF8B1E3F),
        title: Text(
          'Student Location',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: studentLocation == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Search for a location...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        suffixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xFF8B1E3F), width: 2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6, // Adjusted map height
                      child: FlutterMap(
                        options: MapOptions(
                          center: studentLocation,
                          zoom: 16,
                          maxZoom: 18,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                            subdomains: ['a', 'b', 'c'],
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: studentLocation!,
                                builder: (ctx) => Icon(
                                  Icons.location_pin,
                                  color: Color(0xFFCA2C5C),
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "You are close to: ${nearestLocation['name']}",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

