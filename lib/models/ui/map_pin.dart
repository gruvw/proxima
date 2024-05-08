import "package:google_maps_flutter/google_maps_flutter.dart";

//custom map pin class used to display pins on the map
class MapPin {
  const MapPin({
    //unique id that identifies the pin
    //must be unique for each pin
    required this.id,
    //position of the pin on the map
    required this.position,
    //callback function that is called when we click on the pin
    required this.callbackFunction,
  });

  final String id;
  final LatLng position;
  final void Function()? callbackFunction;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MapPin &&
        other.id == id &&
        other.position == position &&
        other.callbackFunction == callbackFunction;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      position,
      callbackFunction,
    );
  }
}
