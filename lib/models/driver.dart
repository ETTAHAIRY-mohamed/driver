import 'package:cloud_firestore/cloud_firestore.dart';

class Driver {
  String uid;
  final String displayName;
  final String phoneNumber;
  final String email;
  bool isBlocked = false;
  String? photoUrl;
  final String vehiculePlateNumber;
  final String vehiculeModel;
  final String vehiculeColor;

  Driver({
    required this.uid,
    required this.displayName,
    required this.phoneNumber,
    required this.email,
    required this.vehiculePlateNumber,
    required this.vehiculeModel,
    required this.vehiculeColor,
    this.isBlocked = false,
    this.photoUrl,
  });

  Driver.withoutUid({
    required this.displayName,
    required this.phoneNumber,
    required this.email,
    required this.vehiculePlateNumber,
    required this.vehiculeModel,
    required this.vehiculeColor,
  }) : uid = '';

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'displayName': displayName,
        'phoneNumber': phoneNumber,
        'email': email,
        'isBlocked': isBlocked,
        'photoUrl': photoUrl,
        'vehiculePlateNumber': vehiculePlateNumber,
        'vehiculeModel': vehiculeModel,
        'vehiculeColor': vehiculeColor,
      };

  static Driver? fromSnap(DocumentSnapshot snap) {
    Map<String, dynamic> snapshot;

    if (snap.toString().isNotEmpty) {
      snapshot = snap.data() as Map<String, dynamic>;

      return Driver(
        uid: snapshot['uid'], // Add the 'uid' named parameter here
        displayName: snapshot['displayName'],
        phoneNumber: snapshot['phoneNumber'],
        email: snapshot['email'],
        isBlocked: snapshot['isBlocked'],
        photoUrl: snapshot['photoUrl'],
        vehiculePlateNumber: snapshot['vehiculePlateNumber'],
        vehiculeModel: snapshot['vehiculeModel'],
        vehiculeColor: snapshot['vehiculeColor'],
      );
    }
    return null;
  }
}
