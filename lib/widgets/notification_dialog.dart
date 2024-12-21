import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:driver/global/global_var.dart';
import 'package:driver/methods/common_methods.dart';
import 'package:driver/methods/firestore_methods.dart';
import 'package:driver/models/trip_details.dart';
import 'package:driver/screens/new_trip_screen.dart';
import 'package:driver/widgets/loading_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class NotificationDialog extends StatefulWidget {
  const NotificationDialog({super.key, required this.tripDetails});

  final TripDetails tripDetails;

  @override
  State<NotificationDialog> createState() => _NotificationDialogState();
}

class _NotificationDialogState extends State<NotificationDialog> {
  String tripRequestStatus = '';

  CommonMethods commonMethods = const CommonMethods();

  cancelNotificationDialogAfter20Sec() {
    const oneTickPerSecond = Duration(seconds: 1);

    Timer.periodic(oneTickPerSecond, (timer) {
      timerDuration -= 1;
      if (tripRequestStatus == 'accepted') {
        timer.cancel();
        timerDuration = 20;
        audioPlayer.stop();
      } else if (timerDuration == 0) {
        timer.cancel();
        timerDuration = 20;
        audioPlayer.stop();
        Navigator.of(context).pop();
      }
    });
  }

  playNotificationSound() {
    audioPlayer.play(AssetSource('sounds/alert_sound.wav'));
  }

  acceptRequest() async {
    showDialog(
        context: context,
        builder: (context) =>
            const LoadingDialog(messageText: 'Accepting request...'));
    audioPlayer.stop();
    setState(() {
      tripRequestStatus = 'accepted';
    });
    bool requestAnswer = await FirestoreMethods()
        .acceptTripRequestStatus(widget.tripDetails.tripId!);

    if (mounted) Navigator.of(context).pop();

    if (requestAnswer) {
      if (mounted) Navigator.of(context).pop();
      if (kDebugMode) {
        print('Request accepted');
      }

      // disable homepage location updates
      commonMethods.pauseLocationUpdates();

      // go to new trip page
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                NewTripScreen(tripDetails: widget.tripDetails),
          ),
        );
      }
    } else {
      if (mounted) {
        Navigator.of(context).pop();
        commonMethods.displaySnackBar(
            'Request not available anymore! Good luck next time.', context);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    cancelNotificationDialogAfter20Sec();
    playNotificationSound();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      backgroundColor: Theme.of(context).canvasColor,
      child: Container(
        margin: const EdgeInsets.all(5),
        width: double.infinity,
        decoration: BoxDecoration(
            color: Theme.of(context).canvasColor,
            borderRadius: BorderRadius.circular(4)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 30,
            ),
            Image.asset(
              'assets/images/electric_car.png',
              width: 140,
            ),
            const SizedBox(
              height: 16.0,
            ),
            Text(
              'New Trip Request',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(
              height: 20,
            ),
            Divider(
              height: 1,
              color: Theme.of(context).dividerColor,
              thickness: 1,
            ),
            const SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // price
                  Row(
                    children: [
                      Text(
                        'Offered Price: ',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: Theme.of(context).colorScheme.onSurface),
                      ),
                      Text(
                        '\$ ${widget.tripDetails.fareAmount}',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  // pick up
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                        child: Text(
                          widget.tripDetails.pickupAddress!,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 15,
                  ),

                  // drop off
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        'assets/images/pin_map_destination.png',
                        height: 16,
                        width: 16,
                      ),
                      const SizedBox(
                        width: 18,
                      ),
                      Expanded(
                        child: Text(
                          widget.tripDetails.dropOffAddress!,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Divider(
              height: 1,
              color: Theme.of(context).dividerColor,
              thickness: 1,
            ),
            const SizedBox(
              height: 8,
            ),
            // accept and decline buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        audioPlayer.stop();
                        Navigator.of(context).pop();
                      },
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: Text(
                        'Decline',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await acceptRequest();
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                      child: Text(
                        'Accept',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 10,
            )
          ],
        ),
      ),
    );
  }
}
