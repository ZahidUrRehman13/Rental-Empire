
// class LocationScreen extends StatefulWidget {
//   const LocationScreen({Key? key}) : super(key: key);
//
//   @override
//   State<LocationScreen> createState() => _LocationScreenState();
// }
//
// class _LocationScreenState extends State<LocationScreen> {
//   GoogleMapController? _controller;
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: GoogleMap(
//           mapType: MapType.normal,
//           initialCameraPosition: const CameraPosition(
//             target: LatLng(22.888,88.987,),zoom: 12.0,
//           ),
//           onMapCreated: (GoogleMapController controller){
//                _controller=controller;
//           },
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';

import 'dart:async';

import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoder/geocoder.dart';


class LocationMap extends StatefulWidget {
  const LocationMap({Key? key}) : super(key: key);

  @override
  State<LocationMap> createState() => _LocationMapState();
}

class _LocationMapState extends State<LocationMap> {
  LatLng? latlong;
  CameraPosition? _cameraPosition;
  GoogleMapController? _controller ;
  final Set<Marker> _markers={};
  TextEditingController locationController = TextEditingController();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _cameraPosition=const CameraPosition(target: LatLng(0, 0),zoom: 10.0);
    getCurrentLocation();

  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      body: SafeArea(child: Stack(
        children: [
          (latlong!=null) ?GoogleMap(
            initialCameraPosition: _cameraPosition!,
            onMapCreated: (GoogleMapController controller){
              _controller=(controller);
              _controller!.animateCamera(

                  CameraUpdate.newCameraPosition(_cameraPosition!));
            },

            markers:_markers ,

          ):Container(),
          Positioned(
            top: 50.0,
            right: 15.0,
            left: 15.0,
            child: Container(
              height: 50.0,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3.0),
                color: Colors.white,
                boxShadow: const [
                  BoxShadow(
                      color: Colors.grey,
                      offset: Offset(1.0, 5.0),
                      blurRadius: 10,
                      spreadRadius: 3)
                ],
              ),
              child: TextField(
                cursorColor: Colors.black,
                controller: locationController,
                decoration: InputDecoration(
                  icon: Container(
                    margin: const EdgeInsets.only(left: 20, top: 0),
                    width: 10,
                    height: 10,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.green,
                    ),
                  ),
                  hintText: "pick up",
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.only(left: 15.0, top: 12.0),
                ),
              ),
            ),
          ),

        ],

      )),
    );
  }

  Future getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission != PermissionStatus.granted) {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission != PermissionStatus.granted) {
        getLocation();
      }
      return;
    }
    getLocation();
  }

  List<Address> results = [];
  getLocation() async
  {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    print(position.latitude);



    setState(() {
      latlong= LatLng(position.latitude, position.longitude);
      _cameraPosition=CameraPosition(target:latlong!,zoom: 15.0 );
      if(_controller!=null) {
        _controller?.animateCamera(

            CameraUpdate.newCameraPosition(_cameraPosition!));
      }



      _markers.add(Marker(markerId: const MarkerId("a"),draggable:true,position: latlong!,icon: BitmapDescriptor.defaultMarkerWithHue(

          BitmapDescriptor.hueRed,),onDragEnd: (_currentlatLng){
        latlong = _currentlatLng;

      }));
    });

    getCurrentAddress();
  }

  getCurrentAddress() async
  {

    final coordinates = Coordinates(latlong!.latitude, latlong!.longitude);
    results  = await Geocoder.local.findAddressesFromCoordinates(coordinates);
    var first = results.first;
    String address;
    address = first.featureName;
    address =   " $address, ${first.subLocality}" ;
    address =  " $address, ${first.subLocality}" ;
    address =  " $address, ${first.locality}" ;
    address =  " $address, ${first.countryName}" ;
    address = " $address, ${first.postalCode}" ;

    locationController.text = address;
  }
}
