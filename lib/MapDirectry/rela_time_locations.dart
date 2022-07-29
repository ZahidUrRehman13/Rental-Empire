import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoder/geocoder.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_maps_webservice/places.dart' as places;
import 'package:translation_rental/MapDirectry/pin_pill_info.dart';
import 'package:google_api_headers/google_api_headers.dart';


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

  LatLng SOURCE_LOCATION = LatLng(42.747932, -71.167889);
  LatLng DEST_LOCATION = LatLng(33.60039,73.062823);

  final Completer<GoogleMapController> _controller = Completer();
  GoogleMapController? mapController;

  final Set<Marker> _markers = <Marker>{};

  PolylinePoints polylinePoints = PolylinePoints();

  String googleAPIKey = "AIzaSyAdTVcCmEfa3BbkGHe8SK2EFjtM66v1CO8";
  Set<Marker> markers = {}; //markers for google map
  Map<PolylineId, Polyline> polylines = {};

  List<LatLng> polylineCoordinates = [];
  // PolylinePoints? polylinePoints;
  // String googleAPIKey = '<AIzaSyAdTVcCmEfa3BbkGHe8SK2EFjtM66v1CO8>';
// for my custom marker pins
  BitmapDescriptor? sourceIcon;
  BitmapDescriptor? destinationIcon;
// the user's initial location and current location
// as it moves
  LocationData? currentLocation;
// a reference to the destination location
  LocationData? destinationLocation;
// wrapper around the location API
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

  Mode _mode = Mode.overlay;

  places.GoogleMapsPlaces _places = places.GoogleMapsPlaces(apiKey: kGoogleApiKey);

  String placeSelected="";

  @override
  void initState() {
    super.initState();

    // create an instance of Location
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
    });
    // set custom marker pins
    setSourceAndDestinationIcons();
    // set the initial location
    setInitialLocation();
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

  void setInitialLocation() async {
    // set the initial location by pulling the user's
    // current location from the location's getLocation()
    currentLocation = await location!.getLocation();

    // hard-coded destination for this example
    destinationLocation = LocationData.fromMap({
      "latitude": DEST_LOCATION.latitude,
      "longitude": DEST_LOCATION.longitude
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
                mapType: MapType.normal,
                initialCameraPosition: initialCameraPosition,
                onTap: (LatLng loc) {
                  pinPillPosition = -100;
                },
                onMapCreated: (GoogleMapController controller) {
                  // controller.setMapStyle(Utils.mapStyles);
                  _controller.complete(controller);
                  // my map has completed being created;
                  // i'm ready to show the pins on the map
                  showPinsOnMap();
                }),

            MapPinPillComponent(
                pinPillPosition: pinPillPosition,
                currentlySelectedPin: currentlySelectedPin),
            Positioned(
                bottom: 200,
                left: 50,
                child: Card(
                  child: Container(
                      padding: const EdgeInsets.all(20),
                      child: Text("Total Distance: ${distance.toStringAsFixed(2)} KM",
                          style: const TextStyle(fontSize: 20, fontWeight:FontWeight.bold))
                  ),
                )
            ),
            GestureDetector(
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
              child: Padding(
                padding: EdgeInsets.only(left: width*0.23,top: 10),
                child: Container(
                    width: width*0.6,
                    height: height*0.07,

                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: Colors.white
                    ),
                    child:  Center(child: Expanded(
                      child: Text(placeSelected == "" ?'Pick Destination address':placeSelected,style: const TextStyle(
                        fontWeight: FontWeight.bold
                      ),),
                    ))
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
  Future<Null> displayPrediction(places.Prediction p) async {
    if (p != null) {
      places.PlacesDetailsResponse detail =
      await _places.getDetailsByPlaceId(p.placeId!);

      var placeId = p.placeId;
      double lat = detail.result.geometry!.location.lat;
      double lng = detail.result.geometry!.location.lng;

      print('displayPrediction placeId: ${p.placeId}');
      print('displayPrediction reference: ${p.reference}');
      print('displayPrediction description: ${p.description}');
      print('displayPrediction types: ${p.types}');
      print('displayPrediction terms: ${p.terms}');

      for (var i = 0; i < p.terms.length; ++i) {
        print('displayPrediction terms[$i]: ${p.terms[i].value}');
      }
      print('displayPrediction matchedSubstrings: ${p.matchedSubstrings}');

//      var address = await Geocoder.local.findAddressesFromQuery(p.description);

      LatLng latLng = LatLng(lat, lng);
      setState(() {
        placeSelected= p.description!;
        DEST_LOCATION = LatLng(lat, lng);
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


      });
      getUDirections(lat, lng);

      // markers.add( Marker( //add second marker
      //   markerId: const MarkerId("upDated"),
      //   position: LatLng(33.60039,73.062823), //position of marker
      //   infoWindow: const InfoWindow( //popup info
      //     title: 'My Custom Title ',
      //     snippet: 'My Custom Subtitle',
      //   ),
      //   icon: BitmapDescriptor.defaultMarker, //Icon for Marker
      // ));
      //_findAddressFromLatLng(latLng);

//       setState(() {
//         _initialPosition = LatLng(latLng.latitude, latLng.longitude);
//         String description = "";
//         for (var i = 0; i < p.terms.length - 1; ++i) {
//           print('displayPrediction terms[$i]: ${p.terms[i].value}');
//           if (i == p.terms.length - 2) {
//             description += p.terms[i].value;
//           } else {
//             description += p.terms[i].value + ", ";
//           }
//         }
//
// //        String description = p.description;
// ////        if(p.description.toLowerCase().contains("united arab emirates")) {
// ////          print('ADDRESS_REPLACE:');
// ////          description = p.description.replaceAll("united arab emirates", "");
// ////        }
//         _locationController.text = description;
//         _searchedAddress = description;
//
//         _latitude = latLng.latitude;
//         _longitude = latLng.longitude;
//
//         _mapController!.animateCamera(
//           CameraUpdate.newCameraPosition(
//             CameraPosition(target: _initialPosition!, zoom: 16.0),
//           ),
//         );
//
//         final String markerIdVal = 'marker_id_$_markerIdCounter';
//         //_markerIdCounter++;
//         final MarkerId markerId = MarkerId(markerIdVal);
//         final Marker marker = Marker(
//           markerId: markerId,
//           position: LatLng(
//             latLng.latitude,
//             latLng.longitude,
//           ),
//           onDragEnd: (position) async {
//             setState(() {
//               _findAddressFromLatLng(position, true);
//             });
//           },
//           draggable: true,
//           infoWindow: InfoWindow(title: p.description, snippet: ""),
//         );
//
//         markers[markerId] = marker;
//       });
    }
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
        markerId: MarkerId('sourcePin'),
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
    print('Direction Api');
  }

  // void setPolylines() async {
  //   PolylineResult result = await polylinePoints!.getRouteBetweenCoordinates(
  //     googleAPIKey,
  //       PointLatLng(currentLocation!.latitude!, currentLocation!.longitude!),
  //       PointLatLng(destinationLocation!.latitude!, destinationLocation!.longitude!),
  //       travelMode: TravelMode.driving,
  //       wayPoints: [PolylineWayPoint(location: "Sabo, Yaba Lagos Nigeria")]);
  //
  //   if (result.points.isNotEmpty) {
  //     for (var point in result.points) {
  //       polylineCoordinates.add(LatLng(point.latitude, point.longitude));
  //     }
  //
  //     setState(() {
  //       _polylines.add(Polyline(
  //           width: 2, // set the width of the polylines
  //           polylineId: const PolylineId("poly"),
  //           color: const Color.fromARGB(255, 255, 50, 50),
  //           visible: true,
  //           points: polylineCoordinates));
  //       print(polylineCoordinates);
  //     });
  //   }
  // }

  // _getPolyline() async {
  //   PolylineResult result = await polylinePoints!.getRouteBetweenCoordinates(
  //       googleAPIKey,
  //       PointLatLng(currentLocation!.latitude!, currentLocation!.longitude!),
  //       PointLatLng(destinationLocation!.latitude!, destinationLocation!.longitude!),
  //       travelMode: TravelMode.driving,
  //       wayPoints: [PolylineWayPoint(location: "Sabo, Yaba Lagos Nigeria")]);
  //   if (result.points.isNotEmpty) {
  //     result.points.forEach((PointLatLng point) {
  //       polylineCoordinates.add(LatLng(point.latitude, point.longitude));
  //     });
  //   }
  //   _addPolyLine();
  // }

  getDirections() async {
    List<LatLng> polylineCoordinates = [];

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleAPIKey,
      PointLatLng(currentLocation!.latitude!,currentLocation!.longitude!),
      PointLatLng(destinationLocation!.latitude!, destinationLocation!.longitude!),
      travelMode: TravelMode.driving,
    );

    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
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
    });
    addPolyLine(polylineCoordinates);
  }

  getUDirections( lat,  lng) async {
    List<LatLng> polylineCoordinates = [];

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleAPIKey,
      PointLatLng(currentLocation!.latitude!,currentLocation!.longitude!),
      PointLatLng(lat.latitude, lng.longitude),
      travelMode: TravelMode.driving,
    );

    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
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
    });
    addPolyLine(polylineCoordinates);
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
      color: Colors.red,
      points: polylineCoordinates,
      width: 5,
    );
    polylines[id] = polyline;
    setState(() {});
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
          markerId: MarkerId('sourcePin'),
          onTap: () {
            setState(() {
              currentlySelectedPin = sourcePinInfo!;
              pinPillPosition = 0;
            });
          },
          position: pinPosition, // updated position
          icon: sourceIcon!));
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