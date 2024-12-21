// ignore_for_file: use_build_context_synchronously

import 'dart:typed_data';
import 'package:driver/methods/auth_methods.dart';
import 'package:driver/methods/common_methods.dart';
import 'package:driver/models/driver.dart';
import 'package:driver/screens/authentication/signin_screen.dart';
import 'package:driver/widgets/info_dialog.dart';
import 'package:driver/widgets/info_dialog_with_image.dart';
import 'package:driver/widgets/loading_dialog.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _userphoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _vehicleNumberController =
      TextEditingController();
  final TextEditingController _vehicleModelController = TextEditingController();
  final TextEditingController _vehicleColorController = TextEditingController();
  Uint8List? _image;

  CommonMethods commonMethods = const CommonMethods();

  bool isPlateNumberTextFieldFirstTap = true;

  Widget? plateNumberTextField;

  final FocusNode _plateNumberFocusNode = FocusNode();

  signUpFormValidation() {
    if (_usernameController.text.trim().length < 3) {
      commonMethods.displaySnackBar(
        'Username must be at least 3 characters long!',
        context,
      );
      return false;
    } else if (_userphoneController.text.trim().length < 10) {
      commonMethods.displaySnackBar(
        'Phone number must be at least 10 characters long!',
        context,
      );
      return false;
    } else if (!_emailController.text.contains('@') ||
        !_emailController.text.contains('.')) {
      commonMethods.displaySnackBar(
        'Invalid email address!',
        context,
      );
      return false;
    } else if (_passwordController.text.trim().length < 6) {
      commonMethods.displaySnackBar(
        'Password must be at least 6 characters long!',
        context,
      );
      return false;
    } else if (_passwordController.text != _confirmPasswordController.text) {
      commonMethods.displaySnackBar(
        'Passwords do not match!',
        context,
      );
      return false;
    } else if (_image == null) {
      commonMethods.displaySnackBar(
        'Please select a profile picture!',
        context,
      );
      return false;
    } else if (_vehicleNumberController.text.trim().length < 3) {
      commonMethods.displaySnackBar(
        'Vehicle number must be at least 3 characters long!',
        context,
      );
      return false;
    } else if (_vehicleModelController.text.trim().length < 3) {
      commonMethods.displaySnackBar(
        'Vehicle model must be at least 3 characters long!',
        context,
      );
      return false;
    } else if (_vehicleColorController.text.trim().length < 3) {
      commonMethods.displaySnackBar(
        'Vehicle color must be at least 3 characters long!',
        context,
      );
      return false;
    }
  }

  registerNewDriver() async {
    showDialog(
        context: context,
        builder: (BuildContext context) =>
            const LoadingDialog(messageText: 'Creating account...'));

    String res = await AuthMethods().signupUser(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      username: _usernameController.text.trim(),
      userphone: _userphoneController.text.trim(),
      file: _image!,
      vehiculeNumber: _vehicleNumberController.text.trim(),
      vehiculeModel: _vehicleModelController.text.trim(),
      vehiculeColor: _vehicleColorController.text.trim(),
      context: context,
    );

    if (mounted) Navigator.of(context).pop();

    if (res != 'success') {
      if (!context.mounted) return;
      commonMethods.displaySnackBar(res, context);
    } else {
      Driver? driver = await AuthMethods().getUserDetails();

      if (driver == null) {
        commonMethods.displaySnackBar(
            'An error occurred. Please try again.', context);
        return;
      }

      await showDialog(
          context: context,
          builder: (context) => InfoDialogWithImage(
                title: 'Welcome ${_usernameController.text}',
                content:
                    'Your account has been created successfully. Please check your email for verification.',
                imageUrl: driver.photoUrl,
              ));

      // Delay for 3 seconds before asking for location and notification permissions

      Future.delayed(const Duration(seconds: 3), () {});

      await commonMethods.askForLocationPermission();
      await commonMethods.askForNotificationPermission();

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const SigninScreen(),
        ),
      );
    }
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
    }
  }

  @override
  void initState() {
    super.initState();

    _plateNumberFocusNode.addListener(() {
      if (!_plateNumberFocusNode.hasFocus) {
        String reversedText =
            _vehicleNumberController.text.split('').reversed.join();
        _vehicleNumberController.text = reversedText;
        _vehicleNumberController.selection = TextSelection.fromPosition(
          TextPosition(offset: _vehicleNumberController.text.length),
        );
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _usernameController.dispose();
    _userphoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _vehicleNumberController.dispose();
    _vehicleModelController.dispose();
    _vehicleColorController.dispose();
    _plateNumberFocusNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    void checkNetwork() async {
      // Check network connection
      await commonMethods.checkConnectivity(context);
    }

    plateNumberTextField = TextField(
      focusNode: _plateNumberFocusNode,
      controller: _vehicleNumberController,
      keyboardType: TextInputType.text,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.left,
      decoration: const InputDecoration(
        labelText: 'Vehicle plate number',
        hintText: '12345 - \u200Eب\u200E - 67',
      ),
    );

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 32,
        ),
        width: double.infinity,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                Stack(
                  children: [
                    _image != null
                        ? CircleAvatar(
                            radius: 86,
                            backgroundImage: MemoryImage(_image!),
                          )
                        : const CircleAvatar(
                            radius: 86,
                            backgroundImage:
                                AssetImage('assets/images/avatar_man.png'),
                          ),
                    Positioned(
                      bottom: -10,
                      left: 110,
                      child: IconButton(
                          onPressed: selectImage,
                          icon: const Icon(Icons.add_a_photo)),
                    )
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Create a Driver\'s Account',
                ),
                // text fields
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    children: [
                      TextField(
                        controller: _usernameController,
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          hintText: 'Enter your username',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _userphoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone number',
                          hintText: 'Enter your phone number',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'Enter your email',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _passwordController,
                        keyboardType: TextInputType.text,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter your password',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _confirmPasswordController,
                        keyboardType: TextInputType.text,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirm password',
                          hintText: 'Confirm your password',
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () async {
                          if (isPlateNumberTextFieldFirstTap) {
                            _plateNumberFocusNode.unfocus();
                            await showDialog(
                              context: context,
                              builder: (context) => const InfoDialog(
                                title: 'Notice',
                                content:
                                    'Please enter your vehicle plate number in the following format: 12345 - \u200Eب\u200E - 67',
                              ),
                            ).then((_) {
                              // Request focus for the TextField after the dialog is dismissed
                              _plateNumberFocusNode.requestFocus();
                            });
                            setState(() {
                              isPlateNumberTextFieldFirstTap = false;
                            });
                          }
                        },
                        child: isPlateNumberTextFieldFirstTap
                            ? const TextField(
                                enabled: false,
                                decoration: InputDecoration(
                                  labelText: 'Vehicle plate number',
                                  hintText: '12345 - \u200Eب\u200E - 67',
                                ),
                              )
                            : plateNumberTextField,
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _vehicleModelController,
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
                          labelText: 'Vehicle model',
                          hintText: 'Enter your vehicle model',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _vehicleColorController,
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
                          labelText: 'Vehicle color',
                          hintText: 'Enter your vehicle color',
                        ),
                      ),
                      const SizedBox(height: 22),
                      ElevatedButton(
                        onPressed: () {
                          checkNetwork();
                          if (signUpFormValidation() == false) {
                            return;
                          }

                          registerNewDriver();
                        },
                        child: const Text(
                          'Sign Up',
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Already have an account?',
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => const SigninScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Sign In',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
