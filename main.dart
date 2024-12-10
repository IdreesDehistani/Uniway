import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart'; // For LatLng
import 'package:geolocator/geolocator.dart'; // For GPS location


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(), // Start with the HomePage
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('UNI-WAY'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Navigate to the map screen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MapScreen()),
            );
          },
          child: Text("Where am I?"),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            textStyle: TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }
}

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? studentLocation; // To hold the student's current location

  @override
  void initState() {
    super.initState();
    _getRealTimeLocation(); // Fetch GPS coordinates when the app starts
  }

  // Fetch the GPS coordinates
  Future<void> _getRealTimeLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        studentLocation = LatLng(0, 0); // Fallback to a default location
      });
      return;
    }

    // Request location permissions if not already granted
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          studentLocation = LatLng(0, 0); // Fallback to a default location
        });
        return;
      }
    }

    // Fetch the current position
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Update the map with the fetched location
    setState(() {
      studentLocation = LatLng(position.latitude, position.longitude);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Student Location'),
      ),
      body: studentLocation == null
          ? Center(child: CircularProgressIndicator()) // Show loader until location is fetched
          : Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.black, // Border color
                      width: 2,           // Border width
                    ),
                    borderRadius: BorderRadius.circular(10), // Rounded corners
                  ),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7, // 70% of screen height
                    child: FlutterMap(
                      options: MapOptions(
                        center: studentLocation, // Center the map on the fetched location
                        zoom: 16, // Default zoom level
                        maxZoom: 18, // Limit maximum zoom to prevent blank screen
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
                                color: Colors.red,
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
                  "© OpenStreetMap contributors",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getRealTimeLocation, // Update location on button press
        child: Icon(Icons.my_location),
      ),
    );
  }
}