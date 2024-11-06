import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../Repositories/map_repository.dart';
import '../Utils/map_utils.dart';

class GoogleMapsWidget extends StatefulWidget {
  const GoogleMapsWidget({super.key});

  @override
  _GoogleMapsWidgetState createState() => _GoogleMapsWidgetState();
}

class _GoogleMapsWidgetState extends State<GoogleMapsWidget> {
  final Completer<GoogleMapController> _controller = Completer();
  final LatLng initialLatLng = const LatLng(30.029585, 31.022356);
  final LatLng destinationLatLng = const LatLng(30.060567, 30.962413);
  final Set<Marker> _markers = <Marker>{};
  final Set<Polyline> _polyline = {};

  bool mapDarkMode = true;
  late String _darkMapStyle;
  late String _lightMapStyle;
  late BitmapDescriptor customIcon;

  @override
  void initState() {
    super.initState();
    _loadMapStyles();
    _loadCustomMarkerIcon();
  }

  Future<void> _loadMapStyles() async {
    _darkMapStyle = await rootBundle.loadString('assets/map_style/dark.json');
    _lightMapStyle = await rootBundle.loadString('assets/map_style/light.json');
  }

  Future<void> _loadCustomMarkerIcon() async {
    customIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(50, 50)),
      'assets/images/marker_car.png',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          mapType: MapType.normal,
          markers: _markers,
          polylines: _polyline,
          initialCameraPosition: CameraPosition(
            target: initialLatLng,
            zoom: 14.47,
          ),
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
            _setMapStyle();
            _setMapPins();
            _addPolyline();
          },
        ),
        Positioned(
          top: 100,
          right: 30,
          child: IconButton(
            icon: Icon(
              mapDarkMode ? Icons.brightness_4 : Icons.brightness_5,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: () {
              setState(() {
                mapDarkMode = !mapDarkMode;
                _setMapStyle();
              });
            },
          ),
        ),
      ],
    );
  }

  Future<void> _setMapStyle() async {
    final controller = await _controller.future;
    controller.setMapStyle(mapDarkMode ? _darkMapStyle : _lightMapStyle);
  }

  void _setMapPins() {
    setState(() {
      _markers.clear();
      _markers.add(Marker(
        markerId: MarkerId('start'),
        position: initialLatLng,
        icon: customIcon,
      ));
      _markers.add(Marker(
        markerId: MarkerId('destination'),
        position: destinationLatLng,
      ));
    });
  }

  Future<void> _addPolyline() async {
    final result = await MapRepository()
        .getRouteCoordinates(initialLatLng, destinationLatLng);
    final route = result.data["routes"][0]["overview_polyline"]["points"];

    setState(() {
      _polyline.add(Polyline(
        polylineId: const PolylineId("route"),
        points: MapUtils.convertToLatLng(MapUtils.decodePoly(route)),
        color: Theme.of(context).primaryColor,
        width: 3,
      ));
    });
  }
}
