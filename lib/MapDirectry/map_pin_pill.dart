import 'package:flutter/material.dart';
import 'package:translation_rental/MapDirectry/pin_pill_info.dart';

class MapPinPillComponent extends StatefulWidget {

  double? pinPillPosition;
  PinInformation? currentlySelectedPin;
  String? source;
  String? destination;

  MapPinPillComponent({ this.pinPillPosition, this.currentlySelectedPin,this.source,this.destination});

  @override
  State<StatefulWidget> createState() => MapPinPillComponentState();
}

class MapPinPillComponentState extends State<MapPinPillComponent> {

  @override
  Widget build(BuildContext context) {

    return AnimatedPositioned(
      bottom: widget.pinPillPosition,
      right: 0,
      left: 0,
      duration: Duration(milliseconds: 200),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: EdgeInsets.all(20),
          height: 70,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(50)),
              boxShadow: <BoxShadow>[
                BoxShadow(blurRadius: 20, offset: Offset.zero, color: Colors.grey.withOpacity(0.5))
              ]
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 50, height: 50,
                margin: const EdgeInsets.only(left: 10),
                child: ClipOval(child: Image.asset(widget.currentlySelectedPin!.avatarPath!, fit: BoxFit.cover )),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(left: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const SizedBox(height: 15.0,),
                      Text(widget.currentlySelectedPin!.locationName!, style: TextStyle(color: widget.currentlySelectedPin!.labelColor)),
                      // Text('Address ${widget.source}', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Expanded(child: Text(widget.currentlySelectedPin!.locationName =="Start Location" ? widget.source.toString() : widget.destination.toString(), style: const TextStyle(fontSize: 12, color: Colors.grey))),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(15),
                child: Image.asset(widget.currentlySelectedPin!.pinPath!, width: 50, height: 50),
              )
            ],
          ),
        ),
      ),
    );
  }

}