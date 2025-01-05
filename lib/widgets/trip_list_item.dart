import 'package:driver/models/ended_trip_details.dart';
import 'package:driver/providers/driver_provider.dart';
import 'package:driver/screens/trip_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class TripListItem extends StatelessWidget {
  const TripListItem({super.key, required this.endedTripDetails});

  final EndedTripDetails endedTripDetails;

  String getLocationImage(BuildContext context) {
    final lat = endedTripDetails.dropOffLocationCoordinates!.latitude;
    final lng = endedTripDetails.dropOffLocationCoordinates!.longitude;
    // get the first letter of the driver name
    final label = Provider.of<DriverProvider>(context, listen: false)
        .getUser!
        .displayName[0]
        .toUpperCase();
     return 'https://maps.googleapis.com/maps/api/geocode/json?center=$lat,$lng=&zoom=16&size=600x300&maptype=roadmap&markers=color:red%7Clabel:$label%7C$lat,$lng&key=${dotenv.env['GOOGLE_MAPS_NO_RESTRICTION_API_KEY']}';

    //  return 'https://maps.googleapis.com/maps/api/staticmap?center=$lat,$lng=&zoom=16&size=600x300&maptype=roadmap&markers=color:red%7Clabel:$label%7C$lat,$lng&key=${dotenv.env['GOOGLE_MAPS_NO_RESTRICTION_API_KEY']}';
  }
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 2) {
      return 'Yesterday';
    } else if (difference.inDays < 365) {
      return DateFormat('d MMM').format(date); // e.g. 12 Jul
    } else {
      return DateFormat('d MMM, yyyy').format(date); // e.g. 12 Jul, 2022
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black87.withOpacity(0.2)),
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        color: Theme.of(context).canvasColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.2), // change color to a semi-transparent black
            blurRadius: 10.0, // reduce blur radius
            spreadRadius: 1.0, // increase spread radius
            offset: const Offset(
              0.0, // change x-offset to 0
              2.0, // increase y-offset to make shadow appear below the box
            ),
          )
        ],
      ),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (context) =>
                TripDetailsScreen(endedTripDetails: endedTripDetails))),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Image.network(
                getLocationImage(context),
                fit: BoxFit.cover,
              ),
              Positioned(
                bottom: 10,
                left: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.black.withOpacity(0.5)
                            : Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 290,
                        ),
                        child: Text(
                          overflow: TextOverflow.ellipsis,
                          endedTripDetails.dropOffAddress!,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      endedTripDetails.passengerInfo?['displayName'],
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 10,
                right: 10,
                child: Text(
                  _formatDate(endedTripDetails.endedAt!),
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
