import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spotify_project/Business_Logic/firestore_database_service.dart';
import 'package:spotify_project/Helpers/helpers.dart';
import 'package:spotify_project/screens/chat_screen.dart';
import 'package:swipe_cards/draggable_card.dart';
import 'package:swipe_cards/swipe_cards.dart';

class SwipeCardWidget extends StatefulWidget {
  SwipeCardWidget({
    Key? key,
    this.title = "You have similar music taste with these people.",
    this.userCard,
    this.snapshotData,
  }) : super(key: key);
  Widget? userCard;
  final String? title;
  var snapshotData;

  @override
  _SwipeCardWidgetState createState() => _SwipeCardWidgetState();
}

class _SwipeCardWidgetState extends State<SwipeCardWidget> {
  final List<SwipeItem> _swipeItems = <SwipeItem>[];
  MatchEngine? _matchEngine;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  final FirestoreDatabaseService _firestoreDatabaseService =
      FirestoreDatabaseService();

  @override
  void initState() {
    super.initState();
    widget.snapshotData.shuffle();
    for (var i = 0; i < widget.snapshotData.length; i++) {
      _swipeItems.add(SwipeItem(
        content: widget.snapshotData[i],
        likeAction: () => _handleLike(widget.snapshotData[i]),
        nopeAction: () => _handleNope(widget.snapshotData[i]),
        superlikeAction: () => _handleSuperLike(),
        onSlideUpdate: (SlideRegion? region) async {
          print("Region $region");
        },
      ));
    }
    _matchEngine = MatchEngine(swipeItems: _swipeItems);
  }

  void _handleLike(dynamic userData) {
    _firestoreDatabaseService.updateIsLiked(true, userData.userId);
    Navigator.of(context).push(CupertinoPageRoute(
      builder: (context) => ChatScreen(
        userData.userId,
        userData.profilePhotos.isNotEmpty ? userData.profilePhotos[0] : "",
        userData.name,
      ),
    ));
    _showSnackBar("Liked", Colors.green);
  }

  void _handleNope(dynamic userData) {
    _firestoreDatabaseService.updateIsLiked(false, userData.userId);
    _showSnackBar("Nope", Colors.red);
  }

  void _handleSuperLike() {
    _showSnackBar("Super Liked", Colors.blue);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
      duration: Duration(milliseconds: 500),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          widget.title.toString(),
          style: GoogleFonts.poppins(
            fontSize: 20.sp,
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        width: screenWidth,
        height: screenHeight,
        color: Colors.white,
        child: Column(
          children: [
            Expanded(
              child: SwipeCards(
                matchEngine: _matchEngine!,
                itemBuilder: (BuildContext context, int index) {
                  return _buildCard(widget.snapshotData[index]);
                },
                onStackFinished: () {
                  _showSnackBar("No more matches", Colors.grey);
                },
                itemChanged: (SwipeItem item, int index) {},
                upSwipeAllowed: false,
                fillSpace: true,
              ),
            ),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(dynamic userData) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            userData.profilePhotos.isNotEmpty
                ? Image.network(
                    userData.profilePhotos[0],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildPlaceholderIcon(),
                  )
                : _buildPlaceholderIcon(),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
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
                    userData.name ?? "No Name",
                    style: GoogleFonts.poppins(
                      fontSize: 28.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    userData.biography ?? "No biography available",
                    style: GoogleFonts.poppins(
                      fontSize: 16.sp,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      color: Colors.grey[300],
      child: Icon(
        Icons.person,
        size: 100.sp,
        color: Colors.grey[600],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 30.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(Icons.close, Colors.red, () {
            _matchEngine!.currentItem?.nope();
          }),
          _buildActionButton(Icons.star, Colors.blue, () {
            _matchEngine!.currentItem?.superLike();
          }),
          _buildActionButton(Icons.favorite, Colors.green, () {
            _matchEngine!.currentItem?.like();
          }),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60.w,
        height: 60.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
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
          size: 30.sp,
        ),
      ),
    );
  }
}
