import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps_test/providers/location.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => LocationProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    Provider.of<LocationProvider>(context, listen: false).init();
    return MaterialApp(
      title: 'Live Location Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MapTest(),
    );
  }
}

class MapTest extends StatefulWidget {
  @override
  _MapTestState createState() => _MapTestState();
}

class _MapTestState extends State<MapTest> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Location Tracker Test"),
      ),
      body: Consumer<LocationProvider>(builder: (context, provider, child) {
        while (provider.polylines.isEmpty) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        print(provider.locationData);

        return Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: GoogleMap(
            mapType: MapType.satellite,
            initialCameraPosition: CameraPosition(
              target: LatLng(provider.locationData.latitude, provider.locationData.longitude),
              zoom: 19.151926040649414,
            ),
            myLocationEnabled: true,
            polylines: provider.polylines,
            markers: Set<Marker>.of(provider.markers.values),
            onMapCreated: (GoogleMapController controller) {
              provider.controller.complete(controller);
            },
          ),
        );
      }),
    );
  }
}
