import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geocoding/geocoding.dart' as g;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:location/location.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_maps_webservice/places.dart' as places;
import 'package:permission_handler/permission_handler.dart'as pr;
import 'package:provider/provider.dart';
import 'package:translation_rental/MapDirectry/pin_pill_info.dart';
import 'package:google_api_headers/google_api_headers.dart';

import 'package:flutter/src/scheduler/ticker.dart';
import 'package:future_progress_dialog/future_progress_dialog.dart';
import 'package:translation_rental/screens/homescreen.dart';


import 'map_pin_pill.dart';

const double CAMERA_ZOOM = 13;
const double CAMERA_TILT = 80;
const double CAMERA_BEARING = 30;

// LatLng DEST_LOCATION = LatLng(33.60039,73.062823);


String kGoogleApiKey = "AIzaSyB0EbvFRPy5cGcBE47BeGLgMJzw-l9IxeQ";

class RealTimeLocationScreen extends StatefulWidget {
  const RealTimeLocationScreen({Key? key}) : super(key: key);

  @override
  State<RealTimeLocationScreen> createState() => _RealTimeLocationScreenState();
}

final homeScaffoldKey = GlobalKey<ScaffoldState>();
final searchScaffoldKey = GlobalKey<ScaffoldState>();

class _RealTimeLocationScreenState extends State<RealTimeLocationScreen> {

  LatLng SOURCE_LOCATION = const LatLng(42.747932, -71.167889);
  LatLng DEST_LOCATION = const LatLng(33.660012,73.083322);

  final Completer<GoogleMapController> _controller = Completer();
  GoogleMapController? mapController;

  final Set<Marker> _markers = <Marker>{};

  PolylinePoints polylinePoints = PolylinePoints();

  String googleAPIKey = "AIzaSyAdTVcCmEfa3BbkGHe8SK2EFjtM66v1CO8";
  // Set<Marker> markers = {}; //markers for google map
  Map<PolylineId, Polyline> polylines = {};

  List<LatLng> polylineCoordinates = [];
  BitmapDescriptor? sourceIcon;
  BitmapDescriptor? destinationIcon;
  LocationData? currentLocation;
  LocationData? destinationLocation;
  Location? location;
  double pinPillPosition = -100;
  PinInformation currentlySelectedPin = PinInformation(
      pinPath: '',
      avatarPath: '',
      location: const LatLng(0, 0),
      locationName: '',
      labelColor: Colors.grey);
   PinInformation? sourcePinInfo;
  PinInformation? destinationPinInfo;

  double distance = 0.0;


  final places.GoogleMapsPlaces _places = places.GoogleMapsPlaces(apiKey: kGoogleApiKey);

  String placeSelected="";

  String _address = "";
  bool? permissionGranted;


  @override
  void initState() {
    super.initState();

      location =  Location();
      polylinePoints = PolylinePoints();

      // subscribe to changes in the user's location
      // by "listening" to the location's onLocationChanged event
      location!.onLocationChanged.listen((LocationData cLoc) {
        // cLoc contains the lat and long of the
        // current user's position in real time,
        // so we're holding on to it
        currentLocation = cLoc;
        updatePinOnMap();
        currentLoc();
      });
      // set custom marker pins
      setSourceAndDestinationIcons();

      // set the initial location




  }

  Future _getLocationPermission() async {
    if (await pr.Permission.location.request().isGranted) {
      permissionGranted = true;
    } else if (await pr.Permission.location.request().isPermanentlyDenied) {
      throw('location.request().isPermanentlyDenied');
    } else if (await pr.Permission.location.request().isDenied) {
      throw('location.request().isDenied');
      permissionGranted = false;
    }
  }

  void setSourceAndDestinationIcons() async {
    BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(devicePixelRatio: 2.0), 'assets/images/driving_pin.png')
        .then((onValue) {
      sourceIcon = onValue;
    });

    BitmapDescriptor.fromAssetImage(const ImageConfiguration(devicePixelRatio: 2.0),
        'assets/images/destination_map_marker.png')
        .then((onValue) {
      destinationIcon = onValue;
    });
  }

  void currentLoc()async{
    currentLocation = await location!.getLocation();
    var pinPosition =
    LatLng(currentLocation!.latitude!, currentLocation!.longitude!);

    sourcePinInfo = PinInformation(
        locationName: "Start Location",
        location: SOURCE_LOCATION,
        pinPath: "assets/images/driving_pin.png",
        avatarPath: "assets/images/friend1.jpg",
        labelColor: Colors.blueAccent);
    mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
            CameraPosition(target: pinPosition, zoom: 13)
          //17 is new zoom level
        )
    );

    // add the initial source location pin
    _markers.add(Marker(
        markerId: MarkerId('sourcePin'),
        position: pinPosition,
        onTap: () {
          setState(() {
            currentlySelectedPin = sourcePinInfo!;
            pinPillPosition = 0;
          });
        },
        icon: sourceIcon!));
  }

  void setInitialLocation() async {
    // set the initial location by pulling the user's
    // current location from the location's getLocation()
    currentLocation = await location!.getLocation();

    // hard-coded destination for this example
    destinationLocation = LocationData.fromMap({
      "latitude": DEST_LOCATION.latitude,
      "longitude": DEST_LOCATION.longitude
    });

    showPinsOnMap();
  }

  void _getPlace() async {
    List<g.Placemark> newPlace = await g.placemarkFromCoordinates(currentLocation!.latitude!, currentLocation!.longitude!);

    // this is all you need
    g.Placemark placeMark  = newPlace[0];
    String? name = placeMark.name;
    String? subLocality = placeMark.subLocality;
    String? locality = placeMark.locality;
    String? administrativeArea = placeMark.administrativeArea;
    String? postalCode = placeMark.postalCode;
    String? country = placeMark.country;
    String? address = "${name}, ${subLocality}, ${locality}, ${administrativeArea} ${postalCode}, ${country}";

    print('Addresscall $address');

    setState(() {
      _address = address; // update _address
    });
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    CameraPosition initialCameraPosition =  CameraPosition(
        zoom: CAMERA_ZOOM,
        tilt: CAMERA_TILT,
        bearing: CAMERA_BEARING,
        target: SOURCE_LOCATION);
    if (currentLocation != null) {
      initialCameraPosition = CameraPosition(
          target: LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
          zoom: CAMERA_ZOOM,
          tilt: CAMERA_TILT,
          bearing: CAMERA_BEARING);
    }
    return Scaffold(
      key: homeScaffoldKey,
      body: SafeArea(
        child: Stack(
          children: <Widget>[

            GoogleMap(
                myLocationEnabled: true,
                compassEnabled: true,
                tiltGesturesEnabled: false,
                markers: _markers,
                polylines:  Set<Polyline>.of(polylines.values),
                // polylines:  _polyline,
                mapType: MapType.normal,

                initialCameraPosition: initialCameraPosition,
                onTap: (LatLng loc) {
                  pinPillPosition = -100;
                },
                onMapCreated: (GoogleMapController controller) {
                  // controller.setMapStyle(Utils.mapStyles);
                  setState(() {
                      _controller.complete(controller);

                    mapController=controller;

                    //showPinsOnMap();
                  });

                }

                ),


            Positioned(
                bottom: height*0.05,
                left: width*0.25,
                child: Card(
                  child: Container(
                      padding: const EdgeInsets.all(20),
                      child: Text("Total Distance: ${distance.toStringAsFixed(2)} KM",
                          style: const TextStyle(fontSize: 15, fontWeight:FontWeight.bold))
                  ),
                )
            ),
            Positioned(
                left: width*0.23,
                top: 10,
                right: width*0.23,
              child: GestureDetector(
                onTap: ()async{
                    places.Prediction? p = await PlacesAutocomplete.show(
                        context: context,
                        apiKey: kGoogleApiKey,
                        types: [],
                        components: [],
                        mode: Mode.overlay,
                        strictbounds: false);
                    //_isSearchingAddress = true;
                    displayPrediction(p!);


                },
                child: Container(

                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: Colors.white
                    ),
                    child:  Padding(
                      padding: const EdgeInsets.all(8.0),
                        child: Text(placeSelected == "" ?'Pick Destination address':placeSelected,style: const TextStyle(
                      fontWeight: FontWeight.bold,

                    ),
                          textAlign: TextAlign.center,
                    ))
                ),
              ),
            ),
            MapPinPillComponent(
              pinPillPosition: pinPillPosition,
              currentlySelectedPin: currentlySelectedPin,
              source: _address,
              destination: placeSelected,),
            Visibility(
              visible: Provider.of<InternetConnectionStatus>(context)==InternetConnectionStatus.disconnected,
              child: const Center(child: Text('No Internet Connection')),
            )
            // Positioned(
            //     bottom: height*0.0,
            //     left: width*0.45,
            //     child:  MaterialButton(
            //       onPressed: (){
            //         print('des_lat= $DEST_LOCATION');
            //         mapController?.animateCamera(
            //             CameraUpdate.newCameraPosition(
            //                 CameraPosition(target: DEST_LOCATION, zoom: 17)
            //               //17 is new zoom level
            //             )
            //         );
            //       },
            //       color: Colors.blue,
            //       child: const Text('Done',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
            //     ),
            // ),
          ],
        ),
      ),
    );
  }


  Future<Null> displayPrediction(places.Prediction p) async {
    places.PlacesDetailsResponse detail =
    await _places.getDetailsByPlaceId(p.placeId!);

    var placeId = p.placeId;
    double lat = detail.result.geometry!.location.lat;
    double lng = detail.result.geometry!.location.lng;

    // print('displayPrediction placeId: ${p.placeId}');
    // print('displayPrediction reference: ${p.reference}');
    // print('displayPrediction description: ${p.description}');
    // print('displayPrediction types: ${p.types}');
    // print('displayPrediction terms: ${p.terms}');

    for (var i = 0; i < p.terms.length; ++i) {
      print('displayPrediction terms[$i]: ${p.terms[i].value}');
    }
    // print('displayPrediction matchedSubstrings: ${p.matchedSubstrings}');

//      var address = await Geocoder.local.findAddressesFromQuery(p.description);

    LatLng latLng = LatLng(lat, lng);
    setState(() {
      placeSelected= p.description!;

      DEST_LOCATION = LatLng(lat, lng);
      showProgressWithoutMsg(context);
      _markers.add(Marker(
          markerId: const MarkerId('destPin'),
          position: DEST_LOCATION,
          onTap: () {
            setState(() {
              currentlySelectedPin = destinationPinInfo!;
              pinPillPosition = 0;
              print('DEST_LOCATION: $DEST_LOCATION');
            });
          },
          icon: destinationIcon!));

      setInitialLocation();


    });
  }

  void onError(places.PlacesAutocompleteResponse response) {
    homeScaffoldKey.currentState!.showSnackBar(
      SnackBar(content: Text(response.errorMessage!)),
    );
  }


  void showPinsOnMap() {
    // get a LatLng for the source location
    // from the LocationData currentLocation object
    var pinPosition =
    LatLng(currentLocation!.latitude!, currentLocation!.longitude!);
    // get a LatLng out of the LocationData object
    var destPosition =
    LatLng(destinationLocation!.latitude!, destinationLocation!.longitude!);

    sourcePinInfo = PinInformation(
        locationName: "Start Location",
        location: SOURCE_LOCATION,
        pinPath: "assets/images/driving_pin.png",
        avatarPath: "assets/images/friend1.jpg",
        labelColor: Colors.blueAccent);

    destinationPinInfo = PinInformation(
        locationName: "End Location",
        location: DEST_LOCATION,
        pinPath: "assets/images/destination_map_marker.png",
        avatarPath: "assets/images/friend2.jpg",
        labelColor: Colors.purple);

    // add the initial source location pin
    _markers.add(Marker(
        markerId: const MarkerId('sourcePin'),
        position: pinPosition,
        onTap: () {
          setState(() {
            currentlySelectedPin = sourcePinInfo!;
            pinPillPosition = 0;
          });
        },
        icon: sourceIcon!));
    // destination pin
    _markers.add(Marker(
        markerId: const MarkerId('destPin'),
        position: destPosition,
        onTap: () {
          setState(() {
            currentlySelectedPin = destinationPinInfo!;
            pinPillPosition = 0;
          });
        },
        icon: destinationIcon!));
    // set the route lines on the map from source to destination
    // for more info follow this tutorial
    getDirections();
  }


  getDirections() async {
    List<LatLng> polylineCoordinates = [];

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleAPIKey,
      PointLatLng(currentLocation!.latitude!,currentLocation!.longitude!),
      PointLatLng(destinationLocation!.latitude!, destinationLocation!.longitude!),
      travelMode: TravelMode.driving,
    );

    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
      if (kDebugMode) {
        print(polylineCoordinates);
      }
    } else {
      if (kDebugMode) {
        print(result.errorMessage);
      }
    }


    double totalDistance = 0;
    for(var i = 0; i < polylineCoordinates.length-1; i++){
      totalDistance += calculateDistance(
          polylineCoordinates[i].latitude,
          polylineCoordinates[i].longitude,
          polylineCoordinates[i+1].latitude,
          polylineCoordinates[i+1].longitude);
    }

    if (kDebugMode) {
      print(totalDistance);
    }

    setState(() {
      distance = totalDistance;
      addPolyLine(polylineCoordinates);
    });

    // addextraPolyline(polylineCoordinates);
  }
  
  double calculateDistance(lat1, lon1, lat2, lon2){
    var p = 0.017453292519943295;
    var a = 0.5 - cos((lat2 - lat1) * p)/2 +
        cos(lat1 * p) * cos(lat2 * p) *
            (1 - cos((lon2 - lon1) * p))/2;
    return 12742 * asin(sqrt(a));
  }

  addPolyLine(List<LatLng> polylineCoordinates) {
    PolylineId id = const PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.redAccent,
      points: polylineCoordinates,
      width: 5,
    );
    polylines[id] = polyline;
    setState(() {
      _getPlace();
    });
  }

  void updatePinOnMap() async {
    // create a new CameraPosition instance
    // every time the location changes, so the camera
    // follows the pin as it moves with an animation
    CameraPosition cPosition = CameraPosition(
      zoom: CAMERA_ZOOM,
      tilt: CAMERA_TILT,
      bearing: CAMERA_BEARING,
      target: LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
    );
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(cPosition));
    // do this inside the setState() so Flutter gets notified
    // that a widget update is due
    setState(() {
      // updated position
      var pinPosition =
      LatLng(currentLocation!.latitude!, currentLocation!.longitude!);

      sourcePinInfo != null ? sourcePinInfo!.location = pinPosition : null;

      // the trick is to remove the marker (by id)
      // and add it again at the updated location
      _markers.removeWhere((m) => m.markerId.value == 'sourcePin');
      _markers.add(Marker(
          markerId: const MarkerId('sourcePin'),
          onTap: () {
            setState(() {
              currentlySelectedPin = sourcePinInfo!;
              pinPillPosition = 0;
            });
          },
          position: pinPosition, // updated position
          icon: sourceIcon!));
      // if(currentLocation!.latitude!.compareTo(destinationLocation!.latitude!)==00.0000 &&currentLocation!.longitude!.compareTo(destinationLocation!.longitude!)==00.000 ) {
      //
      // }
      if(destinationLocation!=null){
        if(destinationLocation!.latitude == currentLocation!.latitude && destinationLocation!.longitude == currentLocation!.longitude ) {
          _displayDialog(context);
        }
      }
    });
  }

  _displayDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Expanded(
          child: AlertDialog(
            title: const Text('Thanks!'),
            content: const Text('You are safely reached to your destination'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('YES', style: TextStyle(color: Colors.black),),
              ),
              // TextButton(
              //   onPressed: () {
              //     Navigator.of(context).pop();
              //   },
              //   child: Text('NO', style: TextStyle(color: Colors.black),),
              // ),
            ],
          ),
        );
      },
    );
  }

  Future<void> showProgressWithoutMsg(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) =>
          FutureProgressDialog(getFuture()),
    );
  }
  Future getFuture() {
    return Future(() async {
      await Future.delayed(const Duration(seconds: 4));
      return '';
    });
  }


}

class Utils {
  static String mapStyles = '''[
  {
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#f5f5f5"
      }
    ]
  },
  {
    "elementType": "labels.icon",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#616161"
      }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#f5f5f5"
      }
    ]
  },
  {
    "featureType": "administrative.land_parcel",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#bdbdbd"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#eeeeee"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#e5e5e5"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#ffffff"
      }
    ]
  },
  {
    "featureType": "road.arterial",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#dadada"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#616161"
      }
    ]
  },
  {
    "featureType": "road.local",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
      }
    ]
  },
  {
    "featureType": "transit.line",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#e5e5e5"
      }
    ]
  },
  {
    "featureType": "transit.station",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#eeeeee"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#c9c9c9"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
      }
    ]
  }
]''';
}