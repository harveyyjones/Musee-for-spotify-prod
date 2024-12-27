import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:spotify_project/screens/its_a_match_screen.dart';
import 'package:spotify_project/widgets/report_bottom_sheet_swipe.dart';
import 'package:swipe_cards/swipe_cards.dart';
import 'package:spotify_project/Business_Logic/Models/user_model.dart';

import '../Business_Logic/firestore_database_service.dart';

class SwipeCardWidgetForQuickMatch extends StatelessWidget {
  final List<UserWithCommonSongs> snapshotData;
  final Function(bool) onSwipe;

  const SwipeCardWidgetForQuickMatch({
    required this.snapshotData,
    required this.onSwipe,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SwipeCards(
      upSwipeAllowed: false,
      matchEngine: MatchEngine(
        swipeItems: snapshotData.map((userData) {
          return SwipeItem(
              content: SwipeableCard(
                userData: userData,
                onSwipe: onSwipe,
              ),
              likeAction: () {
                FirestoreDatabaseService()
                    .updateIsLikedAsQuickMatch(true, userData.user.userId!);
                onSwipe(true);
              },
              nopeAction: () {
                FirestoreDatabaseService()
                    .updateIsLikedAsQuickMatch(false, userData.user.userId!);
                onSwipe(false);
              });
        }).toList(),
      ),
      itemBuilder: (context, index) {
        final item = snapshotData[index];
        return UserProfileCard(userData: item.user);
      },
      onStackFinished: () {
        // Handle when all cards are swiped
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No more cards')),
        );
      },
    );
  }
}

class SwipeableCard extends StatefulWidget {
  final UserWithCommonSongs userData;
  final Function(bool) onSwipe;

  const SwipeableCard({
    required this.userData,
    required this.onSwipe,
    Key? key,
  }) : super(key: key);

  @override
  _SwipeableCardState createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<SwipeableCard>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  bool _showAllGenres = false;
  late AnimationController _animationController;
  late Animation<double> _expansionAnimation;
  List<String> _genres = ['Rock', 'Pop', 'Jazz', 'Classical', 'Hip Hop'];
  bool _isLoadingGenres = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expansionAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _fetchGenres();
  }

  Future<void> _fetchGenres() async {
    // Simulate fetching genres
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _isLoadingGenres = false;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _nextImage() {
    if (_currentPage < widget.userData.user.profilePhotos.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousImage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: PageView.builder(
              physics: const NeverScrollableScrollPhysics(),
              controller: _pageController,
              itemCount: widget.userData.user.profilePhotos.isEmpty
                  ? 1
                  : widget.userData.user.profilePhotos.length,
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                });
              },
              itemBuilder: (context, index) {
                return widget.userData.user.profilePhotos.isEmpty
                    ? const Icon(Icons.person, size: 100, color: Colors.grey)
                    : Image.network(
                        widget.userData.user.profilePhotos[index],
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white));
                        },
                        errorBuilder: (context, error, stackTrace) {
                          print('Error loading image in swipe cards: $error');
                          return const Icon(Icons.error,
                              size: 100, color: Colors.red);
                        },
                      );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _previousImage,
                  behavior: HitTestBehavior.translucent,
                  child: Container(),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _nextImage,
                  behavior: HitTestBehavior.translucent,
                  child: Container(),
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
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(16)),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.userData.user.name ?? 'No Name',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  // TODO: Below fonts are not working. Fix.
                  Text(
                    widget.userData.user.songName ?? '',
                    style: const TextStyle(fontSize: 20, color: Colors.white70),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    widget.userData.user.biography ?? 'No biography available',
                    style: TextStyle(fontSize: 20.sp, color: Colors.white60),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.userData.commonSongsCount > 0) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: Color(0xFF1DB954),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Icon(
                            Icons.music_note,
                            color: Colors.white,
                            size: 12.sp,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          '${widget.userData.commonSongsCount} songs in common',
                          style: TextStyle(
                            color: Color(0xFF1DB954),
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    ...widget.userData.commonSongs.map((song) => Container(
                          margin: EdgeInsets.only(bottom: 8.h),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4.r),
                                child: Image.network(
                                  song['albumImageUrl'] ?? '',
                                  width: 32.w,
                                  height: 32.w,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    width: 32.w,
                                    height: 32.w,
                                    color: Colors.grey[800],
                                    child: Icon(Icons.music_note,
                                        size: 16.sp, color: Colors.white),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      song['name'] ?? '',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      (song['artistNames'] as List<dynamic>)
                                          .join(', '),
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10.sp,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                  const SizedBox(height: 12),
                  _buildGenresWidget(),
                ],
              ),
            ),
          ),
          if (widget.userData.user.profilePhotos.length > 1)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.userData.user.profilePhotos.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
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
        ],
      ),
    );
  }

  Widget _buildGenresWidget() {
    if (_isLoadingGenres) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }
    if (_genres.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayedGenres = _showAllGenres ? _genres : _genres.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Music Interests',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: displayedGenres.map((genre) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.5)),
              ),
              child: Text(
                genre,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            );
          }).toList(),
        ),
        if (_genres.length > 4)
          GestureDetector(
            onTap: () {
              setState(() {
                _showAllGenres = !_showAllGenres;
                if (_showAllGenres) {
                  _animationController.forward();
                } else {
                  _animationController.reverse();
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _showAllGenres ? 'Show Less' : 'Show More',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  AnimatedRotation(
                    turns: _showAllGenres ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class SwipeDirectionIndicator extends StatelessWidget {
  final IconData icon;
  final Color color;

  const SwipeDirectionIndicator({
    Key? key,
    required this.icon,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.8),
      ),
      padding: const EdgeInsets.all(16),
      child: Icon(
        icon,
        color: Colors.white,
        size: 40,
      ),
    );
  }
}

class UserProfileCard extends StatefulWidget {
  final UserModel userData;

  const UserProfileCard({Key? key, required this.userData}) : super(key: key);

  @override
  _UserProfileCardState createState() => _UserProfileCardState();
}

class _UserProfileCardState extends State<UserProfileCard>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  bool _showAllGenres = false;
  late AnimationController _animationController;
  late Animation<double> _expansionAnimation;
  List<String> _genres = ['Rock', 'Pop', 'Jazz', 'Classical', 'Hip Hop'];
  bool _isLoadingGenres = true;

  final FirestoreDatabaseService _firestoreDatabaseService =
      FirestoreDatabaseService();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expansionAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _fetchGenres();
  }

  Future<void> _fetchGenres() async {
    try {
      final topArtists = await _firestoreDatabaseService
          .getTopArtistsFromFirebase(widget.userData.userId!,
              isForProfileScreen: true);
      if (topArtists != null && topArtists.isNotEmpty) {
        if (mounted) {
          setState(() {
            _genres = _firestoreDatabaseService.prepareGenres(topArtists);
            _isLoadingGenres = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _genres = [];
            _isLoadingGenres = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching genres: $e');
      if (mounted) {
        setState(() {
          _genres = [];
          _isLoadingGenres = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _nextImage() {
    if (_currentPage < widget.userData.profilePhotos.length - 1) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.fastLinearToSlowEaseIn);
    }
  }

  void _previousImage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> profilePhotos = widget.userData.profilePhotos;

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: PageView.builder(
              physics: const NeverScrollableScrollPhysics(),
              controller: _pageController,
              itemCount: profilePhotos.isEmpty ? 1 : profilePhotos.length,
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                });
              },
              itemBuilder: (context, index) {
                return profilePhotos.isEmpty
                    ? const Icon(Icons.person, size: 100, color: Colors.grey)
                    : Image.network(
                        profilePhotos[index],
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white));
                        },
                        errorBuilder: (context, error, stackTrace) {
                          print('Error loading image: $error');
                          return const Icon(Icons.error,
                              size: 100, color: Colors.red);
                        },
                      );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _previousImage,
                  behavior: HitTestBehavior.translucent,
                  child: Container(),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _nextImage,
                  behavior: HitTestBehavior.translucent,
                  child: Container(),
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
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(16)),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.userData.name ?? 'No Name',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.userData.songName ?? 'No Major Info',
                    style: const TextStyle(fontSize: 20, color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.userData.biography ?? 'No biography available',
                    style: const TextStyle(fontSize: 14, color: Colors.white60),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  _buildGenresWidget(),
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
                    margin: const EdgeInsets.symmetric(horizontal: 4),
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
          // **************** Report Button ****************
          Positioned(
            top: 16.h,
            right: 16.w,
            child: IconButton(
                onPressed: () {
                  showBottomSheet(
                      context: context,
                      builder: (context) => ReportBottomSheetSwipeCard(
                          userId: widget.userData.userId.toString(),
                          onReportSubmitted: () {
                            FirestoreDatabaseService()
                                .updateIsLikedAsQuickMatch(
                                    false, widget.userData.userId!);
                          }));
                },
                icon: Icon(Icons.report_problem_outlined)),
          )
        ],
      ),
    );
  }

  Widget _buildGenresWidget() {
    if (_isLoadingGenres) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }
    if (_genres.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayedGenres = _showAllGenres ? _genres : _genres.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Music Interests',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: displayedGenres.map((genre) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.5)),
              ),
              child: Text(
                genre,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            );
          }).toList(),
        ),
        if (_genres.length > 4)
          GestureDetector(
            onTap: () {
              setState(() {
                _showAllGenres = !_showAllGenres;
                if (_showAllGenres) {
                  _animationController.forward();
                } else {
                  _animationController.reverse();
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _showAllGenres ? 'Show Less' : 'Show More',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  AnimatedRotation(
                    turns: _showAllGenres ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
