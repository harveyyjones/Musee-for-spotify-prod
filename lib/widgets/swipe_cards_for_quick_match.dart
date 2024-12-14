import 'package:flutter/material.dart';
import 'package:spotify_project/screens/its_a_match_screen.dart';
import 'package:swipe_cards/swipe_cards.dart';
import 'package:spotify_project/Business_Logic/Models/user_model.dart';

import '../Business_Logic/firestore_database_service.dart';

class SwipeCardWidgetForQuickMatch extends StatefulWidget {
  final List<UserModel> snapshotData;
  final Function(bool isLike)? onSwipe;

  const SwipeCardWidgetForQuickMatch({
    Key? key,
    required this.snapshotData,
    this.onSwipe,
  }) : super(key: key);

  @override
  _SwipeCardWidgetForQuickMatchState createState() =>
      _SwipeCardWidgetForQuickMatchState();
}

class _SwipeCardWidgetForQuickMatchState
    extends State<SwipeCardWidgetForQuickMatch> {
  late List<SwipeItem> _swipeItems;
  late MatchEngine _matchEngine;
  final FirestoreDatabaseService _firestoreDatabaseService =
      FirestoreDatabaseService();

  @override
  void initState() {
    super.initState();
    _swipeItems = widget.snapshotData.map((userData) {
      return SwipeItem(
        content: userData,
        likeAction: () async {
          widget.onSwipe?.call(true);
          await _firestoreDatabaseService.updateIsLikedAsQuickMatch(
              true, userData.userId!);
          bool likedMe = await _firestoreDatabaseService
              .getIfSheLikedMeInQuickMatchScreen(userData.userId!);

          if (likedMe) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MatchScreen(matchedUser: userData),
              ),
            );
          }
        },
        nopeAction: () async {
          widget.onSwipe?.call(false);
          await _firestoreDatabaseService.updateIsLikedAsQuickMatch(
              false, userData.userId!);
          bool likedMe = await _firestoreDatabaseService
              .getIfSheLikedMeInQuickMatchScreen(userData.userId!);
          if (likedMe) {
            // Handle the case where the user liked you back
            print('User missed a match! 😲');
            print('${userData.name} liked you back!');
          }
        },
      );
    }).toList();

    _matchEngine = MatchEngine(swipeItems: _swipeItems);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SwipeCards(
            matchEngine: _matchEngine,
            itemBuilder: (BuildContext context, int index) {
              UserModel userData = _swipeItems[index].content as UserModel;
              return UserProfileCard(userData: userData);
            },
            onStackFinished: () {
              // Handle stack finished
            },
            itemChanged: (SwipeItem item, int index) {
              // Handle item changed
            },
            upSwipeAllowed: false,
            fillSpace: true,
            likeTag: const SwipeDirectionIndicator(
              icon: Icons.favorite,
              color: Colors.green,
            ),
            nopeTag: const SwipeDirectionIndicator(
              icon: Icons.close,
              color: Colors.red,
            ),
          ),
        ),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(Icons.close, Colors.red, () {
            widget.onSwipe?.call(false);
            _matchEngine.currentItem?.nope();
          }),
          _buildActionButton(Icons.favorite, Colors.green, () {
            widget.onSwipe?.call(true);
            _matchEngine.currentItem?.like();
          }),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: color,
          size: 30,
        ),
      ),
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
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.error,
                                size: 100, color: Colors.red),
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
                    widget.userData.majorInfo ?? 'No Major Info',
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
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
