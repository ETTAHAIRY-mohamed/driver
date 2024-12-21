import 'package:flutter/material.dart';

class InfoDialogWithImage extends StatefulWidget {
  const InfoDialogWithImage(
      {super.key, required this.title, required this.content, this.imageUrl});

  final String title;
  final String content;
  final String? imageUrl;

  @override
  State<InfoDialogWithImage> createState() => _InfoDialogWithImageState();
}

class _InfoDialogWithImageState extends State<InfoDialogWithImage> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  height: 12,
                ),
                widget.imageUrl != null
                    ? CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(widget.imageUrl!),
                      )
                    : const SizedBox.shrink(),
                const SizedBox(
                  height: 12,
                ),
                Text(
                  widget.title,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(fontWeight: FontWeight.bold, fontSize: 22),
                ),
                const SizedBox(
                  height: 12,
                ),
                Text(
                  widget.content,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: 32,
                ),
                SizedBox(
                  width: 202,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
