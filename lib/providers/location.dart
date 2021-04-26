import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class LocationProvider extends ChangeNotifier {
  Location _location = new Location();
  bool _serviceEnabled;
  PermissionStatus _permissionGranted;
  // ignore: unused_field
  LocationData _locationData;
  Completer<GoogleMapController> _controller = Completer();
  Map<PolylineId, Polyline> _polylines = {};

  Future<void> init() async {
    print("Initializing location provider");
    this._serviceEnabled = await this._location.serviceEnabled();
    if (!this._serviceEnabled) {
      this._serviceEnabled = await this._location.requestService();
      if (!this._serviceEnabled) return;
    }

    this._permissionGranted = await this._location.hasPermission();
    if (this._permissionGranted == PermissionStatus.denied) {
      this._permissionGranted = await this._location.requestPermission();
      if (this._permissionGranted != PermissionStatus.granted) return;
    }

    this._locationData = await this._location.getLocation();
    notifyListeners();

    this._location.onLocationChanged.listen((LocationData data) {
      this._locationData = data;
      this.updatePinOnMap();
      this._addPolyLine();
    });
  }

  void updatePinOnMap() async {
    CameraPosition cPosition = CameraPosition(
        target:
            LatLng(this._locationData.latitude, this._locationData.longitude),
        zoom: 19.151926040649414);

    final GoogleMapController controller = await this._controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(cPosition));
    notifyListeners();
  }

  _addPolyLine() {
    PolylineId id = PolylineId("poly");
    Polyline polyline = Polyline(polylineId: id, color: Colors.red, points: [
      LatLng(this._locationData.latitude, this._locationData.longitude)
    ]);
    this._polylines[id] = polyline;
    notifyListeners();
  }

  LocationData get locationData => this._locationData;
  Completer<GoogleMapController> get controller => this._controller;
  Map<PolylineId, Polyline> get polylines => this._polylines;
}
