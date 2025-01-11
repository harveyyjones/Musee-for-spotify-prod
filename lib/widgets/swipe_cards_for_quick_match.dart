import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
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
      fillSpace: true,
      likeTag: _buildLikeTag(),
      nopeTag: _buildNopeTag(),
      upSwipeAllowed: false,
      matchEngine: MatchEngine(
        swipeItems: snapshotData.map((userData) {
          return SwipeItem(
            content: UserSwipeCard(
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
            },
          );
        }).toList(),
      ),
      itemBuilder: (context, index) {
        final item = snapshotData[index];
        return UserSwipeCard(userData: item, onSwipe: onSwipe);
      },
      onStackFinished: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No more cards')),
        );
      },
    );
  }

  Widget _buildLikeTag() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.thumb_up,
        size: 80.sp,
        color: Colors.white,
      ),
    );
  }

  Widget _buildNopeTag() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.thumb_down,
        size: 80.sp,
        color: Colors.white,
      ),
    );
  }
}

class UserSwipeCard extends StatefulWidget {
  final UserWithCommonSongs userData;
  final Function(bool) onSwipe;

  const UserSwipeCard({
    required this.userData,
    required this.onSwipe,
    Key? key,
  }) : super(key: key);

  @override
  _UserSwipeCardState createState() => _UserSwipeCardState();
}

class _UserSwipeCardState extends State<UserSwipeCard>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  bool _showAllGenres = false;
  late AnimationController _animationController;
  late Animation<double> _expansionAnimation;
  List<String> _genres = [];
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
          .getTopArtistsFromFirebase(widget.userData.user.userId!,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(30),
      ),
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.userData.user.profilePhotos.length,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return Stack(
            children: [
              GestureDetector(
                onTapUp: (details) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  if (details.globalPosition.dx < screenWidth / 2) {
                    if (_currentPage > 0) {
                      _pageController.jumpToPage(_currentPage - 1);
                    }
                  } else {
                    if (_currentPage <
                        widget.userData.user.profilePhotos.length - 1) {
                      _pageController.jumpToPage(_currentPage + 1);
                    }
                  }
                },
                child: _buildImage(index),
              ),
              Positioned(
                top: 16.h,
                right: 16.w,
                child: _buildReportButton(context),
              ),
              if (_currentPage == 0)
                Positioned(
                  bottom: 150.h,
                  left: 16.w,
                  right: 16.w,
                  child: _buildUserInfo(),
                ),
              Positioned(
                bottom: 70.h,
                left: 16.w,
                right: 16.w,
                child: _buildAdditionalInfo(_currentPage),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildImage(int index) {
    return Transform.scale(
      scale: 1.3,
      child: SizedBox.expand(
        child: Image.network(
          widget.userData.user.profilePhotos[index],
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.error, size: 100, color: Colors.red);
          },
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.userData.user.name ?? 'No Name',
                style: TextStyle(
                    fontSize: 53.sp,
                    color: const Color.fromARGB(255, 255, 255, 255)),
              ),
              const SizedBox(width: 10),
              Text(
                widget.userData.user.age.toString(),
                style: TextStyle(
                    fontSize: 54.sp,
                    color: const Color.fromARGB(255, 255, 255, 255)),
              ),
              SizedBox(width: 10),
              FutureBuilder(
                future: _firestoreDatabaseService
                    .getAccountState(widget.userData.user.userId!),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        border: Border.all(color: Colors.red, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        snapshot.data.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }
                  return SizedBox.shrink();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo(int index) {
    switch (index) {
      case 0:
        return Column(
          children: [
            if (widget.userData.commonSongs.isNotEmpty) _buildCommonSongs(),
          ],
        );
      case 1:
        return (widget.userData.user.topArtists != null &&
                widget.userData.user.topArtists!.isNotEmpty)
            ? _buildTopArtists()
            : SizedBox.shrink();
      case 2:
        return widget.userData.hobbies.isNotEmpty
            ? _buildHobbies()
            : SizedBox.shrink();

      case 3:
        return _genres.isNotEmpty ? _buildGenresWidget() : SizedBox.shrink();

      default:
        return SizedBox.shrink();
    }
  }

  Widget _buildHobbies() {
    return Wrap(
      spacing: 2,
      runSpacing: -7,
      children: widget.userData.hobbies.map((hobby) {
        return Chip(
          label: Text(
            hobby,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
          backgroundColor: Colors.white.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.2),
        );
      }).toList(),
    );
  }

  Widget _buildCommonSongs() {
    return Wrap(
      spacing: 3,
      runSpacing: 3,
      children: widget.userData.commonSongs.map((song) {
        return Chip(
          avatar: CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage(song['albumImageUrl']),
            backgroundColor: Colors.transparent,
          ),
          label: Text(
            song['name'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          backgroundColor: const Color.fromARGB(255, 97, 95, 98).withOpacity(1),
          shape: RoundedRectangleBorder(
            side: BorderSide(
                color: const Color.fromARGB(0, 255, 255, 255).withOpacity(1)),
            borderRadius: BorderRadius.circular(34),
          ),
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.2),
        );
      }).toList(),
    );
  }

  Widget _buildTopArtists() {
    return Wrap(
      spacing: 3,
      runSpacing: -7,
      children: widget.userData.user.topArtists!
          .map((artist) {
            return Chip(
              avatar: CircleAvatar(
                backgroundImage: NetworkImage(artist.imageUrl),
                backgroundColor: Colors.transparent,
              ),
              label: Text(
                artist.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
              backgroundColor: Colors.white.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.2),
            );
          })
          .toList()
          .take(4)
          .toList(),
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

  Widget _buildReportButton(BuildContext context) {
    return IconButton(
      onPressed: () {
        showBottomSheet(
          context: context,
          builder: (context) => ReportBottomSheetSwipeCard(
            userId: widget.userData.user.userId.toString(),
            onReportSubmitted: () {
              FirestoreDatabaseService().updateIsLikedAsQuickMatch(
                  false, widget.userData.user.userId!);
            },
          ),
        );
      },
      icon: const Icon(Icons.report_problem_outlined),
    );
  }
}
