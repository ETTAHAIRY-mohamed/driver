import 'dart:async';
import 'dart:io';

import 'package:driver/global/global_var.dart';
import 'package:driver/methods/common_methods.dart';
import 'package:driver/methods/firestore_methods.dart';
import 'package:driver/methods/map_theme_methods.dart';
import 'package:driver/models/trip_details.dart';
import 'package:driver/widgets/info_dialog.dart';
import 'package:driver/widgets/loading_dialog.dart';
import 'package:driver/widgets/payment_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class NewTripScreen extends StatefulWidget {
  const NewTripScreen({super.key, required this.tripDetails});

  final TripDetails tripDetails;

  @override
  State<NewTripScreen> createState() => _NewTripScreenState();
}

class _NewTripScreenState extends State<NewTripScreen> {
  final FirestoreMethods _firestoreMethods = FirestoreMethods();

  final CommonMethods _commonMethods = const CommonMethods();

  final Completer<GoogleMapController> googleMapCompleterController =
      Completer<GoogleMapController>();

  GoogleMapController? controllerGoogleMap;

  PolylinePoints polylinePoints = PolylinePoints();

  List<LatLng> polylineCoordinates = [];

  Set<Marker> markerSet = {};

  Set<Circle> circleSet = {};

  Set<Polyline> polylines = {};

  BitmapDescriptor? movingMarkerIcon;

  bool isRequestingDirection = false;

  String statusOfTrip = 'accepted';

  String durationText = '';

  String distanceText = '';

  String buttonTitle = 'Arrived';

  Color buttonColor = Colors.blueAccent;

  bool isButtonEnabled = true;

  StreamSubscription<DocumentSnapshot>? tripRequestStreamSubscription;

  makeMarker() async {
    if (movingMarkerIcon == null) {
      ImageConfiguration imageConfiguration =
          createLocalImageConfiguration(context, size: const Size(38, 38));

      BitmapDescriptor.asset(
              imageConfiguration, 'assets/images/pin_map_tracking.png')
          .then((value) {
        movingMarkerIcon = value;
      });
    }
  }

  drawRoute(LatLng start, LatLng end) async {
    showDialog(
      context: context,
      builder: (context) => const LoadingDialog(
        messageText: 'Please wait...',
      ),
    );

    var tripDetailsInfo =
        await CommonMethods.getDirectionDetailsFromApi(start, end);

    if (mounted) Navigator.pop(context);

    List<PointLatLng> latlngPoints =
        polylinePoints.decodePolyline(tripDetailsInfo!.encodedPoints!);

    polylineCoordinates.clear();

    if (latlngPoints.isNotEmpty) {
      for (var point in latlngPoints) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    }
    // draw polyline
    polylines.clear();

    setState(() {
      Polyline polyline = Polyline(
        polylineId: const PolylineId('polylineId'),
        color: Colors.blue,
        points: polylineCoordinates,
        width: 5,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );

      polylines.add(polyline);
    });
    // fit polyline into the map
    LatLngBounds latLngBounds;

    if (start.latitude > end.latitude && start.longitude > end.longitude) {
      latLngBounds = LatLngBounds(southwest: end, northeast: start);
    } else if (start.longitude > end.longitude) {
      latLngBounds = LatLngBounds(
        southwest: LatLng(start.latitude, end.longitude),
        northeast: LatLng(end.latitude, start.longitude),
      );
    } else if (start.latitude > end.latitude) {
      latLngBounds = LatLngBounds(
        southwest: LatLng(end.latitude, start.longitude),
        northeast: LatLng(start.latitude, end.longitude),
      );
    } else {
      latLngBounds = LatLngBounds(southwest: start, northeast: end);
    }

    controllerGoogleMap!
        .animateCamera(CameraUpdate.newLatLngBounds(latLngBounds, 70));

    //add marker
    Marker startMarker = Marker(
      markerId: const MarkerId('startMarkerId'),
      position: start,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: const InfoWindow(title: 'Start'),
    );

    Marker endMarker = Marker(
      markerId: const MarkerId('endMarkerId'),
      position: end,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      infoWindow: const InfoWindow(title: 'End'),
    );

    setState(() {
      markerSet.add(startMarker);
      markerSet.add(endMarker);
    });

    //add cicrle
    Circle startCircle = Circle(
      circleId: const CircleId('startCircleId'),
      radius: 12,
      center: start,
      strokeColor: Colors.green,
      fillColor: Colors.green,
    );

    Circle endCircle = Circle(
      circleId: const CircleId('endCircleId'),
      radius: 12,
      center: end,
      strokeColor: Colors.red,
      fillColor: Colors.red,
    );

    setState(() {
      circleSet.add(startCircle);
      circleSet.add(endCircle);
    });
  }

  getLiveLocationUpdates() {
    LatLng lastPosition = const LatLng(0, 0);

    newTripStreamSubscription =
        Geolocator.getPositionStream().listen((Position position) {
      currentPositionOfDriver = position;

      LatLng currentPosition = LatLng(position.latitude, position.longitude);

      Marker carMarker = Marker(
        markerId: const MarkerId('carMarkerId'),
        position: currentPosition,
        icon: movingMarkerIcon!,
        infoWindow: const InfoWindow(title: 'Current Location'),
      );

      setState(() {
        CameraPosition cameraPosition =
            CameraPosition(target: currentPosition, zoom: 16);

        controllerGoogleMap!
            .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

        markerSet
            .removeWhere((marker) => marker.markerId.value == 'carMarkerId');

        markerSet.add(carMarker);
      });

      lastPosition = currentPosition;

      //update trip details informations
      updateTripDetailsInformations();

      // update driver location tripRequest
      FirestoreMethods().updateTripRequestDriverLocation(
          widget.tripDetails.tripId!, lastPosition);
    });
  }

  updateTripDetailsInformations() async {
    if (!isRequestingDirection) {
      isRequestingDirection = true;

      if (currentPositionOfDriver == null) {
        return;
      }

      LatLng driverCurrentPositionLatLng = LatLng(
        currentPositionOfDriver!.latitude,
        currentPositionOfDriver!.longitude,
      );

      LatLng dropOffDestinationLocationLatLng;

      if (statusOfTrip == 'accepted') {
        dropOffDestinationLocationLatLng =
            widget.tripDetails.pickupLocationCoordinates!;
      } else {
        dropOffDestinationLocationLatLng =
            widget.tripDetails.destinationLocationCoordinates!;
      }

      var driverToDestinationDirectionDetails =
          await CommonMethods.getDirectionDetailsFromApi(
              driverCurrentPositionLatLng, dropOffDestinationLocationLatLng);

      if (driverToDestinationDirectionDetails != null) {
        isRequestingDirection = false;
        setState(() {
          durationText = driverToDestinationDirectionDetails.durationText!;
          distanceText = driverToDestinationDirectionDetails.distanceText!;
        });
      }
    }
  }

  endTrip() async {
    newTripStreamSubscription!.cancel();

    _commonMethods.playTripEndedSound();

    var driverPosistion = LatLng(
      currentPositionOfDriver!.latitude,
      currentPositionOfDriver!.longitude,
    );

    await _firestoreMethods.updateFinalDriverLocation(
        widget.tripDetails.tripId!, driverPosistion);

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PaymentDialog(tripDetails: widget.tripDetails),
      );
    }
  }

  listenToTripRequestStatus() async {
    DocumentReference tripRequestRef = FirebaseFirestore.instance
        .collection('tripRequests')
        .doc(widget.tripDetails.tripId);

    tripRequestStreamSubscription =
        tripRequestRef.snapshots().listen((DocumentSnapshot snapshot) {
      if (snapshot.exists) {
        var data = snapshot.data() as Map<String, dynamic>;

        if (data['status'] != null) {
          statusOfTrip = data['status'];

          if (statusOfTrip == 'canceled') {
            whenPassengerCancelTrip();
          }
        }
      }
    });
  }

  whenPassengerCancelTrip() async {
    _commonMethods.playTripCanceledSound();

    await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const InfoDialog(
            title: 'Trip Canceled',
            content:
                'Unfortunately, the passenger has canceled the trip.\n We apologize for any inconvenience caused. We appreciate your understanding and wish you the best of luck on your next trip. Safe travels!'));

    newTripStreamSubscription!.cancel();

    tripRequestStreamSubscription!.cancel();

    await _commonMethods.resumeLocationUpdates();

    if (mounted) Navigator.pop(context);
  }

  cancelTrip() async {
    await _firestoreMethods.cancelTripRequest(widget.tripDetails.tripId!);

    await _commonMethods.resumeLocationUpdates();
  }

  @override
  void initState() {
    super.initState();

    listenToTripRequestStatus();
  }

  @override
  void dispose() {
    super.dispose();
    tripRequestStreamSubscription!.cancel();
  }

  @override
  Widget build(BuildContext context) {
    makeMarker();
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            padding: Platform.isAndroid
                ? const EdgeInsets.only(top: 55, right: 10)
                : const EdgeInsets.only(bottom: 16, right: 28, left: 16),
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
            myLocationEnabled: true,
            markers: markerSet,
            circles: circleSet,
            polylines: polylines,
            initialCameraPosition: casablancaInitialPosition,
            onMapCreated: (GoogleMapController mapController) async {
              controllerGoogleMap = mapController;
              MapThemeMethods().updateMapTheme(controllerGoogleMap!, context);

              googleMapCompleterController.complete(controllerGoogleMap);

              var driverCurrentPositionLatLng = LatLng(
                currentPositionOfDriver!.latitude,
                currentPositionOfDriver!.longitude,
              );

              var userPickUpoLocation =
                  widget.tripDetails.pickupLocationCoordinates;

              await drawRoute(
                  driverCurrentPositionLatLng, userPickUpoLocation!);

              // get the driver's current location
              getLiveLocationUpdates();
            },
          ),
          // cancel button
          Positioned(
            top: 50,
            left: 19,
            child: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text('Cancel Trip',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium!
                              .copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Theme.of(context).colorScheme.onSurface,
                              )),
                      content: const Text(
                          'Are you sure you want to cancel this trip?'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('No'),
                        ),
                        TextButton(
                          onPressed: () async {
                            await cancelTrip();

                            if (context.mounted) Navigator.pop(context);
                            if (context.mounted) Navigator.pop(context);
                          },
                          child: const Text('Yes'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Container(
                decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5,
                        spreadRadius: 0.5,
                        offset: Offset(0.7, 0.7),
                      )
                    ]),
                child: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  radius: 20,
                  child: Icon(
                    Icons.close,
                    color: Theme.of(context).canvasColor,
                  ),
                ),
              ),
            ),
          ),

          // trip details
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).canvasColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 16,
                    spreadRadius: 0.5,
                    offset: Offset(0.7, 0.7),
                  ),
                ],
              ),
              height: 300,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 18,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // trip duration + distance
                      Center(
                        child: Text(
                          '$durationText - $distanceText',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),

                      // user name + call button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // user name
                          Text(
                            widget.tripDetails.passengerDisplayName!,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // user phone number
                          GestureDetector(
                            onTap: () {
                              const CommonMethods().makePhoneCall(
                                  widget.tripDetails.passengerPhoneNumber!);
                            },
                            child: const Padding(
                              padding: EdgeInsets.only(right: 10),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.call,
                                    color: Colors.green,
                                  ),
                                  Text(
                                    'Call',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // pick up icon + location
                      SizedBox(
                        width: double.infinity,
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/images/pin_map_start_position.png',
                              height: 16,
                              width: 16,
                            ),
                            const SizedBox(
                              width: 18,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Pick Up',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    widget.tripDetails.pickupAddress!,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // dropOff icon + location

                      Row(
                        children: [
                          Image.asset(
                            'assets/images/pin_map_destination.png',
                            height: 16,
                            width: 16,
                          ),
                          const SizedBox(
                            width: 18,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Drop Off',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                widget.tripDetails.dropOffAddress!,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Center(
                        child: ElevatedButton(
                          onPressed: isButtonEnabled
                              ? () {
                                  setState(() {
                                    isButtonEnabled = false;
                                  });
                                  if (statusOfTrip == 'accepted') {
                                    // the driver will go to the user pick up location
                                    _firestoreMethods
                                        .updateTripRequestStatus(
                                            widget.tripDetails.tripId!,
                                            'arrived')
                                        .then((value) async {
                                      setState(() {
                                        statusOfTrip = 'arrived';
                                        buttonTitle = 'Start Trip';
                                        buttonColor = Colors.blueAccent;
                                      });

                                      showDialog(
                                          context: context,
                                          builder: (context) {
                                            return const LoadingDialog(
                                              messageText: 'Please wait...',
                                            );
                                          });

                                      await drawRoute(
                                          widget.tripDetails
                                              .pickupLocationCoordinates!,
                                          widget.tripDetails
                                              .destinationLocationCoordinates!);

                                      updateTripDetailsInformations();

                                      if (context.mounted) {
                                        Navigator.pop(context);
                                      }
                                    });
                                  } else if (statusOfTrip == 'arrived') {
                                    // the driver will start the trip
                                    _firestoreMethods
                                        .updateTripRequestStatus(
                                            widget.tripDetails.tripId!,
                                            'onTrip')
                                        .then((value) {
                                      setState(() {
                                        statusOfTrip = 'onTrip';
                                        buttonTitle = 'End Trip';
                                        buttonColor = Colors.red;
                                      });
                                    });
                                  } else if (statusOfTrip == 'onTrip') {
                                    // the driver will end the trip
                                    _firestoreMethods
                                        .updateTripRequestStatus(
                                            widget.tripDetails.tripId!, 'ended')
                                        .then((value) {
                                      endTrip();
                                    });
                                  }
                                  setState(() {
                                    isButtonEnabled = true;
                                  });
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isButtonEnabled ? buttonColor : Colors.grey,
                            disabledForegroundColor:
                                Colors.grey.withOpacity(0.38),
                            disabledBackgroundColor:
                                Colors.grey.withOpacity(0.12),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 80, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Text(
                            buttonTitle,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
