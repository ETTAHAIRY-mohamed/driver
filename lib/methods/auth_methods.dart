import 'package:driver/methods/common_methods.dart';
import 'package:driver/methods/storage_methods.dart';
import 'package:driver/models/driver.dart' as model;
import 'package:driver/providers/driver_provider.dart';
import 'package:driver/providers/navigation_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<model.Driver?> getUserDetails() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      DocumentSnapshot snap =
          await _firestore.collection('drivers').doc(currentUser.uid).get();
      if (snap.exists) {
        if (kDebugMode) {
          print(snap.toString());
        }
        return model.Driver.fromSnap(snap);
      }
    }

    return null;
  }

  Future<String> signupUser({
    required String email,
    required String password,
    required String username,
    required String userphone,
    required String vehiculeNumber,
    required String vehiculeModel,
    required String vehiculeColor,
    required Uint8List file,
    required BuildContext context,
  }) async {
    // Register user
    String res = 'Some error occured';

    try {
      if (username.isNotEmpty &&
          userphone.isNotEmpty &&
          email.isNotEmpty &&
          password.isNotEmpty &&
          file.isNotEmpty &&
          vehiculeNumber.isNotEmpty &&
          vehiculeModel.isNotEmpty &&
          vehiculeColor.isNotEmpty) {
        UserCredential userCredential = await _auth
            .createUserWithEmailAndPassword(email: email, password: password);

        await _auth.currentUser!.sendEmailVerification();

        if (userCredential.user != null) {
          String photoUrl = await StorageMethods()
              .uploadImageToStorage('driversProfilePics', file);

          model.Driver driver = model.Driver(
            uid: userCredential.user!.uid,
            displayName: username,
            phoneNumber: userphone,
            email: email,
            photoUrl: photoUrl,
            vehiculePlateNumber: vehiculeNumber,
            vehiculeModel: vehiculeModel,
            vehiculeColor: vehiculeColor,
          );
          // Save user data to Firestore
          await _firestore
              .collection('drivers')
              .doc(userCredential.user!.uid)
              .set(driver.toJson());

          // DocumentSnapshot newUserSnap = await _firestore
          //     .collection('drivers')
          //     .doc(userCredential.user!.uid)
          //     .get();

          // model.Driver? newUserFromFirestore =
          //     model.Driver.fromSnap(newUserSnap);

          if (context.mounted) {
            Provider.of<DriverProvider>(context, listen: false).setUser = driver;

            res = 'success';
            return res;
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        res = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        res = 'The account already exists for that email.';
      }
    } on Exception catch (e) {
      res = e.toString();
    }
    return res;
  }

  Future<String> updateDriverInfo(
    Map<String, dynamic> data,
    BuildContext context,
  ) async {
    String res = 'Some error occured';
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        if (data['email'] != currentUser.email) {
          try {
            await currentUser.verifyBeforeUpdateEmail(data['email']);

            res = 'email-verification-sent';

            return res;
          } on FirebaseAuthException catch (e) {
            if (e.code == 'email-already-in-use') {
              res = 'The account already exists for that email.';
            } else if (e.code == 'invalid-email') {
              res = 'The email address is badly formatted.';
            }
          } on Exception catch (e) {
            res = e.toString();
          }
        }

        if (data['password'] != null) {
          try {
            await currentUser.updatePassword(data['password']);

            res = 'success';

            data.remove('password');

            return res;
          } on FirebaseAuthException catch (e) {
            if (e.code == 'weak-password') {
              res = 'The password provided is too weak.';
            } else if (e.code == 'requires-recent-login') {
              res =
                  'The user must reauthenticate before this operation can be executed.';
            }
          } on Exception catch (e) {
            res = e.toString();
          }
          data.remove('password');
        }

        await _firestore
            .collection('drivers')
            .doc(currentUser.uid)
            .update(data);
        DocumentSnapshot snap =
            await _firestore.collection('drivers').doc(currentUser.uid).get();
        model.Driver? user = model.Driver.fromSnap(snap);
        if (context.mounted) {
          Provider.of<DriverProvider>(context, listen: false).setUser = user!;
          res = 'success';
        }
      }
    } catch (e) {
      res = e.toString();
    }
    return res;
  }

  // signin user
  Future<String> signinUser({
    required String email,
    required String password,
  }) async {
    String res = 'Some error occured';
    try {
      if (email.isNotEmpty && password.isNotEmpty) {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
            email: email, password: password);

        if (!userCredential.user!.emailVerified) {
          res = 'email-not-verified';

          // await _auth.signOut();

          return res;
        }

        if (userCredential.user != null) {
          DocumentSnapshot snap = await _firestore
              .collection('drivers')
              .doc(userCredential.user!.uid)
              .get();
          model.Driver? user = model.Driver.fromSnap(snap);
          if (user?.isBlocked == true) {
            await _auth.signOut();
            res = 'Your account has been blocked';
          } else {
            res = 'success';
          }
        }
      } else {
        res = 'Please fill all the fields';
      }
    } catch (err) {
      if (err is FirebaseAuthException) {
        if (err.code == 'invalid-credential') {
          res = 'Invalid credentials provided.';
        }
      } else {
        res = err.toString();
      }
    }
    return res;
  }

  Future<String> updateDriverPhoto(Uint8List file) async {
    String res = 'Some error occured';
    User? currentUser = _auth.currentUser;

    // uploadImageToStorage

    String photoUrl =
        await StorageMethods().uploadImageToStorage('driversProfilePics', file);

    if (currentUser != null) {
      try {
        await _firestore
            .collection('drivers')
            .doc(currentUser.uid)
            .update({'photoUrl': photoUrl});

        res = 'success';
      } on Exception catch (e) {
        res = e.toString();
      }
    }

    return res;
  }

  // signout user
  Future<void> signoutUser(BuildContext context) async {
    if (_auth.currentUser != null) {
      const CommonMethods().saveDriverStatus(false);

      Provider.of<NavigationProvider>(context, listen: false).selectedIndex = 0;

      await _auth.signOut();
    }
  }
}
