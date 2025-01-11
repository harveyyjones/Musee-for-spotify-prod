import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spotify_project/Business_Logic/Models/user_model.dart';
import 'package:spotify_project/Business_Logic/firestore_database_service.dart';
import 'package:spotify_project/business/Spotify_Logic/Models/top_10_track_model.dart';
import 'package:spotify_project/screens/profile_settings.dart';
import 'package:spotify_project/screens/register_page.dart';
import 'package:spotify_sdk/models/player_state.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:spotify_project/constants/app_colors.dart';
import 'dart:math';
import 'package:spotify_project/business/Spotify_Logic/Models/top_artists_of_the_user_model.dart';
import 'package:spotify_project/business/Spotify_Logic/services/fetch_users_saved_tracks.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class ShareableImagesForMarketing extends StatefulWidget {
  const ShareableImagesForMarketing({Key? key}) : super(key: key);

  @override
  State<ShareableImagesForMarketing> createState() =>
      _ShareableImagesForMarketingState();
}

class _ShareableImagesForMarketingState
    extends State<ShareableImagesForMarketing> {
  final FirestoreDatabaseService _firestoreService = FirestoreDatabaseService();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _screenshotKey = GlobalKey();
  var genres;

  static const String defaultImage =
      "https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_960_720.png";

  final SpotifyServiceForSavedTracks _spotifyServiceForSavedTracks =
      SpotifyServiceForSavedTracks();

  @override
  void initState() {
    super.initState();
    // Fetch saved tracks and other initializations
    _fetchAndLogSavedTracks();

    // Take screenshot and show it in a dialog after a short delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _takeScreenshotAndShowDialog();
          }
        });
      }
    });

    final topArtists = _firestoreService
        .getTopArtistsFromFirebase(currentUser!.uid)
        .then((data) {
      print('genres are being prepeared data: $data');
      genres =
          _firestoreService.prepareGenresForProfiles(data as List<dynamic>?);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate dimensions for Instagram story ratio (9:16)
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final storyHeight = (screenWidth * 16) / 8;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RepaintBoundary(
        key: _screenshotKey,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Container(
            width: screenWidth,
            height: storyHeight,
            child: Stack(
              children: [
                _buildStoryBackground(),
                FutureBuilder<UserModel>(
                  future: _firestoreService.getUserData(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child:
                            CircularProgressIndicator(color: AppColors.primary),
                      );
                    }

                    if (userSnapshot.hasError || userSnapshot.data == null) {
                      return const Center(
                        child: Text(
                          'Error loading profile data',
                          style: TextStyle(color: AppColors.white),
                        ),
                      );
                    }

                    return Container(
                      width: screenWidth,
                      height: storyHeight,
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: ListView(
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          SizedBox(height: 80.h),
                          // Musee Branding
                          _buildMuseeBranding(),
                          SizedBox(height: 20.h),
                          // User's Music Taste Title
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "${userSnapshot.data!.name}'s ",
                                  style: GoogleFonts.poppins(
                                    fontSize: 45.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.white,
                                  ),
                                ),
                                Text(
                                  'Top Artists',
                                  style: GoogleFonts.poppins(
                                    fontSize: 45
                                        .sp, // Match font size for a single sentence look
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 0.h),
                          // Top Artists Section
                          _buildTopArtistsGrid(userSnapshot.data!.userId!),
                          SizedBox(height: 50.h),
                          // Top Tracks Section
                          _buildTopTracksSection(userSnapshot.data!.userId!),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _takeScreenshotAndShowDialog() async {
    if (!mounted) return; // Ensure the widget is still mounted

    try {
      RenderRepaintBoundary boundary = _screenshotKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 4.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      print('Screenshot taken successfully'); // Debug print
      _showScreenshotDialog(pngBytes);
    } catch (e) {
      print('Error taking screenshot: $e');
    }
  }

  void _showScreenshotDialog(Uint8List pngBytes) {
    print('Showing screenshot dialog'); // Debug print
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Container(
          width: double.infinity, // Make the dialog width as large as possible
          height:
              double.infinity, // Make the dialog height as large as possible
          child: AlertDialog(
            title: ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  colors: [
                    Color(0xFF6366F1), // Vibrant color
                    Color(0xFF9333EA), // Vibrant color
                  ],
                ).createShader(bounds);
              },
              child: Text(
                'Screenshot',
                style: GoogleFonts.poppins(
                  fontSize: 24, // Adjust font size as needed
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Set color to white for visibility
                ),
              ),
            ),
            contentPadding: EdgeInsets.zero, // Add this line to fix the error
            content: SingleChildScrollView(
              // Allow scrolling if content is too large
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.memory(pngBytes), // Display the screenshot
                  const SizedBox(height: 20),
                  const Text('What would you like to do?'),
                ],
              ),
            ),
            actions: [
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF6366F1), // Vibrant color
                      Color(0xFF9333EA), // Vibrant color
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton(
                  onPressed: () async {
                    await Share.shareXFiles([
                      XFile.fromData(pngBytes,
                          name: 'screenshot.png', mimeType: 'image/png')
                    ], text: 'Share Your Tops!');
                    Navigator.of(context)
                        .pop(); // Close the dialog after sharing
                  },
                  child: const Text(
                    'Share',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      Navigator.of(context).pop();
    });
  }

  void _fetchAndLogSavedTracks() async {
    final savedTracks = await _spotifyServiceForSavedTracks.getSavedTracks();
    if (savedTracks != null) {
      for (var item in savedTracks.items) {
        print('Song Name: ${item.track.name}');
      }
    } else {
      print('No saved tracks found or error fetching tracks.');
    }
  }

  Widget _buildStoryBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.background,
            Colors.black.withOpacity(0.9),
            AppColors.background,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  Widget _buildMuseeBranding() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.3),
            AppColors.secondary.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        'MUSEE',
        style: GoogleFonts.poppins(
          fontSize: 24.sp,
          fontWeight: FontWeight.bold,
          color: AppColors.white,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildTopArtistsGrid(String userId) {
    return FutureBuilder<SpotifyArtistsResponse>(
      future: _firestoreService
          .getTopArtistsFromFirebase(
            userId,
            isForProfileScreen: false,
          )
          .then((data) => SpotifyArtistsResponse(
                href: '',
                limit: data?.length ?? 0,
                offset: 0,
                total: data?.length ?? 0,
                items: data
                        ?.map((artist) => Artist(
                              externalUrls: ExternalUrls(spotify: ''),
                              followers: Followers(total: 0),
                              genres: (artist['genres'] as List<dynamic>?)
                                      ?.cast<String>() ??
                                  [],
                              href: '',
                              id: artist['id'] as String? ?? '',
                              images: [
                                ImageOfTheArtist(
                                  url: artist['imageUrl'] as String? ??
                                      defaultImage,
                                  height: 300,
                                  width: 300,
                                )
                              ],
                              name: artist['name'] as String? ?? '',
                              popularity: artist['popularity'] as int? ?? 0,
                              type: 'artist',
                              uri: '',
                            ))
                        .toList() ??
                    [],
              )),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.items.isEmpty == true) {
          return const SizedBox.shrink();
        }

        final artists = snapshot.data!.items.take(6).toList();

        return Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 15.h), // Space for the title
                GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 15.w,
                    mainAxisSpacing: 15.h,
                  ),
                  itemCount: artists.length,
                  itemBuilder: (context, index) {
                    final artist = artists[index];
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.1),
                            AppColors.secondary.withOpacity(0.1),
                          ],
                        ),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 118.w, // Increased size by 40%
                            height: 118.w, // Increased size by 40%
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary),
                            ),
                            child: ClipOval(
                              child: Image.network(
                                artist.images.firstOrNull?.url ?? defaultImage,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.person,
                                  color: AppColors.primary,
                                  size: 59.sp, // Increased size by 40%
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            artist.name,
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 30.8.sp, // Increased font size by 40%
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                SizedBox(height: 90.h), // Added space below the grid
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopTracksSection(String userId) {
    return FutureBuilder<List<SpotifyTrackFromSpotify>?>(
      future: _firestoreService.getTopTracksFromFirebase(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.isEmpty == true) {
          return const SizedBox.shrink();
        }

        final tracks = snapshot.data!.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Tracks',
              style: GoogleFonts.poppins(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 15.h),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: tracks.length,
              itemBuilder: (context, index) {
                final track = tracks[index];
                return Container(
                  margin: EdgeInsets.only(bottom: 10.h),
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.1),
                        AppColors.secondary.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: Image.network(
                          track.album.images.firstOrNull?.url ?? defaultImage,
                          width: 50.w,
                          height: 50.w,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.music_note,
                            color: AppColors.primary,
                            size: 30.sp,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              track.name ?? '',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              track.artists
                                  .map((artist) => artist.name)
                                  .join(', '),
                              style: TextStyle(
                                color: AppColors.white.withOpacity(0.7),
                                fontSize: 14.sp,
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
            ),
          ],
        );
      },
    );
  }
}

class WidgetsForOwnProfileScreenForClients {
  static Widget _buildGenresWidget(List<String> genres) {
    if (genres.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: WidgetsForOwnProfileScreenForClients._buildGradientTitle(
              'Music Interests'),
        ),
        SizedBox(height: 16.h),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Row(
            children: genres
                .map((genre) =>
                    WidgetsForOwnProfileScreenForClients._buildGenreChip(genre))
                .toList(),
          ),
        ),
      ],
    );
  }

  static Widget _buildGradientTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 20.sp,
        fontWeight: FontWeight.bold,
        foreground: Paint()
          ..shader = const LinearGradient(
            colors: [
              Color(0xFF6366F1),
              Color(0xFF9333EA),
            ],
          ).createShader(Rect.fromLTWH(0, 0, 200, 70)),
      ),
    );
  }

  static Widget _buildGenreChip(String genre) {
    return Container(
      margin: EdgeInsets.only(right: 8.w),
      padding: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: 8.h,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withOpacity(0.1),
            const Color(0xFF9333EA).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Text(
        genre,
        style: TextStyle(
          color: Colors.white,
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
