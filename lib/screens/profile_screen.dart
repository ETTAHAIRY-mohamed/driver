// ignore_for_file: use_build_context_synchronously

import 'dart:typed_data';

import 'package:driver/methods/auth_methods.dart';
import 'package:driver/methods/firestore_methods.dart';
import 'package:driver/models/driver.dart';
import 'package:driver/providers/driver_provider.dart';
import 'package:driver/widgets/info_dialog.dart';
import 'package:driver/widgets/loading_dialog.dart';
import 'package:flutter/material.dart';
import 'package:driver/methods/common_methods.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:restart/restart.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? totalTrips;
  String? totalDistance;
  String? totalTime;
  Driver? driver;
  bool isEditing = false;

  TextEditingController? _displayNameController;
  TextEditingController? _emailController;
  TextEditingController? _phoneNumberController;
  TextEditingController? _passwordController;
  TextEditingController? _confirmPasswordController;
  TextEditingController? _vehiculePlateNumberController;
  TextEditingController? _vehiculeModelController;
  TextEditingController? _vehiculeColorController;

  Uint8List? _image;

  CommonMethods commonMethods = const CommonMethods();

  String? _plateNumberDigits;
  String? _plateNumberLetter;
  String? _plateNumberCityCodeCode;

  void splitPlateNumber(String plateNumber) {
    var splittedPlateNumber = [];
    plateNumber = plateNumber.replaceAll(' ', ''); // Remove all spaces
    splittedPlateNumber = plateNumber.split('-');

    for (String part in splittedPlateNumber) {
      if (part.length > 2 && part.length <= 5 && part.contains(RegExp(r'\d'))) {
        _plateNumberDigits = part;
      } else if (part.contains(RegExp(r'[ء-ي]'))) {
        _plateNumberLetter = part;
      } else if (part.length <= 2 && part.contains(RegExp(r'\d'))) {
        _plateNumberCityCodeCode = part;
      }
    }
  }

  signUpFormValidation() {
    if (_displayNameController!.text != driver?.displayName &&
        _displayNameController!.text.trim().length < 3) {
      commonMethods.displaySnackBar(
        'Username must be at least 3 characters long!',
        context,
      );
      return false;
    } else if (_phoneNumberController!.text != driver?.phoneNumber &&
        _phoneNumberController!.text.trim().length < 10) {
      commonMethods.displaySnackBar(
        'Phone number must be at least 10 characters long!',
        context,
      );
      return false;
    } else if (_emailController!.text != driver?.email &&
        (!_emailController!.text.contains('@') ||
            !_emailController!.text.contains('.'))) {
      commonMethods.displaySnackBar(
        'Invalid email address!',
        context,
      );
      return false;
    } else if (_passwordController!.text.isNotEmpty &&
        _passwordController!.text.trim().length < 6) {
      commonMethods.displaySnackBar(
        'Password must be at least 6 characters long!',
        context,
      );
      return false;
    } else if (_passwordController!.text != _confirmPasswordController!.text) {
      commonMethods.displaySnackBar(
        'Passwords do not match!',
        context,
      );
      return false;
    } else if (_vehiculePlateNumberController!.text !=
            driver?.vehiculePlateNumber &&
        _vehiculePlateNumberController!.text.trim().length < 3) {
      commonMethods.displaySnackBar(
        'Vehicle number must be at least 3 characters long!',
        context,
      );
      return false;
    } else if (_vehiculeModelController!.text != driver?.vehiculeModel &&
        _vehiculeModelController!.text.trim().length < 3) {
      commonMethods.displaySnackBar(
        'Vehicle model must be at least 3 characters long!',
        context,
      );
      return false;
    } else if (_vehiculeColorController!.text != driver?.vehiculeColor &&
        _vehiculeColorController!.text.trim().length < 3) {
      commonMethods.displaySnackBar(
        'Vehicle color must be at least 3 characters long!',
        context,
      );
      return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    driver = Provider.of<DriverProvider>(context, listen: false).getUser;
    splitPlateNumber(driver!.vehiculePlateNumber);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    driver = Provider.of<DriverProvider>(context, listen: false).getUser;
    _displayNameController = TextEditingController(text: driver?.displayName);
    _emailController = TextEditingController(text: driver?.email);
    _phoneNumberController = TextEditingController(text: driver?.phoneNumber);
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _vehiculePlateNumberController =
        TextEditingController(text: driver?.vehiculePlateNumber);
    _vehiculeModelController =
        TextEditingController(text: driver?.vehiculeModel);
    _vehiculeColorController =
        TextEditingController(text: driver?.vehiculeColor);
  }

  signout() async {
    showDialog(
        context: context,
        builder: (ctx) => const LoadingDialog(messageText: 'Going offline...'));

    await const CommonMethods().goOfflinePermanently(context);

    await Future.delayed(const Duration(seconds: 3));

    if (context.mounted) Navigator.of(context).pop();

    await AuthMethods().signoutUser(context);

    // await Future.delayed(const Duration(seconds: 3));

    // await restart();
  }

  selectImage() async {
    // Show a loading spinner while the image picker is running
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const LoadingDialog(messageText: 'Loading image...'),
    );

    await commonMethods.askForPhotosPermission();

    // Run the image picker operation
    Uint8List? im = await commonMethods.pickImage(ImageSource.gallery);

    // Dismiss the loading spinner
    Navigator.of(context).pop();

    // Update the state with the selected image
    if (im != null) {
      setState(() {
        _image = im;
      });
      updateProfilePicture(im);
    }
  }

  updateProfilePicture(Uint8List image) async {
    showDialog(
        context: context,
        builder: (context) =>
            const LoadingDialog(messageText: 'Uploading new image...'));
    String res = await AuthMethods().updateDriverPhoto(image);

    if (mounted) Navigator.of(context).pop();

    if (res == 'success') {
      commonMethods.displaySnackBar(
          'Profile picture updated successfully', context);
    } else {
      commonMethods.displaySnackBar(res, context);
    }
  }

  setCounters() async {
    int totalTrips = await FirestoreMethods().getTripsCount();
    double totalDistance =
        await FirestoreMethods().getTotalDistanceCoveredOnTrips();
    int totalTime = await FirestoreMethods().getTotalTimeSpentOnTrips();

    setState(() {
      this.totalTrips = totalTrips.toString();
      this.totalDistance = '${totalDistance.toStringAsFixed(2)} km';
      this.totalTime = '$totalTime minutes';
    });
  }

  @override
  Widget build(BuildContext context) {
    setCounters();
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: signout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 5,
              color: Theme.of(context).cardColor.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isDarkMode
                        ? Colors.black.withOpacity(0.5)
                        : Colors.black.withOpacity(0.2),
                  )),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Flexible(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              children: [
                                _image != null
                                    ? CircleAvatar(
                                        radius: 50,
                                        backgroundImage: MemoryImage(_image!),
                                      )
                                    : CircleAvatar(
                                        radius: 50,
                                        backgroundImage:
                                            NetworkImage(driver!.photoUrl!),
                                      ),
                                Positioned(
                                  bottom: -10,
                                  right: -10,
                                  child: IconButton(
                                    onPressed: selectImage,
                                    icon: const Icon(Icons.camera_alt),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              driver!.displayName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              driver!.email,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        color: Theme.of(context).dividerColor,
                      ),
                      Flexible(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Trips',
                                    style: TextStyle(fontSize: 24),
                                  ),
                                  Text(totalTrips ?? '0'),
                                ],
                              ),
                            ),
                            Flexible(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Distance',
                                    style: TextStyle(fontSize: 24),
                                  ),
                                  Text(totalDistance ?? '0'),
                                ],
                              ),
                            ),
                            Flexible(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Time',
                                    style: TextStyle(fontSize: 24),
                                  ),
                                  Text(totalTime ?? '0'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Card(
              elevation: 5,
              color: Theme.of(context).cardColor.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isDarkMode
                        ? Colors.black.withOpacity(0.5)
                        : Colors.black.withOpacity(0.2),
                  )),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    SizedBox(
                      height: 340,
                      child: ListView.builder(
                        itemCount: 1,
                        itemBuilder: (context, index) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 55,
                                child: isEditing
                                    ? TextField(
                                        controller: _displayNameController,
                                        decoration: const InputDecoration(
                                            labelText: 'Name'),
                                      )
                                    : Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.2),
                                                blurRadius: 5,
                                                spreadRadius: 0.5,
                                                offset: const Offset(0.7, 0.7),
                                              )
                                            ]),
                                        child: ListTile(
                                          leading: const Icon(Icons.person),
                                          title: Text(driver!.displayName,
                                              style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w500)),
                                        ),
                                      ),
                              ),
                              const SizedBox(
                                height: 6,
                              ),
                              SizedBox(
                                height: 55,
                                child: isEditing
                                    ? TextField(
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        controller: _emailController,
                                        decoration: const InputDecoration(
                                            labelText: 'Email'),
                                      )
                                    : Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.2),
                                                blurRadius: 5,
                                                spreadRadius: 0.5,
                                                offset: const Offset(0.7, 0.7),
                                              )
                                            ]),
                                        child: ListTile(
                                          leading: const Icon(Icons.email),
                                          title: Text(driver!.email,
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500)),
                                        ),
                                      ),
                              ),
                              const SizedBox(
                                height: 6,
                              ),
                              SizedBox(
                                height: 55,
                                child: isEditing
                                    ? TextField(
                                        controller: _phoneNumberController,
                                        decoration: const InputDecoration(
                                            labelText: 'Phone Number'),
                                      )
                                    : Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.2),
                                                blurRadius: 5,
                                                spreadRadius: 0.5,
                                                offset: const Offset(0.7, 0.7),
                                              )
                                            ]),
                                        child: ListTile(
                                          leading: const Icon(Icons.phone),
                                          title: Text(driver!.phoneNumber,
                                              style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w500)),
                                        ),
                                      ),
                              ),
                              const SizedBox(
                                height: 6,
                              ),
                              SizedBox(
                                  height: 55,
                                  child: isEditing
                                      ? TextField(
                                          obscureText: true,
                                          controller: _passwordController,
                                          decoration: const InputDecoration(
                                              labelText: 'Password'),
                                        )
                                      : Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.2),
                                                  blurRadius: 5,
                                                  spreadRadius: 0.5,
                                                  offset:
                                                      const Offset(0.7, 0.7),
                                                )
                                              ]),
                                          child: const ListTile(
                                            leading: Icon(Icons.lock),
                                            title: Text('********',
                                                style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight:
                                                        FontWeight.w500)),
                                          ),
                                        )),
                              !isEditing
                                  ? const SizedBox(
                                      height: 0,
                                    )
                                  : SizedBox(
                                      height: 60,
                                      child: TextField(
                                        obscureText: true,
                                        controller: _confirmPasswordController,
                                        decoration: const InputDecoration(
                                            labelText: 'Confirm Password'),
                                      ),
                                    ),
                              const SizedBox(
                                height: 6,
                              ),
                              SizedBox(
                                  height: 60,
                                  child: isEditing
                                      ? TextField(
                                          controller:
                                              _vehiculePlateNumberController,
                                          decoration: const InputDecoration(
                                              labelText:
                                                  'Vehicle Plate Number'),
                                        )
                                      :
                                      // give it the design of a car plate number
                                      Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 6, horizontal: 18),
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.2),
                                                  blurRadius: 5,
                                                  spreadRadius: 0.5,
                                                  offset:
                                                      const Offset(0.7, 0.7),
                                                )
                                              ]),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.abc),
                                              const SizedBox(
                                                width: 4,
                                              ),
                                              Stack(children: [
                                                Positioned(
                                                    child: Image.asset(
                                                        'assets/images/plate_number_holder.png',
                                                        width: 200,
                                                        height: 50,
                                                        fit: BoxFit.fill)),
                                                Positioned(
                                                  left: 20,
                                                  top: 10,
                                                  child: Text(
                                                    _plateNumberDigits ?? '',
                                                    style: const TextStyle(
                                                        fontSize: 20,
                                                        color: Colors.black87,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ),
                                                Positioned(
                                                  top: 10,
                                                  left: 120,
                                                  child: Text(
                                                    _plateNumberLetter ?? '',
                                                    style: const TextStyle(
                                                        fontSize: 20,
                                                        color: Colors.black87,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ),
                                                Positioned(
                                                  top: 10,
                                                  left: 160,
                                                  child: Text(
                                                    _plateNumberCityCodeCode ??
                                                        '',
                                                    style: const TextStyle(
                                                        fontSize: 20,
                                                        color: Colors.black87,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ),
                                              ]),
                                            ],
                                          ),
                                        )),
                              const SizedBox(
                                height: 6,
                              ),
                              SizedBox(
                                  height: 55,
                                  child: isEditing
                                      ? TextField(
                                          controller: _vehiculeModelController,
                                          decoration: const InputDecoration(
                                              labelText: 'Vehicle Model'),
                                        )
                                      : Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.2),
                                                  blurRadius: 5,
                                                  spreadRadius: 0.5,
                                                  offset:
                                                      const Offset(0.7, 0.7),
                                                )
                                              ]),
                                          child: ListTile(
                                            leading: const Icon(
                                                Icons.directions_car),
                                            title: Text(driver!.vehiculeModel,
                                                style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight:
                                                        FontWeight.w500)),
                                          ),
                                        )),
                              const SizedBox(
                                height: 6,
                              ),
                              SizedBox(
                                  height: 55,
                                  child: isEditing
                                      ? TextField(
                                          controller: _vehiculeColorController,
                                          decoration: const InputDecoration(
                                              labelText: 'Vehicle Color'),
                                        )
                                      : Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.2),
                                                  blurRadius: 5,
                                                  spreadRadius: 0.5,
                                                  offset:
                                                      const Offset(0.7, 0.7),
                                                )
                                              ]),
                                          child: ListTile(
                                            leading: const Icon(Icons.brush),
                                            title: Text(driver!.vehiculeColor,
                                                style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight:
                                                        FontWeight.w500)),
                                          ),
                                        )),
                            ],
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Edit and Save buttons
                    if (isEditing)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                isEditing = false;
                              });
                            },
                            child: const Text('Cancel',
                                style: TextStyle(color: Colors.red)),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () async {
                              if (signUpFormValidation()) {
                                showDialog(
                                    context: context,
                                    builder: (ctx) => const LoadingDialog(
                                        messageText: 'Updating profile...'));

                                String result =
                                    await Provider.of<DriverProvider>(context,
                                            listen: false)
                                        .updateProfile({
                                  'displayName': _displayNameController!.text ==
                                          driver?.displayName
                                      ? driver?.displayName
                                      : _displayNameController!.text,
                                  'email':
                                      _emailController!.text == driver?.email
                                          ? driver?.email
                                          : _emailController!.text,
                                  'phoneNumber': _phoneNumberController!.text ==
                                          driver?.phoneNumber
                                      ? driver?.phoneNumber
                                      : _phoneNumberController!.text,
                                  'password': _passwordController!.text.isEmpty
                                      ? null
                                      : _passwordController!.text,
                                  'vehiculePlateNumber':
                                      _vehiculePlateNumberController!.text ==
                                              driver?.vehiculePlateNumber
                                          ? driver?.vehiculePlateNumber
                                          : _vehiculePlateNumberController!
                                              .text,
                                  'vehiculeModel':
                                      _vehiculeModelController!.text ==
                                              driver?.vehiculeModel
                                          ? driver?.vehiculeModel
                                          : _vehiculeModelController!.text,
                                  'vehiculeColor':
                                      _vehiculeColorController!.text ==
                                              driver?.vehiculeColor
                                          ? driver?.vehiculeColor
                                          : _vehiculeColorController!.text,
                                }, context);

                                if (mounted) Navigator.of(context).pop();

                                if (result == 'success') {
                                  commonMethods.displaySnackBar(
                                      'Profile updated successfully', context);
                                  setState(() {
                                    isEditing = false;
                                  });

                                  await Future.delayed(
                                      const Duration(seconds: 3));

                                  restart();
                                } else if (result ==
                                    'email-verification-sent') {
                                  commonMethods.displaySnackBar(
                                      'Email verification link sent. Please verify your email',
                                      context);

                                  await Future.delayed(
                                      const Duration(seconds: 3));

                                  await const CommonMethods()
                                      .goOfflinePermanently(context);

                                  await AuthMethods().signoutUser(context);
                                } else {
                                  commonMethods.displaySnackBar(
                                      result, context);
                                }
                              }
                            },
                            child: const Text('Update Profile'),
                          ),
                        ],
                      ),
                    if (!isEditing)
                      ElevatedButton(
                        onPressed: () {
                          showDialog(
                              context: context,
                              builder: (context) => const InfoDialog(
                                  title: 'Notice',
                                  content:
                                      'To change your email or password, you must update them individually.\n Other profile details can be modified together in a single update.'));
                          setState(() {
                            isEditing = true;
                          });
                        },
                        child: const Text('Edit Infos'),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}