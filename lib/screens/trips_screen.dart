import 'package:driver/methods/firestore_methods.dart';
import 'package:driver/widgets/trip_list_item.dart';
import 'package:flutter/material.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  getTrips() async {
    // get the trips of the user
    await FirestoreMethods().getTrips()?.then((value) {
      setState(() {
        endedTripDetails = value;
      });
    });
  }

  List endedTripDetails = [];

  @override
  Widget build(BuildContext context) {
    getTrips();

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 32,
        ),
        width: double.infinity,
        child: ListView(
          padding: const EdgeInsets.all(8.0),
          children: [
            const SizedBox(
              height: 100,
            ),
            Image.asset(
              'assets/images/trips.png',
              height: 200,
              fit: BoxFit.fitHeight,
            ),
            const SizedBox(
              height: 20,
            ),
            endedTripDetails.isEmpty
                ? const Column(
                    children: [
                      SizedBox(
                        height: 200,
                      ),
                      Center(
                        child: Text('No trips found'),
                      ),
                    ],
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: endedTripDetails.length,
                    itemBuilder: (ctx, index) {
                      if (endedTripDetails.isNotEmpty) {
                        return TripListItem(
                            endedTripDetails: endedTripDetails[index]);
                      } else {
                        return const Text('No trips found');
                      }
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
