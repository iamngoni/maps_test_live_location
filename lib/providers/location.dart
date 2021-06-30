import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

class LocationProvider extends ChangeNotifier {
  Location _location = new Location();
  bool _serviceEnabled;
  PermissionStatus _permissionGranted;
  // ignore: unused_field
  LocationData _locationData;
  Completer<GoogleMapController> _controller = Completer();
  final PolylinePoints polylinePoints = PolylinePoints();
  final List<LatLng> polylineCoordinates = [];
  final Set<Polyline> polylines = {};
  final Map<MarkerId, Marker> markers = Map();

  final double uzLatitude = -17.782438;
  final double uzLongitude = 31.054688;

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

    this.setPolyLines(
        LatLng(this._locationData.latitude, this.locationData.longitude),
        LatLng(uzLatitude, uzLongitude));

    // this._location.onLocationChanged.listen((LocationData data) {
    //   this._locationData = data;
    // this.updatePinOnMap(;)
    // });
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

  setPolyLines(LatLng pointA, LatLng pointB) async {
    // clear polylines (this is optional)
    // clear if  you plan to get only one route

    PolylineResult _result = await polylinePoints?.getRouteBetweenCoordinates(
      "GOOGLE_MAPS_API",
      PointLatLng(
        pointA.latitude,
        pointA.longitude,
      ),
      PointLatLng(pointB.latitude, pointB.longitude),
      travelMode: TravelMode.driving,
    );

    print(_result.points);

    List<PointLatLng> result = _result.points;
    if (result.isNotEmpty) {
      // loop through all PointLatLng points and convert them
      // to a list of LatLng, required by the Polyline
      result.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    }

    // create a Polyline instance
    // with an id, an RGB color and the list of LatLng pairs
    Polyline polyline = Polyline(
        polylineId: PolylineId("Route"),
        color: Color.fromARGB(255, 40, 122, 198),
        points: polylineCoordinates);
    polylines.add(polyline);

    // add markers
    final pointAMarkerId = MarkerId("pointA");
    final Marker pointAMarker = Marker(
      consumeTapEvents: false,
      visible: true,
      icon:
          await getBitmapDescriptorFromAsset("assets/icons/departure.png", 100),
      markerId: pointAMarkerId,
      position: pointA,
      infoWindow:
          InfoWindow(title: "Point A", snippet: 'This is the starting point'),
    );

    final pointBMarkerId = MarkerId("pointB");
    final Marker pointBMarker = Marker(
      consumeTapEvents: false,
      visible: true,
      icon: await getBitmapDescriptorFromAsset(
          "assets/icons/destination.png", 100),
      markerId: pointBMarkerId,
      position: pointB,
      infoWindow:
          InfoWindow(title: "Point B", snippet: 'This is the destination'),
    );

    markers[pointAMarkerId] = pointAMarker;
    markers[pointBMarkerId] = pointBMarker;

    notifyListeners();
  }

  Future<BitmapDescriptor> getBitmapDescriptorFromAsset(
      String path, int width) async {
    // basically for loading custom icons for your pins on the map

    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    final bytes = (await fi.image.toByteData(format: ui.ImageByteFormat.png))
        .buffer
        .asUint8List();

    return BitmapDescriptor.fromBytes(bytes);
  }

  LocationData get locationData => this._locationData;
  LatLng get currentLocation =>
      LatLng(this._locationData.latitude, this._locationData.longitude);
  Completer<GoogleMapController> get controller => this._controller;
}
