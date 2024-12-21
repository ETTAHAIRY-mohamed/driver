import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:audioplayers/audioplayers.dart';

// for dev purpose we're getting the location of google plex
const CameraPosition googlePlexInitialPosition = CameraPosition(
  target: LatLng(37.42796133580664, -122.085749655962),
  zoom: 14.4746,
);
const CameraPosition casablancaInitialPosition = CameraPosition(
  target: LatLng(33.5731, -7.5898),
  zoom: 14.4746,
);

Position? currentPositionOfDriver;

StreamSubscription<Position>? homeTabPageStreamSubscription;

StreamSubscription<Position>? newTripStreamSubscription;

bool isGeofireInitialized = false;

int timerDuration = 20;

final audioPlayer = AudioPlayer();

bool isDriverAvailable = false;

bool isDriverAvailableServerSide = false;
