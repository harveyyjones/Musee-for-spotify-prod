import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spotify_project/Business_Logic/Models/user_model.dart';
import 'package:spotify_project/Business_Logic/firestore_database_service.dart';
import 'package:spotify_project/business/Spotify_Logic/Models/chosen_top_track_model.dart';
import 'package:spotify_project/business/Spotify_Logic/Models/top_10_track_model.dart';
import 'package:spotify_project/business/Spotify_Logic/constants.dart';
import 'package:spotify_project/business/Spotify_Logic/services/fetch_recently_played_tracks_service.dart';
import 'package:spotify_project/screens/profile_settings.dart';
import 'package:spotify_project/screens/register_page.dart';
import 'package:spotify_project/screens/shareable%20images%20for%20marketing/share_your_tops_screen.dart';
import 'package:spotify_project/widgets/bottom_bar.dart';
import 'package:spotify_sdk/models/player_state.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:spotify_project/constants/app_colors.dart';
import 'dart:math';
import 'package:spotify_project/business/Spotify_Logic/Models/top_artists_of_the_user_model.dart';
import 'package:spotify_project/business/Spotify_Logic/services/fetch_users_saved_tracks.dart';

class OwnProfileScreenForClients extends StatefulWidget {
  const OwnProfileScreenForClients({Key? key}) : super(key: key);

  @override
  State<OwnProfileScreenForClients> createState() =>
      _OwnProfileScreenForClientsState();
}

class _OwnProfileScreenForClientsState
    extends State<OwnProfileScreenForClients> {
  final FirestoreDatabaseService _firestoreService = FirestoreDatabaseService();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _screenshotKey = GlobalKey();
  var genres;

  static const String defaultImage =
      "https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_960_720.png";

  final SpotifyServiceForSavedTracks _spotifyServiceForSavedTracks =
      SpotifyServiceForSavedTracks();
  final SpotifyServiceForRecentlyPlayedTracks
      _spotifyServiceForRecentlyPlayedTracks =
      SpotifyServiceForRecentlyPlayedTracks();

  @override
  void initState() {
    // _fetchAndLogSavedTracks();
    // _fetchRecentlyPlayedTracks();
    super.initState();
    // !accessToken.isEmpty

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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _buildBackground(),
          // Main content with user data
          FutureBuilder<UserModel>(
            future: _firestoreService.getUserData(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              if (userSnapshot.hasError) {
                return const Center(
                  child: Text(
                    'Error loading profile data. Please try again.',
                    style: TextStyle(color: AppColors.white),
                  ),
                );
              }

              final userData = userSnapshot.data;
              if (userData == null) {
                return const Center(
                  child: Text(
                    'No user data found',
                    style: TextStyle(color: AppColors.white),
                  ),
                );
              }

              return CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Profile Header
                  _buildProfileHeader(userData),

                  // Add a share button

                  // Current Track (Spotify)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: _buildCurrentTrack(),
                    ),
                  ),
                  if (accessToken.isNotEmpty && genres != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 24.h),
                        child: WidgetsForOwnProfileScreenForClients
                            ._buildGenresWidget(genres),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: SizedBox(height: 20.h),
                  ),
                  shareYourInterestButton(context),
                  // Top Artists (Spotify)
                  SliverToBoxAdapter(child: SizedBox(height: 20.h)),
                  SliverToBoxAdapter(
                    child: FutureBuilder<List<String>>(
                      future:
                          _firestoreService.getUserHobbies(userData.userId!),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          print('Error loading hobbies: ${snapshot.error}');
                          return const SizedBox.shrink();
                        }
                        if (!snapshot.hasData ||
                            snapshot.data?.isEmpty == true) {
                          return const SizedBox.shrink();
                        }

                        final hobbies = snapshot.data!;
                        return Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 8.h),
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
                                    backgroundColor:
                                        AppColors.primary.withOpacity(0.2),
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
                    ),
                  ),
                  if (true)
                    SliverToBoxAdapter(
                      child: FutureBuilder<SpotifyArtistsResponse>(
                        future: _firestoreService
                            .getTopArtistsFromFirebase(userData.userId!,
                                isForProfileScreen: false)
                            .then((data) => SpotifyArtistsResponse(
                                  href: '',
                                  limit: data?.length ?? 0,
                                  offset: 0,
                                  total: data?.length ?? 0,
                                  items: data
                                          ?.map((artist) => Artist(
                                                externalUrls:
                                                    ExternalUrls(spotify: ''),
                                                followers: Followers(total: 0),
                                                genres: (artist['genres']
                                                            as List<dynamic>?)
                                                        ?.cast<String>() ??
                                                    [],
                                                href: '',
                                                id: artist['id'] as String? ??
                                                    '',
                                                images: [
                                                  ImageOfTheArtist(
                                                    url: artist['imageUrl']
                                                            as String? ??
                                                        defaultImage,
                                                    height: 300,
                                                    width: 300,
                                                  )
                                                ],
                                                name:
                                                    artist['name'] as String? ??
                                                        '',
                                                popularity: artist['popularity']
                                                        as int? ??
                                                    0,
                                                type: 'artist',
                                                uri: '',
                                              ))
                                          .toList() ??
                                      [],
                                )),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            print('Error loading artists: ${snapshot.error}');
                            return const SizedBox.shrink();
                          }
                          if (!snapshot.hasData ||
                              snapshot.data?.items.isEmpty == true) {
                            return const SizedBox.shrink();
                          }

                          return _buildTopArtists(snapshot.data!);
                        },
                      ),
                    ),

                  // Divider
                  SliverToBoxAdapter(
                    child: Divider(
                      thickness: 1,
                      color: AppColors.white.withOpacity(0.5),
                    ),
                  ),

                  // Top Tracks (Spotify)
                  SliverToBoxAdapter(
                    child: FutureBuilder<List<ChosenTopTrack>?>(
                      future: _firestoreService
                          .getChosenTopTracks(userData.userId!),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          print(
                              'Error loading chosen top tracks: ${snapshot.error}');
                          return const SizedBox.shrink();
                        }
                        if (!snapshot.hasData ||
                            snapshot.data?.isEmpty == true) {
                          return const SizedBox.shrink();
                        }

                        return _buildChosenTopTracks(snapshot.data!);
                      },
                    ),
                  ),
                ],
              );
            },
          ),

          // Bottom Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomBar(selectedIndex: 3),
          ),

          // Add a button for debugging
        ],
      ),
    );
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

  void _fetchRecentlyPlayedTracks() async {
    // TODO: From now on below will fetch from the spotify in a different function specified for the firebase.
    final recentlyPlayedTracks = await _spotifyServiceForRecentlyPlayedTracks
        .getRecentlyPlayedTracksFromSpotify();
    if (recentlyPlayedTracks != null) {
      for (var item in recentlyPlayedTracks.items) {
        print('Recently Played Song: ${item.track?.name ?? 'Unknown'}');
      }
    } else {
      print('No recently played tracks found or error fetching tracks.');
    }
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.background,
            Colors.black,
            AppColors.background,
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserModel userData) {
    return SliverToBoxAdapter(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.55,
        child: Stack(
          children: [
            // Profile Image
            Image.network(
              userData.profilePhotos.firstOrNull ?? defaultImage,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.background,
                child:
                    Icon(Icons.person, color: AppColors.primary, size: 40.sp),
              ),
            ),

            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),

            // User Info
            Positioned(
              bottom: 20.h,
              left: 20.w,
              right: 20.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userData.name ?? 'No Name',
                    style: GoogleFonts.poppins(
                      fontSize: 45.sp,
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (userData.age != null)
                    Text(
                      '${userData.age}',
                      style: GoogleFonts.poppins(
                        fontSize: 45.sp,
                        color: AppColors.white,
                      ),
                    ),
                  Text(
                    userData.biography ?? 'No biography available.',
                    style: TextStyle(
                      fontSize: 25.sp,
                      color: AppColors.white.withOpacity(0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Settings Button
            Positioned(
              top: 40.h,
              right: 20.w,
              child: IconButton(
                icon: Icon(Icons.settings, color: AppColors.white, size: 24.sp),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileSettings()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTrack() {
    return StreamBuilder<PlayerState>(
      stream: SpotifySdk.subscribePlayerState(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.track == null) {
          return const SizedBox.shrink();
        }

        final track = snapshot.data!.track!;
        return Container(
          margin: EdgeInsets.only(bottom: 24.h),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.1),
                AppColors.secondary.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.music_note, color: AppColors.primary),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  '${track.artist.name} - ${track.name}',
                  style: TextStyle(color: AppColors.white, fontSize: 16.sp),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopArtists(SpotifyArtistsResponse artists) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(20.w),
          child: Text(
            'Top Artists',
            style: GoogleFonts.poppins(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        SizedBox(
          height: 160.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            itemCount: min(artists.items.length, 5),
            itemBuilder: (context, index) {
              final artist = artists.items[index];
              return Container(
                width: 120.w,
                margin: EdgeInsets.symmetric(horizontal: 8.w),
                child: Column(
                  children: [
                    Container(
                      width: 100.w,
                      height: 100.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary),
                      ),
                      child: ClipOval(
                        child: Image.network(
                          artist.images.firstOrNull?.url ?? defaultImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.person,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      artist.name,
                      style: GoogleFonts.poppins(
                        color: const Color.fromARGB(255, 194, 194, 194),
                        fontSize: 25.sp,
                      ),
                      maxLines: 2,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChosenTopTracks(List<ChosenTopTrack> tracks) {
    return Padding(
      padding: EdgeInsets.only(bottom: 140.h),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Text(
              'Chosen Top Tracks',
              style: GoogleFonts.poppins(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: min(tracks.length, 5),
            itemBuilder: (context, index) {
              final track = tracks[index];
              return Container(
                margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 20.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.all(12.w),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: Image.network(
                      track.albumImage ?? defaultImage,
                      width: 50.w,
                      height: 50.w,
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
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    track.artist,
                    style: TextStyle(
                      color: AppColors.white.withOpacity(0.7),
                      fontSize: 14.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class WidgetsForOwnProfileScreenForClients {
  static Widget _buildGenresWidget(List<String> genres) {
    if (genres.isEmpty) return SizedBox.shrink();

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
          physics: BouncingScrollPhysics(),
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
          ..shader = LinearGradient(
            colors: const [
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
            Color(0xFF6366F1).withOpacity(0.1),
            Color(0xFF9333EA).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: Color(0xFF6366F1).withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF6366F1).withOpacity(0.1),
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

shareYourInterestButton(context) {
  return SliverToBoxAdapter(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.8),
              AppColors.secondary.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: EdgeInsets.symmetric(vertical: 15.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          onPressed: () {
            // Navigate to ShareableImagesForMarketing
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ShareableImagesForMarketing(),
              ),
            );
          },
          child: Text(
            'Share Your Tops',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
        ),
      ),
    ),
  );
}
