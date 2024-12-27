import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spotify_project/Business_Logic/Models/message_model.dart';
import 'package:spotify_project/Business_Logic/chat_services/chat_database_service.dart';
import 'package:spotify_project/Business_Logic/firestore_database_service.dart';
import 'package:spotify_project/business/active_status_updater.dart';
import 'package:spotify_project/screens/message_box.dart';
import 'package:spotify_project/screens/profile_screen.dart';
import 'package:spotify_project/screens/register_page.dart';
import 'package:intl/intl.dart';
import 'package:spotify_project/screens/test_screens/test_screen_for_search.dart';
import 'package:spotify_project/widgets/chat_screen_settings.dart';
import 'package:spotify_project/widgets/report_bottom_sheet_swipe.dart';
import 'package:spotify_sdk/spotify_sdk.dart';

class ChatScreen extends StatefulWidget {
  final String userIDOfOtherUser;
  final profileURL;
  final String name;

  ChatScreen(this.userIDOfOtherUser, this.profileURL, this.name);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

bool _hasSpotify = false;

class _ChatScreenState extends State<ChatScreen> with ActiveStatusUpdater {
  final ScrollController _scrollController = ScrollController();
  final ChatDatabaseService _chatDBService = ChatDatabaseService();
  final TextEditingController _textController = TextEditingController();
  String? messageText;

  Future<Map<String, dynamic>?> _checkIfHasSpotify() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();

    if (userDoc.exists) {
      final data = userDoc.data();
      setState(() {
        _hasSpotify = data?['hasSpotify'] ?? false;
      });
      return data;
    }
    return null;
  }

  void sendMessage() {
    if (_textController.text.trim().isNotEmpty) {
      Message messageToSaveAndSend = Message(
        fromWhom: currentUser!.uid,
        date: FieldValue.serverTimestamp(),
        isSentByMe: true,
        message: _textController.text,
        toWhom: widget.userIDOfOtherUser,
      );
      _chatDBService.sendMessage(messageToSaveAndSend);
      _textController.clear();
      setState(() {
        messageText = null;
      });

      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0A0A),
              Color(0xFF1D1D1D),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Stack(
                  children: [
                    _buildPatternOverlay(),
                    StreamBuilder<List<Message>>(
                      stream: _chatDBService.getMessagesFromStream(
                          currentUser!.uid, widget.userIDOfOtherUser),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xFF1DB954)));
                        }

                        List<Message> allMessages = snapshot.data!;

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_scrollController.hasClients) {
                            _scrollController.jumpTo(
                              _scrollController.position.maxScrollExtent,
                            );
                          }
                        });

                        return Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                controller: _scrollController,
                                child: Column(
                                  children: [
                                    FutureBuilder<Map<String, dynamic>?>(
                                      future: FirestoreDatabaseService()
                                          .getCommonSongInfoBasedOnUid(
                                              widget.userIDOfOtherUser),
                                      builder: (context, songSnapshot) {
                                        if (songSnapshot.hasData &&
                                            songSnapshot.data != null) {
                                          return Center(
                                              child: Column(
                                            children: [
                                              if (allMessages.isEmpty)
                                                SizedBox(
                                                  height: 190.h,
                                                ),
                                              Container(
                                                width: allMessages.isEmpty
                                                    ? 450.w
                                                    : double.infinity,
                                                height: allMessages.isEmpty
                                                    ? 450.w
                                                    : 100.h,
                                                margin: EdgeInsets.symmetric(
                                                    horizontal: 20.w,
                                                    vertical:
                                                        allMessages.isEmpty
                                                            ? 40.h
                                                            : 16.h),
                                                child: Card(
                                                  elevation: 8,
                                                  shadowColor: Colors.black
                                                      .withOpacity(0.3),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            15),
                                                  ),
                                                  color: Colors.black
                                                      .withOpacity(0.7),
                                                  child: Padding(
                                                    padding:
                                                        EdgeInsets.all(16.w),
                                                    child: allMessages.isEmpty
                                                        ? Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              _buildSongImage(
                                                                  songSnapshot,
                                                                  isEmpty:
                                                                      true),
                                                              SizedBox(
                                                                  height: 16.h),
                                                              Flexible(
                                                                child: _buildSongTitle(
                                                                    songSnapshot,
                                                                    isEmpty:
                                                                        true),
                                                              ),
                                                            ],
                                                          )
                                                        : Row(
                                                            children: [
                                                              _buildSongImage(
                                                                  songSnapshot,
                                                                  isEmpty:
                                                                      false),
                                                              SizedBox(
                                                                  width: 12.w),
                                                              Expanded(
                                                                child: _buildSongTitle(
                                                                    songSnapshot,
                                                                    isEmpty:
                                                                        false),
                                                              ),
                                                            ],
                                                          ),
                                                  ),
                                                ),
                                              ),
                                              // SizedBox(height: 12.h),
                                              if (allMessages.isEmpty)
                                                Text(
                                                  'You listened the same song!',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 30.sp,
                                                    color: Colors.white70,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                            ],
                                          ));
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                    allMessages.isEmpty
                                        ? const SizedBox()
                                        : Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 16.w,
                                                vertical: 16.h),
                                            child: ListView.builder(
                                              shrinkWrap: true,
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              itemCount: allMessages.length,
                                              itemBuilder: (context, index) {
                                                final message =
                                                    allMessages[index];
                                                if (message.message!
                                                    .startsWith('@@@')) {
                                                  return _buildSongMessage(
                                                      message);
                                                } else {
                                                  return _buildRegularMessage(
                                                      message);
                                                }
                                              },
                                            ),
                                          ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              _buildMessageComposer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 36.sp,
            ),
            onPressed: () => Navigator.push(
              context,
              CupertinoPageRoute(builder: (context) => MessageScreen()),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) =>
                    ProfileScreen(uid: widget.userIDOfOtherUser),
              ),
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 45.sp,
                    backgroundImage: NetworkImage(widget.profileURL),
                  ),
                ),
                SizedBox(width: 20.w),
                Text(
                  widget.name,
                  style: GoogleFonts.poppins(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Spacer(),
          IconButton(
            icon: Icon(
              Icons.more_horiz,
              color: Colors.white,
              size: 36.sp,
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => ChatScreenSettings(
                  currentUserId: currentUser!.uid,
                  otherUserId: widget.userIDOfOtherUser,
                ),
                isScrollControlled: true,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height - 70.h,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPatternOverlay() {
    return Opacity(
      opacity: 0.05,
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
                'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAPklEQVQoU2NkYGD4z8DAwMgAAf8ZGBiZGBgY/oP4jFA2IyOEzcgIE2SEiTMyYhVD0QgTR9GIy0CsGvGpBQBuYBBCrGHQrgAAAABJRU5ErkJggg=='),
            repeat: ImageRepeat.repeat,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageComposer() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _checkIfHasSpotify(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _hasSpotify = snapshot.data!['hasSpotify'] ?? false;
        }

        return Column(
          children: [
            if (_hasSpotify)
              Padding(
                padding: EdgeInsets.only(left: 16.w, bottom: 8.h),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (BuildContext context) {
                            return FractionallySizedBox(
                              heightFactor: 0.9,
                              child: TestSearchScreen(
                                userIDOfOtherUser: widget.userIDOfOtherUser,
                              ),
                            );
                          },
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF8E2DE2),
                              Color(0xFF4A00E0),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(25.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: 24.w, vertical: 12.h),
                        child: Text(
                          '🎵 Send a Song',
                          style: GoogleFonts.poppins(
                            fontSize: 18.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 23.sp,
                      ),
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 23.sp,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(35.r),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(35.r),
                          borderSide: BorderSide(
                            color: Colors.purple.withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.2),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 30.w,
                          vertical: 23.h,
                        ),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        setState(() {
                          messageText = value;
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Container(
                    height: 70.h,
                    width: 70.h,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF9C27B0),
                          Color(0xFF00BCD4),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(35.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF9C27B0).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(35.r),
                        onTap: sendMessage,
                        child: Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 29.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _messageBubble(Message message) {
    final isSentByMe = message.isSentByMe!;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: Row(
                mainAxisAlignment: isSentByMe
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                children: [
                  if (!isSentByMe) SizedBox(width: 0.02.sw),
                  Flexible(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 0.9.sw),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 20.w, vertical: 16.h),
                        decoration: BoxDecoration(
                          gradient: isSentByMe
                              ? LinearGradient(
                                  colors: [
                                    const Color(0xFF1DB954)
                                        .withOpacity(0.95), // Spotify green
                                    const Color(0xFF1ED760)
                                        .withOpacity(0.95), // Lighter green
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : const LinearGradient(
                                  colors: [
                                    Color.fromARGB(255, 17, 88, 221),
                                    Color(0xFF4A4A4A),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(isSentByMe ? 28.r : 8.r),
                            topRight: Radius.circular(isSentByMe ? 8.r : 28.r),
                            bottomLeft: Radius.circular(28.r),
                            bottomRight: Radius.circular(28.r),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSentByMe
                                  ? const Color(0xFF1DB954).withOpacity(0.3)
                                  : Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.message!,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 23.sp,
                                fontWeight: isSentByMe
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              _formatTime(message.date),
                              style: TextStyle(
                                color: isSentByMe
                                    ? const Color.fromARGB(255, 255, 255, 255)
                                        .withOpacity(0.9)
                                    : Colors.white.withOpacity(0.7),
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (isSentByMe) SizedBox(width: 0.02.sw),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTime(dynamic date) {
    if (date == null) return '';
    if (date is Timestamp) {
      return DateFormat.Hm().format(date.toDate());
    }
    return '';
  }

  Widget _buildSongImage(AsyncSnapshot<Map<String, dynamic>?> songSnapshot,
      {bool isEmpty = false}) {
    if (!songSnapshot.hasData || songSnapshot.data == null) {
      return SizedBox(
        width: isEmpty ? 200.w : 70.w,
        height: isEmpty ? 200.w : 70.w,
      );
    }

    double size = isEmpty ? 320.w : 70.w;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          FirestoreDatabaseService()
              .getSpotifyImageUrl(songSnapshot.data!['image']),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[900],
              child: Icon(Icons.music_note,
                  color: Colors.white54, size: isEmpty ? 50.sp : 30.sp),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSongTitle(AsyncSnapshot<Map<String, dynamic>?> songSnapshot,
      {bool isEmpty = false}) {
    return Text(
      '${songSnapshot.data!['titleOfTheSong']}',
      style: TextStyle(
        fontSize: isEmpty ? 30.sp : 16.sp,
        color: Colors.white,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      textAlign: isEmpty ? TextAlign.center : TextAlign.start,
      overflow: TextOverflow.ellipsis,
      maxLines: isEmpty ? 3 : 2,
    );
  }

  Widget _buildRegularMessage(Message message) {
    final isSentByMe = message.isSentByMe ?? false;
    return Align(
      alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5.h, horizontal: 10.w),
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
        decoration: BoxDecoration(
          gradient: isSentByMe
              ? LinearGradient(
                  colors: [
                    const Color(0xFF1DB954).withOpacity(0.95), // Spotify green
                    const Color(0xFF1ED760).withOpacity(0.95), // Lighter green
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [
                    Color.fromARGB(255, 17, 88, 221),
                    Color(0xFF4A4A4A),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isSentByMe ? 28.r : 8.r),
            topRight: Radius.circular(isSentByMe ? 8.r : 28.r),
            bottomLeft: Radius.circular(28.r),
            bottomRight: Radius.circular(28.r),
          ),
          boxShadow: [
            BoxShadow(
              color: isSentByMe
                  ? const Color(0xFF1DB954).withOpacity(0.3)
                  : Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          message.message ?? '',
          style: TextStyle(
            color: Colors.white,
            fontSize: 27.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSongMessage(Message message) {
    // Extract song details
    final parts = message.message?.substring(3).split(' -- ') ?? [];
    final trackName = parts.length > 0
        ? parts[0].replaceFirst('Track: ', '')
        : 'Unknown Track';
    final artistName = parts.length > 1
        ? parts[1].replaceFirst('ArtistName: ', '')
        : 'Unknown Artist';
    final imageUrl =
        parts.length > 2 ? parts[2].replaceFirst('Image: ', '') : '';
    final trackUri = parts.length > 3
        ? parts[3].replaceFirst('Uri: ', '')
        : ''; // Extract the URI

    final isSentByMe = message.isSentByMe ?? false;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('tokens')
          .doc('spotify')
          .get(),
      builder: (context, snapshot) {
        bool hasToken = snapshot.hasData && snapshot.data!.exists;

        return GestureDetector(
          onTap: () async {
            if (trackUri.isNotEmpty && hasToken) {
              try {
                bool isConnected = await SpotifySdk.isSpotifyAppActive;
                if (isConnected) {
                  await SpotifySdk.connectToSpotifyRemote(
                    clientId: '32a50962636143748e6779e2f604e07b',
                    redirectUrl: 'com-developer-spotifyproject://callback',
                  );
                  await SpotifySdk.play(spotifyUri: trackUri);
                }
              } catch (error) {
                print('Error playing track: $error');
              }
            }
          },
          child: Align(
            alignment:
                isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 9.h, horizontal: 18.w),
              padding: EdgeInsets.all(27.w),
              decoration: BoxDecoration(
                gradient: isSentByMe
                    ? LinearGradient(
                        colors: [
                          const Color.fromARGB(255, 17, 141, 58)
                              .withOpacity(0.95),
                          const Color.fromARGB(255, 10, 96, 39)
                              .withOpacity(0.95),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : const LinearGradient(
                        colors: [
                          Color.fromARGB(255, 17, 88, 221),
                          Color(0xFF4A4A4A),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isSentByMe ? 50.4.r : 14.4.r),
                  topRight: Radius.circular(isSentByMe ? 14.4.r : 50.4.r),
                  bottomLeft: Radius.circular(50.4.r),
                  bottomRight: Radius.circular(50.4.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSentByMe
                        ? const Color.fromARGB(255, 23, 127, 59)
                            .withOpacity(0.3)
                        : Colors.black.withOpacity(0.2),
                    blurRadius: 14.4,
                    offset: const Offset(0, 7.2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14.4.r),
                      child: Image.network(
                        imageUrl,
                        width: 90.w,
                        height: 90.w,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.music_note,
                              color: Colors.white54, size: 90.sp);
                        },
                      ),
                    ),
                  SizedBox(width: 18.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trackName,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 28.8.sp,
                          ),
                        ),
                        Text(
                          artistName,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 21.6.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasToken)
                    IconButton(
                      icon: Icon(Icons.play_circle_fill,
                          color: Colors.white, size: 40.sp),
                      onPressed: () async {
                        if (trackUri.isNotEmpty) {
                          try {
                            bool isConnected =
                                await SpotifySdk.isSpotifyAppActive;
                            if (isConnected) {
                              await SpotifySdk.connectToSpotifyRemote(
                                clientId: '32a50962636143748e6779e2f604e07b',
                                redirectUrl:
                                    'com-developer-spotifyproject://callback',
                              );
                              await SpotifySdk.play(spotifyUri: trackUri);
                            }
                          } catch (error) {
                            print('Error playing track: $error');
                          }
                        }
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
