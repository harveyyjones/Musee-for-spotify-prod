import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spotify_project/Business_Logic/firestore_database_service.dart';
import 'package:spotify_project/business/Spotify_Logic/Models/chosen_top_track_model.dart';
import 'package:spotify_project/business/Spotify_Logic/Models/top_10_track_model.dart';
import 'package:spotify_project/business/active_status_updater.dart';
import 'package:spotify_project/constants/app_colors.dart';
import 'package:spotify_project/screens/chat_screen.dart';
import 'package:spotify_project/screens/register_page.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;

  ProfileScreen({Key? key, required this.uid}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with ActiveStatusUpdater {
  ScrollController _scrollController = ScrollController();

  String get text => "Message";
  FirestoreDatabaseService _firestoreDatabaseService =
      FirestoreDatabaseService();

  late Future<Map<String, dynamic>> _combinedFuture;
  int _currentImageIndex = 0;
  late PageController _pageController;
  bool _showingCommonSongs = false;
  late PageController _contentPageController;

  @override
  void initState() {
    super.initState();
    _combinedFuture = _loadAllData();
    _pageController = PageController();
    _contentPageController = PageController();
  }

  Future<Map<String, dynamic>> _loadAllData() async {
    try {
      final userData =
          await _firestoreDatabaseService.getUserDataForDetailPage(widget.uid);
      final topArtists = await _firestoreDatabaseService
          .getTopArtistsFromFirebase(widget.uid, isForProfileScreen: true);
      final topTracks =
          await _firestoreDatabaseService.getChosenTopTracks(widget.uid);

      return {
        'userData': userData,
        'topArtists': topArtists ?? [], // Use an empty list if null
        'topTracks': topTracks ?? [], // Use an empty list if null
      };
    } catch (e) {
      print('Error loading data: $e');
      return {}; // Return an empty map in case of error
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _combinedFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF121212),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF6366F1)),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return _buildErrorScreen('No data available');
        }

        final data = snapshot.data!;
        final userData = data['userData'];
        final topArtists = data['topArtists'] as List<dynamic>?;
        final topTracks = data['topTracks'] as List<dynamic>?;
        final genres =
            _firestoreDatabaseService.prepareGenresForProfiles(topArtists);

        return Scaffold(
          backgroundColor: const Color(0xFF121212),
          extendBodyBehindAppBar: true,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(0),
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              systemOverlayStyle: SystemUiOverlayStyle.light,
            ),
          ),
          body: Stack(
            children: [
              CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: _buildSliverSections(
                    userData, genres, topArtists, topTracks),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildSliverSections(
    dynamic userData,
    List<String> genres,
    List<dynamic>? topArtists,
    List<dynamic>? topTracks,
  ) {
    return [
      SliverToBoxAdapter(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Stack(
            children: [
              _buildGradientOverlay(),
              _buildProfileImages(userData),
              _buildProfileInfo(userData),
              _buildBackButton(),
              _buildImageIndicators(userData.profilePhotos?.length ?? 1),
            ],
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _contentPageController.animateToPage(
                    0,
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: !_showingCommonSongs
                              ? Color(0xFF6366F1)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      'Profile',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => _contentPageController.animateToPage(
                    1,
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _showingCommonSongs
                              ? Color(0xFF6366F1)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      'Common',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: PageView(
            controller: _contentPageController,
            onPageChanged: (index) {
              setState(() {
                _showingCommonSongs = index == 1;
              });
            },
            children: [
              SingleChildScrollView(
                child: Column(
                  children: [
                    if (genres.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 24.h),
                        child: _buildGenresWidget(genres),
                      ),
                    SizedBox(height: 22.h),
                    buildHobbies(genres, userData.userId!),
                    SizedBox(height: 0.h),
                    if (topArtists != null && topArtists.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 24.h),
                        child: _buildTopArtists(topArtists),
                      ),
                    if (topTracks != null && topTracks.isNotEmpty)
                      _buildTopTracks(topTracks as List<ChosenTopTrack>),
                  ],
                ),
              ),
              FutureBuilder<List>(
                future:
                    _firestoreDatabaseService.getCommonSongsForProfileScreen(
                  FirebaseAuth.instance.currentUser!.uid,
                  widget.uid,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final commonSongs = snapshot.data ?? [];
                  if (commonSongs.isEmpty) {
                    return Center(
                      child: Text(
                        'No common songs found',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 28.w),
                    itemCount: commonSongs.length,
                    itemBuilder: (context, index) {
                      final song = commonSongs[index];
                      return Container(
                        margin: EdgeInsets.only(bottom: 16.8.h),
                        padding: EdgeInsets.all(16.8.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16.8.r),
                        ),
                        child: Row(
                          children: [
                            if (song['albumImageUrl'] != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(11.2.r),
                                child: Image.network(
                                  song['albumImageUrl'],
                                  width: 70.w,
                                  height: 70.w,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            SizedBox(width: 16.8.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    song['name'] ?? '',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22.4.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 5.6.h),
                                  Text(
                                    (song['artistNames'] as List<dynamic>)
                                        .join(', '),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 19.6.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _buildGenresWidget(List<String> genres) {
    if (genres.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 28.w),
          child: _buildGradientTitle('Music Interests'),
        ),
        SizedBox(height: 22.4.h),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 28.w),
          child: Row(
            children: genres.map((genre) => _buildGenreChip(genre)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildGradientTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 28.sp,
        fontWeight: FontWeight.bold,
        foreground: Paint()
          ..shader = LinearGradient(
            colors: const [
              Color(0xFF6366F1),
              Color(0xFF9333EA),
            ],
          ).createShader(Rect.fromLTWH(0, 0, 280, 98)),
      ),
    );
  }

  Widget _buildTopArtists(List<dynamic> artists) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 28.w),
          child: _buildGradientTitle('Top Artists'),
        ),
        SizedBox(height: 11.2.h),
        SizedBox(
          height: 161.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 28.w),
            itemCount: min(artists.length, 5),
            itemBuilder: (context, index) => _buildArtistItem(artists[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildTopTracks(List<ChosenTopTrack> tracks) {
    return Stack(
      children: [
        Container(
          margin: EdgeInsets.only(top: 56.h),
          child: ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: min(tracks.length, 5),
            itemBuilder: (context, index) {
              final track = tracks[index];
              return Container(
                margin: EdgeInsets.symmetric(vertical: 5.6.h, horizontal: 28.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16.8.r),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.all(16.8.w),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(11.2.r),
                    child: Image.network(
                      track.albumImage.toString(),
                      width: 70.w,
                      height: 70.w,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.music_note,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  title: Text(
                    track.name ?? '',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 22.4.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    track.artist.toString(),
                    style: TextStyle(
                      color: AppColors.white.withOpacity(0.7),
                      fontSize: 19.6.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          top: 75.4.h,
          left: 28.w,
          right: 28.w,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 11.2.h),
            child: Text(
              'Top Tracks',
              style: GoogleFonts.poppins(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserProfile(dynamic userData) {
    List<String> profilePhotos = userData.profilePhotos ?? [];
    String defaultImage =
        "https://static.vecteezy.com/system/resources/previews/009/734/564/non_2x/default-avatar-profile-icon-of-social-media-user-vector.jpg";

    if (profilePhotos.isEmpty) {
      profilePhotos = [defaultImage];
    }

    void _nextImage() {
      print("Next image tapped");
      if (_currentImageIndex < profilePhotos.length - 1) {
        setState(() {
          _currentImageIndex++;
          _pageController.animateToPage(
            _currentImageIndex,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        });
      }
    }

    void _previousImage() {
      print("Previous image tapped");
      if (_currentImageIndex > 0) {
        setState(() {
          _currentImageIndex--;
          _pageController.animateToPage(
            _currentImageIndex,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        });
      }
    }

    return Stack(
      children: [
        Container(
          height: MediaQuery.of(context).size.height * 0.8,
          child: PageView.builder(
            controller: _pageController,
            itemCount: profilePhotos.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Image.network(
                profilePhotos[index],
                fit: BoxFit.cover,
                loadingBuilder: (BuildContext context, Widget child,
                    ImageChunkEvent? loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: Colors.yellow,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.error, color: Colors.yellow),
              );
            },
          ),
        ),
        Positioned.fill(
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _previousImage,
                  behavior: HitTestBehavior.opaque,
                  child: Container(color: Colors.transparent),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _nextImage,
                  behavior: HitTestBehavior.opaque,
                  child: Container(color: Colors.transparent),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 40,
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
                  color: _currentImageIndex == index
                      ? Color(0xFF1ED760)
                      : Colors.white.withOpacity(0.5),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userData.name ?? currentUser?.displayName ?? 'No Name',
                style: GoogleFonts.poppins(
                  fontSize: 45.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                userData.majorInfo ?? "No major info",
                style: TextStyle(
                  fontSize: 18.sp,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              SizedBox(height: 8),
              Text(
                userData.biography ?? "No biography available.",
                style: TextStyle(
                  fontSize: 28.sp,
                  color: Colors.white.withOpacity(0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ChatScreen(
                                widget.uid,
                                userData.profilePhotos.isNotEmpty
                                    ? userData.profilePhotos[0]
                                    : defaultImage,
                                userData.name,
                              )));
                  print("Message button tapped");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1DB954),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(
                  'Message',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileImages(dynamic userData) {
    List<String> profilePhotos = userData?.profilePhotos ?? [];
    String defaultImage =
        "https://static.vecteezy.com/system/resources/previews/009/734/564/non_2x/default-avatar-profile-icon-of-social-media-user-vector.jpg";

    if (profilePhotos.isEmpty) {
      profilePhotos = [defaultImage];
    }

    return Stack(
      children: [
        // Main Image PageView
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.55,
          child: PageView.builder(
            controller: _pageController,
            itemCount: profilePhotos.length,
            onPageChanged: (index) =>
                setState(() => _currentImageIndex = index),
            itemBuilder: (context, index) => Image.network(
              profilePhotos[index],
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFF1A1A1A),
                child: Icon(Icons.error, color: Color(0xFF6366F1), size: 40.sp),
              ),
            ),
          ),
        ),

        // Gesture Detection Layer
        if (profilePhotos.length > 1)
          Positioned.fill(
            child: Row(
              children: [
                // Left side tap detection
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      print("Left side tapped");
                      if (_currentImageIndex > 0) {
                        setState(() {
                          _currentImageIndex--;
                          _pageController.animateToPage(
                            _currentImageIndex,
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        });
                      }
                    },
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),
                // Right side tap detection
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      print("Right side tapped");
                      if (_currentImageIndex < profilePhotos.length - 1) {
                        setState(() {
                          _currentImageIndex++;
                          _pageController.animateToPage(
                            _currentImageIndex,
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        });
                      }
                    },
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildGenreChip(String genre) {
    return Container(
      margin: EdgeInsets.only(right: 11.2.w),
      padding: EdgeInsets.symmetric(
        horizontal: 22.4.w,
        vertical: 11.2.h,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF6366F1).withOpacity(0.1),
            Color(0xFF9333EA).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(
          color: Color(0xFF6366F1).withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF6366F1).withOpacity(0.1),
            blurRadius: 11.2,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Text(
        genre,
        style: TextStyle(
          color: Colors.white,
          fontSize: 19.6.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildArtistItem(Map<String, dynamic> artist) {
    return Container(
      width: 196.w,
      margin: EdgeInsets.only(right: 22.4.w),
      child: Column(
        children: [
          Container(
            width: 168.w,
            height: 168.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF6366F1).withOpacity(0.2),
                  Color(0xFF9333EA).withOpacity(0.2),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF6366F1).withOpacity(0.2),
                  blurRadius: 22.4,
                  offset: Offset(0, 11.2),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.network(
                artist['imageUrl'] ?? '',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Icon(
                    Icons.person,
                    size: 56.sp,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 16.8.h),
          Text(
            artist['name'] ?? '',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19.6.sp,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTrackItem(Map<String, dynamic> track, int index) {
    print(track[index]);
    return Container(
      margin: EdgeInsets.symmetric(
        vertical: 8.h,
        horizontal: 20.w,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF6366F1).withOpacity(0.1),
            Color(0xFF9333EA).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Color(0xFF6366F1).withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Row(
          children: [
            Container(
              width: 50.w,
              height: 50.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF6366F1).withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: Image.network(
                  track['album']?['images']?[0]?['url'] ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Color(0xFF6366F1).withOpacity(0.2),
                    child: Icon(
                      Icons.music_note,
                      color: Color(0xFF6366F1),
                      size: 24.sp,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track['name'] ?? '',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    (track['artists'] as List<dynamic>?)
                            ?.map((artist) => artist['name'])
                            .join(', ') ??
                        '',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF6366F1).withOpacity(0.1),
              ),
              child: Center(
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: Color(0xFF6366F1),
                  size: 20.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.2),
              Colors.black.withOpacity(0.8),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfo(dynamic userData) {
    return Positioned(
      bottom: 20.h,
      left: 20.w,
      right: 20.w,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                userData?.name ?? 'No Name',
                style: GoogleFonts.poppins(
                  fontSize: 55.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 2),
                      blurRadius: 4,
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 14.w),
              Text(
                userData?.age != null ? ' ${userData.age}' : '',
                style: GoogleFonts.poppins(
                  fontSize: 45.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 2),
                      blurRadius: 4,
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (userData?.songName?.isNotEmpty == true) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF6366F1).withOpacity(0.2),
                    Color(0xFF9333EA).withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: Color(0xFF6366F1).withOpacity(0.5)),
              ),
              child: Text(
                userData.songName,
                style: TextStyle(
                  fontSize: 25.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: 12.h),
          ],
          if (userData?.biography?.isNotEmpty == true) ...[
            Text(
              userData.biography,
              style: TextStyle(
                fontSize: 33.sp,
                color: Colors.white.withOpacity(0.8),
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 20.h),
          ],
          _buildMessageButton(userData),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Positioned(
      top: 40.h,
      left: 20.w,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: 20.sp),
          color: Colors.white,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Widget _buildImageIndicators(int count) {
    return Positioned(
      top: 40.h,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          count,
          (index) => Container(
            margin: EdgeInsets.symmetric(horizontal: 4.w),
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _currentImageIndex == index
                  ? Color(0xFF6366F1)
                  : Colors.white.withOpacity(0.5),
              boxShadow: _currentImageIndex == index
                  ? [
                      BoxShadow(
                        color: Color(0xFF6366F1).withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageButton(dynamic userData) {
    String defaultImage =
        "https://static.vecteezy.com/system/resources/previews/009/734/564/non_2x/default-avatar-profile-icon-of-social-media-user-vector.jpg";

    return Container(
      width: double.infinity,
      height: 50.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF6366F1),
            Color(0xFF9333EA),
          ],
        ),
        borderRadius: BorderRadius.circular(25.r),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25.r),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  widget.uid,
                  userData.profilePhotos?.isNotEmpty == true
                      ? userData.profilePhotos[0]
                      : defaultImage,
                  userData.name,
                ),
              ),
            );
          },
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.message_rounded,
                  color: Colors.white,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Message',
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen(String message) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64.sp,
              color: Color(0xFF6366F1),
            ),
            SizedBox(height: 16.h),
            Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 18.sp,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _combinedFuture = _loadAllData();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6366F1),
                padding: EdgeInsets.symmetric(
                  horizontal: 24.w,
                  vertical: 12.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                ),
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  buildHobbies(List<String> hobbies, String userId) {
    return FutureBuilder<List<String>>(
      future: _firestoreDatabaseService.getUserHobbies(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Error loading hobbies: ${snapshot.error}');
          return const SizedBox.shrink();
        }
        if (!snapshot.hasData || snapshot.data?.isEmpty == true) {
          return const SizedBox.shrink();
        }

        final hobbies = snapshot.data!;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: SizedBox(
            height: 50.h,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: hobbies.map((hobby) {
                return Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: Chip(
                    label: Text(
                      hobby,
                      style: TextStyle(color: AppColors.white),
                    ),
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
