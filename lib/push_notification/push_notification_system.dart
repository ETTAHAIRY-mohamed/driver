import 'package:driver/methods/firestore_methods.dart';
import 'package:driver/widgets/loading_dialog.dart';
import 'package:driver/widgets/notification_dialog.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PushNotificationSystem {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  generateDeviceRegistrationToken() async {
    String? token = await messaging.getToken();
    if (token != null) await FirestoreMethods().setDeviceToken(token);

    messaging.subscribeToTopic('drivers');
    messaging.subscribeToTopic('users');

    messaging.onTokenRefresh.listen((newToken) {
      // Save the new token to Firestore
      FirestoreMethods().setDeviceToken(newToken);
    });
  }

  startListeningForNewNotifications(BuildContext context) async {
    ///1. Terminated
    //When the app is terminated
    messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        String tripId = message.data['tripId'];

        if (context.mounted) retrieveTripData(tripId, context);
      }
    });

    ///2. Foreground
    //When the app is open and it receive a push notification
    FirebaseMessaging.onMessage.listen((RemoteMessage? message) {
      if (message != null) {
        String tripId = message.data['tripId'];

        if (context.mounted) retrieveTripData(tripId, context);
      }
    });

    ///3. Background
    //when the app is in the background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage? message) {
      if (message != null) {
        String tripId = message.data['tripId'];

        if (context.mounted) retrieveTripData(tripId, context);
      }
    });
  }

  retrieveTripData(String tripId, BuildContext context) async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const LoadingDialog(
              messageText: 'Loading Trip Data...',
            ));
    var response =
        await FirestoreMethods().retrieveTripDataFromFirebase(tripId);

    if (kDebugMode) {
      print('Response: $response');
    }

    if (context.mounted) Navigator.of(context).pop();

    if (response != null) {
      if (context.mounted) {
        showDialog(
            context: context,
            builder: (context) => NotificationDialog(
                  tripDetails: response,
                ));
      }
    }
  }
}