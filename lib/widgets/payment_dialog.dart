import 'package:driver/methods/common_methods.dart';
import 'package:driver/methods/firestore_methods.dart';
import 'package:driver/models/trip_details.dart';
import 'package:flutter/material.dart';

class PaymentDialog extends StatefulWidget {
  const PaymentDialog({super.key, required this.tripDetails});

  final TripDetails tripDetails;

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  CommonMethods commonMethods = const CommonMethods();
  updateTripStatusToEnded() async {
    await FirestoreMethods().updateDriverTotalEarnings(
        double.parse(widget.tripDetails.fareAmount!));
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
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 21,
            ),
            Text('Payment',
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.onSurface,
                    )),
            const SizedBox(
              height: 21,
            ),
            Divider(
              height: 1,
              color: Theme.of(context).dividerColor,
              thickness: 1,
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              '\$ ${widget.tripDetails.fareAmount}',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              'Please collect the fare amount of \$ ${widget.tripDetails.fareAmount} from the passenger.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(
              height: 21,
            ),
            const SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      await FirestoreMethods()
                          .confirmPayment(widget.tripDetails.tripId!);

                      await updateTripStatusToEnded();

                      commonMethods.playFairAmountReceivedSound();

                      if (context.mounted) {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      }

                      commonMethods.resumeLocationUpdates();
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
