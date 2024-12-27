import 'dart:typed_data';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spotify_project/Business_Logic/firestore_database_service.dart';
import 'package:spotify_project/Helpers/helpers.dart';
import 'package:spotify_project/business/active_status_updater.dart';
import 'package:spotify_project/screens/register_page.dart';
import 'package:spotify_project/widgets/bottom_bar.dart';
import 'package:spotify_sdk/models/player_state.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:swipe_cards/swipe_cards.dart';
import 'package:spotify_project/screens/chat_screen.dart';
import 'package:spotify_project/widgets/report_bottom_sheet_swipe.dart';
import 'package:lottie/lottie.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({Key? key}) : super(key: key);

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen>
    with ActiveStatusUpdater {
  final FirestoreDatabaseService _firestoreDatabaseService =
      FirestoreDatabaseService();
  String? _errorMessage;
  bool _isLoading = true;
  List<dynamic>? _matchData;
  bool _showCurrentTrack = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
    firestoreDatabaseService.updateActiveStatus();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer(Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showCurrentTrack = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initializeUserData() async {
    try {
      String currentlyListeningMusicName = await _getCurrentlyListeningMusic();
      bool isSpotifyActive = await _checkSpotifyStatus();

      await _firestoreDatabaseService.getUserDatasToMatch(
        songName: currentlyListeningMusicName,
        amIListeningNow: isSpotifyActive,
      );

      _matchData = await _firestoreDatabaseService.getPreviousMatchesList();

      _firestoreDatabaseService.updateActiveStatus();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Error initializing user data: $e";
          _isLoading = false;
        });
      }
    }
  }

  Future<String> _getCurrentlyListeningMusic() async {
    try {
      bool isSpotifyActive = await SpotifySdk.isSpotifyAppActive;
      if (!isSpotifyActive) {
        return '';
      }

      String? musicName =
          await _firestoreDatabaseService.returnCurrentlyListeningMusicName();
      return musicName ?? '';
    } catch (e) {
      print("Error getting currently listening music: $e");
      return '';
    }
  }

  Future<bool> _checkSpotifyStatus() async {
    try {
      return await SpotifySdk.isSpotifyAppActive;
    } catch (e) {
      print("Error checking Spotify active status: $e");
      return false;
    }
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Text(
        _errorMessage ?? "An unknown error occurred",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18, color: Colors.red),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: CircularProgressIndicator(color: Colors.black),
    );
  }

  Widget _buildNoDataWidget(String message) {
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildMatchesWidget() {
    return StreamBuilder<PlayerState>(
      stream: SpotifySdk.subscribePlayerState(),
      builder: (context, snapshot) {
        if (snapshot.hasError || !_showCurrentTrack) {
          // After 12 seconds or if there's an error, display the swipe cards or no data message
          if (_matchData != null && _matchData!.isNotEmpty) {
            return Container(
              color: Color(0xFF2A2A2A),
              child: SwipeCardWidget(snapshotData: _matchData!),
            );
          }

          return _buildNoDataWidget(
              "No matches found. Try listening to some music!");
        }

        if (snapshot.hasData) {
          final track = snapshot.data!.track!;
          return displayPreSwipeCardWidget(track, context);
        }

        return const SizedBox
            .shrink(); // Fallback in case of no data and no error
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1E1E1E),
      bottomNavigationBar: BottomBar(selectedIndex: 1),
      body: _isLoading
          ? _buildLoadingWidget()
          : _errorMessage != null
              ? _buildErrorWidget()
              : _buildMatchesWidget(),
    );
  }
}

class SwipeCardWidget extends StatefulWidget {
  final List<dynamic> snapshotData;

  const SwipeCardWidget({Key? key, required this.snapshotData})
      : super(key: key);

  @override
  _SwipeCardWidgetState createState() => _SwipeCardWidgetState();
}

class _SwipeCardWidgetState extends State<SwipeCardWidget> {
  List<SwipeItem> _swipeItems = <SwipeItem>[];
  MatchEngine? _matchEngine;
  final FirestoreDatabaseService _firestoreDatabaseService =
      FirestoreDatabaseService();

  @override
  void initState() {
    super.initState();
    _swipeItems = widget.snapshotData.map((userData) {
      return SwipeItem(
        content: userData,
        likeAction: () {
          _firestoreDatabaseService.updateIsLiked(true, userData.userId);
          Navigator.of(context).push(CupertinoPageRoute(
            builder: (context) => ChatScreen(
              userData.userId,
              userData.profilePhotos.isNotEmpty
                  ? userData.profilePhotos[0]
                  : "",
              userData.name,
            ),
          ));
        },
        nopeAction: () {
          _firestoreDatabaseService.updateIsLiked(false, userData.userId);
        },
      );
    }).toList();

    _matchEngine = MatchEngine(swipeItems: _swipeItems);
  }

  @override
  Widget build(BuildContext context) {
    return SwipeCards(
      matchEngine: _matchEngine!,
      itemBuilder: (BuildContext context, int index) {
        return UserProfileCard(
          userData: widget.snapshotData[index],
          onLike: () => _matchEngine!.currentItem?.like(),
          onNope: () => _matchEngine!.currentItem?.nope(),
          onReport: () =>
              _showReportBottomSheet(widget.snapshotData[index].userId),
        );
      },
      onStackFinished: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No more matches!")),
        );
      },
      itemChanged: (SwipeItem item, int index) {},
      upSwipeAllowed: false,
      fillSpace: true,
    );
  }

  void _showReportBottomSheet(String userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ReportBottomSheetSwipeCard(
        userId: userId,
        onReportSubmitted: () {
          _matchEngine!.currentItem?.nope();
          _firestoreDatabaseService.updateIsLiked(false, userId);

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                "Thanks for your report, we will review it in less than 24 hours.",
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ));
        },
      ),
    );
  }
}

class UserProfileCard extends StatefulWidget {
  final dynamic userData;
  final VoidCallback onLike;
  final VoidCallback onNope;
  final VoidCallback onReport;

  const UserProfileCard({
    Key? key,
    required this.userData,
    required this.onLike,
    required this.onNope,
    required this.onReport,
  }) : super(key: key);

  @override
  _UserProfileCardState createState() => _UserProfileCardState();
}

class _UserProfileCardState extends State<UserProfileCard> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextImage() {
    if (_currentPage < widget.userData.profilePhotos.length - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousImage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> profilePhotos = widget.userData.profilePhotos;

    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                });
              },
              itemCount: profilePhotos.isEmpty ? 1 : profilePhotos.length,
              itemBuilder: (context, index) {
                return profilePhotos.isEmpty
                    ? Container(
                        color: Colors.black,
                        child: const Icon(Icons.person,
                            size: 100, color: Colors.grey),
                      )
                    : Image.network(
                        profilePhotos[index],
                        fit: BoxFit.cover,
                      );
              },
            ),
          ),

          // Song info overlay positioned on top of the image
          Positioned(
            top: 100.h,
            left: 0,
            right: 0,
            child: FutureBuilder<Map<String, dynamic>?>(
              future: FirestoreDatabaseService()
                  .getCommonSongInfoBasedOnUid(widget.userData.userId),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return Center(
                    child: Container(
                      width: 350.w,
                      height: 350.w,
                      margin: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Card(
                        elevation: 8,
                        shadowColor: Colors.black.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        color: Colors.black.withOpacity(0.7),
                        child: Container(
                          padding: EdgeInsets.all(16.w),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                margin: EdgeInsets.only(bottom: 12.w),
                                width: 250.w,
                                height: 250.w,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    FirestoreDatabaseService()
                                        .getSpotifyImageUrl(
                                            snapshot.data!['image']),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[900],
                                        child: Icon(Icons.music_note,
                                            color: Colors.white54, size: 50.sp),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              Text(
                                '🎵 ${snapshot.data!['titleOfTheSong']}',
                                style: TextStyle(
                                  fontSize: 24.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          // Rest of your existing widgets...
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _previousImage,
                  behavior: HitTestBehavior.translucent,
                  child: Container(color: const Color.fromARGB(0, 0, 0, 0)),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _nextImage,
                  behavior: HitTestBehavior.translucent,
                  child: Container(color: const Color.fromARGB(0, 0, 0, 0)),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                ),
              ),
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 50.w),
                    child: Row(
                      children: [
                        Text(
                          widget.userData.name ?? 'No Name',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          ', ${widget.userData.age ?? ''}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 110.h),
                  SizedBox(height: 8),
                  Text(
                    widget.userData.biography ?? 'No biography available',
                    style: TextStyle(fontSize: 14, color: Colors.white60),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          if (profilePhotos.length > 1)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  profilePhotos.length,
                  (index) => Container(
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index
                          ? Colors.white
                          : Colors.grey.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 35.h,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionButton(Icons.close, Colors.red, widget.onNope),
                SizedBox(width: 100.w),
                _buildActionButton(Icons.favorite, Colors.green, widget.onLike),
              ],
            ),
          ),
          Positioned(
            top: 60.h,
            right: 25.w,
            child: IconButton(
              icon: Icon(Icons.report_problem,
                  color: const Color.fromARGB(255, 255, 255, 255)),
              onPressed: widget.onReport,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130.w,
        height: 130.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color.fromARGB(255, 219, 219, 219),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: color,
          size: 60.sp,
        ),
      ),
    );
  }
}

displayPreSwipeCardWidget(track, context) {
  return Container(
    width: MediaQuery.of(context).size.width,
    height: MediaQuery.of(context).size.height,
    margin: EdgeInsets.symmetric(vertical: 24.h),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white10,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        OverflowBox(
          maxWidth: double.infinity,
          maxHeight: double.infinity,
          child: Lottie.network(
            'https://lottie.host/9f08e4c6-e76a-497e-ab70-923762e1fa42/zWlSuTQeEP.json',
            alignment: Alignment.center,
            fit: BoxFit.cover,
          ),
        ),
        FutureBuilder<Uint8List?>(
          future: SpotifySdk.getImage(
            imageUri: track.imageUri,
            dimension: ImageDimension.large,
          ),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Container(
                width: 330.w,
                height: 330.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: MemoryImage(snapshot.data!),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            }
            return Container(
              width: 330.w,
              height: 330.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white24,
              ),
              child: Center(child: Text('...')),
            );
          },
        ),
        Positioned(
          bottom: 0,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                Text(
                  track.name,
                  style: GoogleFonts.poppins(
                    fontSize: 30.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                SizedBox(height: 4.h),
                Text(
                  track.artist.name.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 30.sp,
                    color: Colors.white70,
                  ),
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 60.h,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                Text(
                  'Finding your match...',
                  style: GoogleFonts.poppins(
                    fontSize: 30.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                SizedBox(height: 4.h),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
