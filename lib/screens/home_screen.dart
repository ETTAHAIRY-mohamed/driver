import 'dart:async';
import 'dart:io';
import 'package:driver/global/global_var.dart';
import 'package:driver/methods/common_methods.dart';
import 'package:driver/methods/firestore_methods.dart';
import 'package:driver/methods/map_theme_methods.dart';
import 'package:driver/push_notification/push_notification_system.dart';
import 'package:driver/widgets/loading_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final Completer<GoogleMapController> googleMapCompleterController =
      Completer<GoogleMapController>();

  GoogleMapController? controllerGoogleMap;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final CommonMethods commonMethods = const CommonMethods();

  String driverStatusText = 'Go Online';
  Color driverStatusColor = Colors.green;

  DatabaseReference onlineDriversRef =
      FirebaseDatabase.instance.ref().child('onlineDrivers');

  getCurrentLiveLocationOfDriver() async {
    Position positionOfUser = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
    );
    currentPositionOfDriver = positionOfUser;

    LatLng positionOfUserInLatLng = LatLng(
        currentPositionOfDriver!.latitude, currentPositionOfDriver!.longitude);

    CameraPosition cameraPosition = CameraPosition(
      target: positionOfUserInLatLng,
      zoom: 14.4746,
    );

    controllerGoogleMap!
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  }

  setAndGetLocationUpdates() {
    homeTabPageStreamSubscription =
        Geolocator.getPositionStream().listen((Position position) {
      currentPositionOfDriver = position;

      if (isDriverAvailable) {
        Geofire.setLocation(
          _auth.currentUser!.uid,
          currentPositionOfDriver!.latitude,
          currentPositionOfDriver!.longitude,
        );

        LatLng positionOfDriverInLatLng =
            LatLng(position.latitude, position.longitude);

        controllerGoogleMap!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: positionOfDriverInLatLng,
              zoom: 14.4746,
            ),
          ),
        );
      }
    });
  }

  checkDriverAvailabilityOnServer() async {
    isDriverAvailableServerSide =
        await FirestoreMethods().getDriverAvailabilityStatus();

    if (isDriverAvailableServerSide == true) {
      Geofire.initialize('onlineDrivers');
      isGeofireInitialized = true;
      setState(() {
        driverStatusColor = Colors.red;
        driverStatusText = 'Go Offline';
        isDriverAvailable = true;
      });
    } else {
      setState(() {
        driverStatusColor = Colors.green;
        driverStatusText = 'Go Online';
        isDriverAvailable = false;
      });
    }
  }

  goOnline() async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            const LoadingDialog(messageText: 'Logging you in...'));

    bool initialized = await Geofire.initialize('onlineDrivers');

    if (initialized) {
      isGeofireInitialized = true;
      await commonMethods.saveDriverStatus(true);
      setState(() {
        isDriverAvailable = true;
      });
    } else {
      await commonMethods.saveDriverStatus(false);
      setState(() {
        isDriverAvailable = false;
      });
      if (mounted) {
        commonMethods.displaySnackBar(
            'Could not connect, please try again shortly', context);
      }
    }

    if (mounted) Navigator.pop(context);
  }

  goOffline() async {
    await homeTabPageStreamSubscription?.cancel();
    homeTabPageStreamSubscription = null;

    if (mounted) {
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const LoadingDialog(messageText: 'Logging you out...'));
    }

    await commonMethods.checkGeoFireInitialization();

    commonMethods.saveDriverStatus(false);

    commonMethods.pauseLocationUpdates();

    if (mounted) Navigator.pop(context);
  }

  initializePushNotificationSystem() async {
    PushNotificationSystem pushNotificationSystem = PushNotificationSystem();
    await pushNotificationSystem.generateDeviceRegistrationToken();
    if (context.mounted) {
      // ignore: use_build_context_synchronously
      await pushNotificationSystem.startListeningForNewNotifications(context);
    }
  }

  @override
  void initState() {
    checkDriverAvailabilityOnServer();
    initializePushNotificationSystem();
    super.initState();
  }

  setDriverAvailability() {
    commonMethods.loadDriverStatus().then((isOnline) {
      if (isOnline && isDriverAvailableServerSide) {
        setState(() {
          driverStatusColor = Colors.red;
          driverStatusText = 'Go Offline';
          isDriverAvailable = true;
        });
      } else {
        setState(() {
          driverStatusColor = Colors.green;
          driverStatusText = 'Go Online';
          isDriverAvailable = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    //commonMethods.checkGeoFireInitialization();

    //checkDriverAvailabilityOnServer();
    //setDriverAvailability();

    return Stack(
      children: [
        GoogleMap(
          padding: Platform.isAndroid
              ? const EdgeInsets.only(top: 35, right: 10)
              : const EdgeInsets.only(bottom: 16, right: 28, left: 16),
          myLocationButtonEnabled: true,
          zoomControlsEnabled: false,
          mapType: MapType.normal,
          myLocationEnabled: true,
          initialCameraPosition: casablancaInitialPosition,
          onMapCreated: (GoogleMapController mapController) {
            controllerGoogleMap = mapController;
            MapThemeMethods().updateMapTheme(controllerGoogleMap!, context);

            googleMapCompleterController.complete(controllerGoogleMap);

            getCurrentLiveLocationOfDriver();
          },
        ),

        // go online offline container
        Positioned(
          top: 41,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isDismissible: false,
                    builder: (BuildContext context) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 15,
                              spreadRadius: 0.5,
                              offset: Offset(0.7, 0.7),
                            ),
                          ],
                        ),
                        height: 221,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 18,
                          ),
                          child: Column(
                            children: [
                              const SizedBox(height: 12),
                              Text(
                                (!isDriverAvailable)
                                    ? 'GO ONLINE'
                                    : 'GO OFFLINE',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium!
                                    .copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                (!isDriverAvailable)
                                    ? 'You are about to become available to receive trip requests from passengers'
                                    : 'You are about to become unavailable to receive trip requests from passengers',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(
                                      color: Theme.of(context).hintColor,
                                    ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        if (mounted) Navigator.pop(context);
                                      },
                                      child: Text(
                                        'Cancel',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        if (!isDriverAvailable) {
                                          await goOnline();
                                          //close the bottom sheet
                                          if (context.mounted) {
                                            Navigator.pop(context);
                                          }

                                          setState(() {
                                            driverStatusColor = Colors.red;
                                            driverStatusText = 'Go Offline';
                                            isDriverAvailable = true;
                                          });

                                          setAndGetLocationUpdates();
                                        } else {
                                          await goOffline();

                                          if (context.mounted) {
                                            Navigator.pop(context);
                                          }

                                          setState(() {
                                            driverStatusColor = Colors.green;
                                            driverStatusText = 'Go Online';
                                            isDriverAvailable = false;
                                          });
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: (!isDriverAvailable)
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                      child: Text(
                                        'Confirm',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: driverStatusColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  driverStatusText,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}
