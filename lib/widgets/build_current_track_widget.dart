import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:spotify_project/Business_Logic/firestore_database_service.dart';
import 'package:spotify_sdk/models/player_state.dart';
import 'package:spotify_sdk/spotify_sdk.dart';

class BuildCurrentTrackWidget extends StatefulWidget {
  const BuildCurrentTrackWidget({super.key});

  @override
  State<BuildCurrentTrackWidget> createState() =>
      _BuildCurrentTrackWidgetState();
}

class _BuildCurrentTrackWidgetState extends State<BuildCurrentTrackWidget> {
  FirestoreDatabaseService firestoreDatabaseService =
      FirestoreDatabaseService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          // Put any state updates here
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerState>(
      stream: SpotifySdk.subscribePlayerState(),
      builder: (context, snapshot) {
        print('Stream update received: ${snapshot.data?.track?.name}');

        if (!snapshot.hasData) {
          print('No data in snapshot');
          return Container(
            margin: EdgeInsets.symmetric(vertical: 24.h),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: SizedBox.shrink()),
          );
        }

        final track = snapshot.data!.track!;
        print('Track updated: ${track.name}');

        firestoreDatabaseService.updateIsUserListening(
          snapshot.data!.isPaused == false,
          track.name,
        );
        firestoreDatabaseService.updateActiveStatus();

        return Container(
          margin: EdgeInsets.symmetric(vertical: 24.h),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              FutureBuilder<Uint8List?>(
                future: SpotifySdk.getImage(
                  imageUri: track.imageUri,
                  dimension: ImageDimension.large,
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Container(
                      margin: EdgeInsets.only(right: 16.w),
                      width: 80.w,
                      height: 80.w,
                      child: Image.memory(snapshot.data!),
                    );
                  }
                  return Container(
                    margin: EdgeInsets.only(right: 16.w),
                    width: 80.w,
                    height: 80.w,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(child: Text('...')),
                  );
                },
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.name,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      track.artist.name.toString(),
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
