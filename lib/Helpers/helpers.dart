import 'dart:ui';

import 'package:spotify_project/Business_Logic/firestore_database_service.dart';

var pixelRatio = window.devicePixelRatio;
var logicalScreenSize = window.physicalSize / pixelRatio;
var screenWidth = logicalScreenSize.width;
var screenHeight = logicalScreenSize.height;
FirestoreDatabaseService firestoreDatabaseService = FirestoreDatabaseService();
