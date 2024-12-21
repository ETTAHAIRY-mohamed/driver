import 'package:google_maps_flutter/google_maps_flutter.dart';

class EndedTripDetails {
  String? tripId;
  LatLng? dropOffLocationCoordinates;
  LatLng? pickUpLocationCoordinates;
  Map<String, dynamic>? passengerInfo;
  DateTime? acceptedAt;
  DateTime? startedAt;
  DateTime? endedAt;
  String? status;
  String? fareAmout;

  String? pickUpAddress;
  String? dropOffAddress;

  LatLng? destinationCoordinates;

  EndedTripDetails(
      {this.tripId,
      this.dropOffLocationCoordinates,
      this.pickUpLocationCoordinates,
      this.passengerInfo,
      this.acceptedAt,
      this.startedAt,
      this.endedAt,
      this.status,
      this.fareAmout,
      this.pickUpAddress,
      this.dropOffAddress,
      this.destinationCoordinates});

  EndedTripDetails.fromSnapshot(Map<String, dynamic> snapshot) {
    double dropOffLat = double.parse(
        snapshot['dropOffLocationCoordinates']['latitude'].toString());
    double dropOffLng = double.parse(
        snapshot['dropOffLocationCoordinates']['longitude'].toString());

    LatLng dropOffLocationCoordinatesLatLng = LatLng(dropOffLat, dropOffLng);

    dropOffLocationCoordinates = dropOffLocationCoordinatesLatLng;

    double pickUpLat = double.parse(
        snapshot['pickUpLocationCoordinates']['latitude'].toString());
    double pickUpLng = double.parse(
        snapshot['pickUpLocationCoordinates']['longitude'].toString());

    LatLng pickUpLocationCoordinatesLatLng = LatLng(pickUpLat, pickUpLng);
    pickUpLocationCoordinates = pickUpLocationCoordinatesLatLng;

    passengerInfo = snapshot['passengerInfo'];
    acceptedAt = snapshot['acceptedAt'].toDate();
    startedAt = snapshot['startedAt'].toDate();
    endedAt = snapshot['endedAt'].toDate();
    status = snapshot['status'];
    fareAmout = snapshot['fareAmount'];
    pickUpAddress = snapshot['pickUpAddress'];
    dropOffAddress = snapshot['dropOffAddress'];

    double destinationLat =
        double.parse(snapshot['destinationCoordinates']['latitude'].toString());
    double destinationLng = double.parse(
        snapshot['destinationCoordinates']['longitude'].toString());

    LatLng destinationCoordinatesLatLng =
        LatLng(destinationLat, destinationLng);
    destinationCoordinates = destinationCoordinatesLatLng;
  }
}
