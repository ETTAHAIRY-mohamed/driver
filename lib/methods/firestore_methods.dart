import 'dart:io';
import 'dart:math';

import 'package:driver/global/global_var.dart';
import 'package:driver/models/ended_trip_details.dart';
import 'package:driver/models/trip_details.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class FirestoreMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;

  setDeviceToken(String token) async {
    String phoneModel = 'unknown';
    String? deviceId = 'unknown';

    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      phoneModel = androidInfo.model;
      deviceId = androidInfo.id; // Unique device ID for Android
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      phoneModel = iosInfo.utsname.machine;
      deviceId = iosInfo.identifierForVendor; // Unique device ID for iOS
    }

    // Check if the phone is already registered
    DocumentSnapshot doc =
        await _firestore.collection('tokens').doc(user!.uid).get();
    if (doc.exists) {
      // Check if the device is already registered
      List<dynamic> devices = doc.get('devices');
      for (var device in devices) {
        if (device['id'] == deviceId && device['token'] == token) {
          return;
        } else if (device['id'] == deviceId && device['token'] != token) {
          // Update the device token in the Firestore database
          await _firestore.collection('tokens').doc(user!.uid).update({
            'devices': FieldValue.arrayRemove([
              {
                'id': deviceId,
                'model': phoneModel,
                'token': device['token'],
              }
            ])
          });
          await _firestore.collection('tokens').doc(user!.uid).update({
            'devices': FieldValue.arrayUnion([
              {
                'id': deviceId,
                'model': phoneModel,
                'token': token,
              }
            ])
          });
          return;
        }
      }
      // Update the device token in the Firestore database
      await _firestore.collection('tokens').doc(user!.uid).update({
        'devices': FieldValue.arrayUnion([
          {
            'id': deviceId,
            'model': phoneModel,
            'token': token,
          }
        ])
      });
    } else {
      // Set the device token in the Firestore database
      await _firestore.collection('tokens').doc(user!.uid).set({
        'devices': [
          {
            'id': deviceId,
            'model': phoneModel,
            'token': token,
          },
        ],
      });
    }
  }

  Future<TripDetails?> retrieveTripDataFromFirebase(String tripId) async {
    // Retrieve the trip data from the Firestore database
    DocumentSnapshot snap =
        await _firestore.collection('tripRequests').doc(tripId).get();

    if (snap.exists) {
      // get the trip details

      TripDetails tripDetails = TripDetails();
      tripDetails.tripId = tripId;

      Map<String, dynamic>? data = snap.data() as Map<String, dynamic>?;

      tripDetails.pickupLocationCoordinates = LatLng(
        double.parse(data?['pickUpLocationCoordinates']['latitude'] ?? '0'),
        double.parse(data?['pickUpLocationCoordinates']['longitude'] ?? '0'),
      );
      tripDetails.pickupAddress = data?['pickUpAddress'] ?? 'Nearby';

      tripDetails.destinationLocationCoordinates = LatLng(
        double.parse(data?['dropOffLocationCoordinates']['latitude'] ?? '0'),
        double.parse(data?['dropOffLocationCoordinates']['longitude'] ?? '0'),
      );
      tripDetails.dropOffAddress = data?['dropOffAddress'] ?? '';

      tripDetails.passengerDisplayName =
          data?['passengerInfo']['displayName'] ?? '';
      tripDetails.passengerPhoneNumber =
          data?['passengerInfo']['phoneNumber'] ?? '';

      tripDetails.fareAmount = data?['fareAmount'] ?? '';

      return tripDetails;
    }
    return null;
  }

  Future<bool> acceptTripRequestStatus(String requestId) async {
    //check the current request state
    DocumentSnapshot snap =
        await _firestore.collection('tripRequests').doc(requestId).get();

    if (snap.exists) {
      Map<String, dynamic>? data = snap.data() as Map<String, dynamic>?;

      if (data?['status'] == 'accepted') {
        return false;
      }
    }

    // get driver informations
    DocumentSnapshot driverSnap =
        await _firestore.collection('drivers').doc(user!.uid).get();

    if (driverSnap.exists) {
      Map<String, dynamic>? driverData =
          driverSnap.data() as Map<String, dynamic>?;

      await _firestore.collection('tripRequests').doc(requestId).update({
        'driverInfo': {
          'uid': driverData?['uid'] ?? '',
          'displayName': driverData?['displayName'] ?? '',
          'phoneNumber': driverData?['phoneNumber'] ?? '',
          'photoUrl': driverData?['photoUrl'] ?? '',
          'email': driverData?['email'] ?? '',
          'vehiculeModel': driverData?['vehiculeModel'] ?? '',
          'vehiculeColor': driverData?['vehiculeColor'] ?? '',
          'vehiculePlateNumber': driverData?['vehiculePlateNumber'] ?? '',
        },
        'status': 'accepted',
        'driverLocation': {
          'latitude': currentPositionOfDriver!.latitude,
          'longitude': currentPositionOfDriver!.longitude,
        },
      });

      // update start time for current trip in trips subcollection of the earnings collection in uid doc in firestore
      await _firestore
          .collection('earnings')
          .doc(user!.uid)
          .collection('trips')
          .doc(requestId)
          .set({
        'acceptedAt': FieldValue.serverTimestamp(),
        'pickupAddress': snap['pickUpAddress'] ?? '',
        'dropOffAddress': snap['dropOffAddress'] ?? '',
        'fareAmount': snap['fareAmount'] ?? '',
        'pickUpLocationCoordinates': snap['pickUpLocationCoordinates'] ??
            {'latitude': 0, 'longitude': 0},
        'dropOffLocationCoordinates': snap['dropOffLocationCoordinates'] ??
            {'latitude': 0, 'longitude': 0},
        'status': 'accepted',
        'passengerInfo': snap['passengerInfo'] ?? {},
      }, SetOptions(merge: true));

      return true;
    }

    return false;
  }

  startTrip(String tripId) async {
    await _firestore
        .collection('earnings')
        .doc(user!.uid)
        .collection('trips')
        .doc(tripId)
        .update({
      'startedAt': FieldValue.serverTimestamp(),
    });
  }

  updateTripRequestDriverLocation(String tripId, LatLng currentPosition) async {
    // update driver location tripRequest
    Map<String, dynamic> updatedLocation = {
      'latitude': currentPosition.latitude,
      'longitude': currentPosition.longitude,
    };

    await _firestore
        .collection('tripRequests')
        .doc(tripId)
        .update({'driverLocation': updatedLocation});
  }

  updateFinalDriverLocation(String tripId, LatLng currentPosition) async {
    // update driver location tripRequest
    Map<String, dynamic> updatedLocation = {
      'latitude': currentPosition.latitude,
      'longitude': currentPosition.longitude,
    };

    await _firestore
        .collection('tripRequests')
        .doc(tripId)
        .update({'driverInfo.destinationCoordinates': updatedLocation});

    // update end time for current trip in trips subcollection of the earnings collection in uid doc in firestore
    await _firestore
        .collection('earnings')
        .doc(user!.uid)
        .collection('trips')
        .doc(tripId)
        .update({
      'endedAt': FieldValue.serverTimestamp(),
      'destinationCoordinates': updatedLocation,
    });
  }

  Future<bool> getDriverAvailabilityStatus() async {
    DatabaseReference dbRef = FirebaseDatabase.instance.ref('onlineDrivers');
    DataSnapshot snapshot = (await dbRef.child(user!.uid).once()).snapshot;

    if (snapshot.value != null) {
      // The child with the user ID exists
      return true;
    } else {
      // The child with the user ID does not exist
      return false;
    }
  }

  updateTripRequestStatus(String tripId, String status) async {
    if (status == 'onTrip') {
      await startTrip(tripId);
    }
    await _firestore.collection('tripRequests').doc(tripId).update({
      'status': status,
    });
  }

  cancelTripRequest(String tripId) async {
    try {
      DocumentSnapshot snap =
          await _firestore.collection('tripRequests').doc(tripId).get();

      if (snap.exists) {
        Map<String, dynamic>? data = snap.data() as Map<String, dynamic>?;

        if (data?['status'] == 'canceled') {
          return;
        }

        await _firestore.collection('tripRequests').doc(tripId).update({
          'status': 'canceled_by_driver',
        });
      }

      // delete the trip from the earnings collection
      DocumentSnapshot trip = await _firestore
          .collection('earnings')
          .doc(user!.uid)
          .collection('trips')
          .doc(tripId)
          .get();

      if (trip.exists) {
        await _firestore
            .collection('earnings')
            .doc(user!.uid)
            .collection('trips')
            .doc(tripId)
            .delete();
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  updateDriverTotalEarnings(double fareAmount) {
    _firestore.collection('earnings').doc(user!.uid).set({
      'totalEarnings': FieldValue.increment(fareAmount),
      'lastTripEarnings': fareAmount,
      'lastTripDate': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  confirmPayment(String tripId) async {
    try {
      await _firestore.collection('tripRequests').doc(tripId).update({
        'endedAt': FieldValue.serverTimestamp(),
        'paymentStatus': 'paid',
      });

      // update end time for current trip in trips subcollection of the earnings collection in uid doc in firestore
      await _firestore
          .collection('earnings')
          .doc(user!.uid)
          .collection('trips')
          .doc(tripId)
          .update({
        'endedAt': FieldValue.serverTimestamp(),
        'status': 'ended',
      });
    } on Exception {
      if (kDebugMode) {
        print('Error confirming payment');
      }
    }
  }

  Future<double> getTotalEarningsOfCurrentMonth() async {
    DateTime now = DateTime.now();
    DateTime firstDayOfCurrentMonth =
        DateTime(now.year, now.month, 1, 0, 0, 0, 0, 0);
    DateTime lastDayOfCurrentMonth =
        DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999, 999);

    double totalEarningsOfCurrentMonth = 0;

    try {
      QuerySnapshot<Map<String, dynamic>> snapshot;

      snapshot = await _firestore
          .collection('earnings')
          .doc(user!.uid)
          .collection('trips')
          .where('acceptedAt', isGreaterThanOrEqualTo: firstDayOfCurrentMonth)
          .where('acceptedAt', isLessThanOrEqualTo: lastDayOfCurrentMonth)
          .where('endedAt', isNull: false)
          .get();

      for (var doc in snapshot.docs) {
        totalEarningsOfCurrentMonth += double.parse(doc['fareAmount']);
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }

    return totalEarningsOfCurrentMonth;
  }

  Future<double> getTotalEarningsOfCurrentWeek() async {
    DateTime now = DateTime.now();
    DateTime firstDayOfCurrentWeek =
        now.subtract(Duration(days: now.weekday - 1));
    DateTime lastDayOfCurrentWeek = firstDayOfCurrentWeek.add(const Duration(
        days: 6,
        hours: 23,
        minutes: 59,
        seconds: 59,
        milliseconds: 999,
        microseconds: 999));

    double totalEarningsOfCurrentWeek = 0;

    try {
      QuerySnapshot<Map<String, dynamic>> snapshot;

      snapshot = await _firestore
          .collection('earnings')
          .doc(user!.uid)
          .collection('trips')
          .where('acceptedAt', isGreaterThanOrEqualTo: firstDayOfCurrentWeek)
          .where('acceptedAt', isLessThanOrEqualTo: lastDayOfCurrentWeek)
          .where('endedAt', isNull: false)
          .get();

      for (var doc in snapshot.docs) {
        totalEarningsOfCurrentWeek += double.parse(doc['fareAmount']);
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }

    return totalEarningsOfCurrentWeek;
  }

  Future<double> getTotalEarnedAmount() async {
    double totalEarnings = 0;

    try {
      DocumentSnapshot doc =
          await _firestore.collection('earnings').doc(user!.uid).get();

      if (doc.exists) {
        totalEarnings = double.parse(doc['totalEarnings'].toString());
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }

    return totalEarnings;
  }

  Future<List<EndedTripDetails>>? getTrips() async {
    // get the trips of the user from the earnings collection
    QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('earnings')
        .doc(user!.uid)
        .collection('trips')
        .where('endedAt', isNull: false)
        .orderBy('acceptedAt', descending: true)
        .get();

    List<EndedTripDetails> trips = [];

    for (var doc in snapshot.docs) {
      trips.add(EndedTripDetails.fromSnapshot(doc.data()));
    }

    return trips;
  }

  Future<int> getTripsCount() async {
    // get the trips of the user from the earnings collection
    QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('earnings')
        .doc(user!.uid)
        .collection('trips')
        .where('endedAt', isNull: false)
        .get();

    return snapshot.docs.length;
  }

  // get the total time spent on trips
  Future<int> getTotalTimeSpentOnTrips() async {
    int totalTimeSpentOnTrips = 0;

    try {
      QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection('earnings')
          .doc(user!.uid)
          .collection('trips')
          .where('endedAt', isNull: false)
          .get();

      for (var doc in snapshot.docs) {
        if (doc['startedAt'] != null && doc['endedAt'] != null) {
          DateTime startedAt = doc['startedAt'].toDate();
          DateTime endedAt = doc['endedAt'].toDate();

          totalTimeSpentOnTrips += endedAt.difference(startedAt).inMinutes;
        }
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }

    return totalTimeSpentOnTrips;
  }

  // get the total distance covered on trips
  Future<double> getTotalDistanceCoveredOnTrips() async {
    double totalDistanceCoveredOnTrips = 0;

    if (kDebugMode) {
      print(user!.uid);
    }

    try {
      QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection('earnings')
          .doc(user!.uid)
          .collection('trips')
          .where('endedAt', isNull: false)
          .get();

      for (var doc in snapshot.docs) {
        if (doc['pickUpLocationCoordinates'] != null &&
            doc['dropOffLocationCoordinates'] != null) {
          LatLng pickupLocationCoordinates = LatLng(
            double.parse(doc['pickUpLocationCoordinates']['latitude']),
            double.parse(doc['pickUpLocationCoordinates']['longitude']),
          );
          LatLng dropOffLocationCoordinates = LatLng(
            double.parse(doc['dropOffLocationCoordinates']['latitude']),
            double.parse(doc['dropOffLocationCoordinates']['longitude']),
          );

          totalDistanceCoveredOnTrips += distanceBetween(
            pickupLocationCoordinates.latitude,
            pickupLocationCoordinates.longitude,
            dropOffLocationCoordinates.latitude,
            dropOffLocationCoordinates.longitude,
          );
        }
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }

    return totalDistanceCoveredOnTrips;
  }

  distanceBetween(double startLatitude, double startLongitude,
      double endLatitude, double endLongitude) {
    const double pi = 3.1415926535897932;
    const double earthRadius = 6371.0;

    double dLat = (endLatitude - startLatitude) * (pi / 180.0);
    double dLon = (endLongitude - startLongitude) * (pi / 180.0);

    double a = (0.5 -
            cos(dLat) / 2 +
            cos(startLatitude * (pi / 180.0)) *
                cos(endLatitude * (pi / 180.0)) *
                (1 - cos(dLon)) /
                2) *
        2;

    return earthRadius * 2 * asin(sqrt(a));
  }
}
