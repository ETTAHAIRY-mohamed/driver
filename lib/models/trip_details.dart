import 'package:google_maps_flutter/google_maps_flutter.dart';

class TripDetails {
  String? tripId;
  LatLng? pickupLocationCoordinates;
  String? pickupAddress;
  LatLng? destinationLocationCoordinates;
  String? dropOffAddress;

  String? passengerDisplayName;
  String? passengerPhoneNumber;
  String? fareAmount;
  String? paymentStatus;

  TripDetails({
    this.tripId,
    this.pickupLocationCoordinates,
    this.pickupAddress,
    this.destinationLocationCoordinates,
    this.dropOffAddress,
    this.passengerDisplayName,
    this.passengerPhoneNumber,
    this.fareAmount,
    this.paymentStatus,
  });
}
