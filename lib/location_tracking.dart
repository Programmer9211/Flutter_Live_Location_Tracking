import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:location_tracking/google_map_api.dart';

class LocationTracking extends StatefulWidget {
  const LocationTracking({Key? key}) : super(key: key);

  @override
  _LocationTrackingState createState() => _LocationTrackingState();
}

class _LocationTrackingState extends State<LocationTracking> {
  LatLng sourceLocation = LatLng(28.432864, 77.002563);
  LatLng destinationLatlng = LatLng(28.431626, 77.002475);

  bool isLoading = true;
  Completer<GoogleMapController> _controller = Completer();

  Set<Marker> _marker = Set<Marker>();

  Set<Polyline> _polylines = Set<Polyline>();
  List<LatLng> polylineCoordinates = [];
  late PolylinePoints polylinePoints;

  late StreamSubscription<LocationData> subscription;

  late LocationData currentLocation;
  late LocationData destinationLocation;
  late Location location;

  @override
  void initState() {
    super.initState();

    location = Location();
    polylinePoints = PolylinePoints();

    subscription = location.onLocationChanged.listen((clocation) {
      currentLocation = clocation;

      updatePinsOnMap();
    });

    setInitialLocation();
  }

  void setInitialLocation() async {
    currentLocation = await location.getLocation();

    destinationLocation = LocationData.fromMap({
      "latitude": destinationLatlng.latitude,
      "longitude": destinationLatlng.longitude,
    });

    setState(() {
      isLoading = false;
    });
  }

  void showLocationPins() {
    var sourceposition = LatLng(
        currentLocation.latitude ?? 0.0, currentLocation.longitude ?? 0.0);

    var destinationPosition =
        LatLng(destinationLatlng.latitude, destinationLatlng.longitude);

    _marker.add(Marker(
      markerId: MarkerId('sourcePosition'),
      position: sourceposition,
    ));

    _marker.add(
      Marker(
        markerId: MarkerId('destinationPosition'),
        position: destinationPosition,
      ),
    );

    setPolylinesInMap();
  }

  void setPolylinesInMap() async {
    var result = await polylinePoints.getRouteBetweenCoordinates(
      GoogleMapApi().url,
      PointLatLng(
          currentLocation.latitude ?? 0.0, currentLocation.longitude ?? 0.0),
      PointLatLng(destinationLatlng.latitude, destinationLatlng.longitude),
    );

    if (result.points.isNotEmpty) {
      result.points.forEach((pointLatLng) {
        polylineCoordinates
            .add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }

    setState(() {
      _polylines.add(Polyline(
        width: 5,
        polylineId: PolylineId('polyline'),
        color: Colors.blueAccent,
        points: polylineCoordinates,
      ));
    });
  }

  void updatePinsOnMap() async {
    CameraPosition cameraPosition = CameraPosition(
      zoom: 20,
      tilt: 80,
      bearing: 30,
      target: LatLng(
          currentLocation.latitude ?? 0.0, currentLocation.longitude ?? 0.0),
    );

    final GoogleMapController controller = await _controller.future;

    controller.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    var sourcePosition = LatLng(
        currentLocation.latitude ?? 0.0, currentLocation.longitude ?? 0.0);

    setState(() {
      _marker.removeWhere((marker) => marker.mapsId.value == 'sourcePosition');

      _marker.add(Marker(
        markerId: MarkerId('sourcePosition'),
        position: sourcePosition,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    CameraPosition initialCameraPosition = CameraPosition(
      zoom: 20,
      tilt: 80,
      bearing: 30,
      target: LatLng(
          currentLocation.latitude ?? 0.0, currentLocation.longitude ?? 0.0),
    );

    return isLoading
        ? Expanded(
            child: Container(
            alignment: Alignment.center,
            child: CircularProgressIndicator(),
          ))
        : SafeArea(
            child: Scaffold(
              body: GoogleMap(
                myLocationButtonEnabled: true,
                compassEnabled: true,
                markers: _marker,
                polylines: _polylines,
                mapType: MapType.normal,
                initialCameraPosition: initialCameraPosition,
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);

                  showLocationPins();
                },
              ),
            ),
          );
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }
}
