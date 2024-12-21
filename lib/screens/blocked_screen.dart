import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class BlockedScreen extends StatelessWidget {
  const BlockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 200,
              width: 200,
              child: Image.asset('assets/images/user_blocked.png'),
            ),
            const SizedBox(height: 16),
            Text('You have been blocked!',
                style: Theme.of(context).textTheme.displayMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Text(
              'Please contact the administrator for more information.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final Uri params = Uri(
                  scheme: 'mailto',
                  path: 'admin@ecocargo.com',
                  query:
                      'subject=Account Blocked&body=My account has been blocked. Please provide further information.',
                );

                String url = params.toString();
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url));
                } else {
                  if (kDebugMode) {
                    print('Could not launch $url');
                  }
                }
              },
              child: const Text('Email Us'),
            ),
            const SizedBox(height: 16),
            Text(
              'Thank you!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    );
  }
}
