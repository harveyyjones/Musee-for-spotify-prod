import 'package:flutter/widgets.dart';
import 'package:spotify_project/Business_Logic/firestore_database_service.dart';

mixin ActiveStatusUpdater<T extends StatefulWidget> on State<T> {
  final FirestoreDatabaseService _firestoreDatabaseService =
      FirestoreDatabaseService();

  @override
  void initState() {
    super.initState();
    _updateActiveStatus();
  }

  @override
  void dispose() {
    _updateActiveStatus();
    super.dispose();
  }

  Future<void> _updateActiveStatus() async {
    _firestoreDatabaseService.updateActiveStatus();
  }
}
