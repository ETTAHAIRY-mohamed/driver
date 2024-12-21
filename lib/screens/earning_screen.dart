import 'package:driver/methods/firestore_methods.dart';
import 'package:flutter/material.dart';

class EarningScreen extends StatefulWidget {
  const EarningScreen({super.key});

  @override
  State<EarningScreen> createState() => _EarningScreenState();
}

class _EarningScreenState extends State<EarningScreen> {
  double? totalEarning;

  double? currentMonthEarning;

  double? currentWeekEarning;

  final FirestoreMethods _firestoreMethods = FirestoreMethods();

  getEarning() async {
    // get the total earning of the user
    totalEarning = await _firestoreMethods.getTotalEarnedAmount();
    // get the earning of the current month
    currentMonthEarning =
        await _firestoreMethods.getTotalEarningsOfCurrentMonth();
    // get the earning of the current week
    currentWeekEarning =
        await _firestoreMethods.getTotalEarningsOfCurrentWeek();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // In this screen a statitcs of earning will be shown based on the user's earning
    // The user can see the total earning, the earning of the current month, and the earning of the current week

    getEarning();

    return Scaffold(
        body: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          const SizedBox(
            height: 100,
          ),
          Image.asset(
            'assets/images/total_earnings.png',
            height: 200,
            fit: BoxFit.cover,
          ),
          const SizedBox(
            height: 100,
          ),
          // Total Earning
          Card(
            color: Theme.of(context).cardColor.withOpacity(0.9),
            child: ListTile(
              title: Text(
                'Total Earning',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              subtitle: Text(
                totalEarning != null ? totalEarning!.toStringAsFixed(2) : '0',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          // Earning of the current month
          ListTile(
            title: const Text('Earning of the current month',
                style: TextStyle(fontSize: 22)),
            subtitle: Text(
              currentMonthEarning != null
                  ? currentMonthEarning!.toStringAsFixed(2)
                  : '0',
              style: const TextStyle(fontSize: 18),
            ),
          ),
          // Earning of the current week
          ListTile(
            title: const Text('Earning of the current week',
                style: TextStyle(fontSize: 22)),
            subtitle: Text(
                currentWeekEarning != null
                    ? currentWeekEarning!.toStringAsFixed(2)
                    : '0',
                style: const TextStyle(fontSize: 18)),
          ),
        ],
      ),
    ));
  }
}
