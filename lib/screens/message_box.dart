import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:spotify_project/Business_Logic/Models/conversations_in_message_box.dart';
import 'package:spotify_project/Business_Logic/Models/user_model.dart';
import 'package:spotify_project/Business_Logic/chat_services/chat_database_service.dart';
import 'package:spotify_project/Business_Logic/chat_services/firebase_mesaaging_background.dart';
import 'package:spotify_project/Business_Logic/firestore_database_service.dart';
import 'package:spotify_project/Helpers/helpers.dart';
import 'package:spotify_project/business/subscription_service.dart';
import 'package:spotify_project/screens/chat_screen.dart';
import 'package:spotify_project/screens/premium_subscription_screen.dart';
import 'package:spotify_project/widgets/bottom_bar.dart';
import 'package:google_fonts/google_fonts.dart';

class MessageScreen extends StatefulWidget {
  MessageScreen({Key? key}) : super(key: key);

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final NotificationService _notificationService = NotificationService();
  final FirestoreDatabaseService firestoreDatabaseService =
      FirestoreDatabaseService();
  final ChatDatabaseService _chatDatabaseService = ChatDatabaseService();
  final SubscriptionService _subscriptionService = SubscriptionService();

  @override
  void initState() {
    super.initState();
    firestoreDatabaseService.updateActiveStatus();
    _notificationService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _subscriptionService.subscriptionStatusStream(),
      builder: (context, subscriptionSnapshot) {
        isSubscriptionActive = subscriptionSnapshot.data ?? false;

        return Scaffold(
          backgroundColor: const Color(0xFF191414),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF191414),
                  Color(0xFF1E1B1E),
                  Color(0xFF191414),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  _buildLikedUsersSection(),
                  _buildDivider(),
                  _buildConversationsList(),
                ],
              ),
            ),
          ),
          bottomNavigationBar: BottomBar(selectedIndex: 3),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(34.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Messages',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 47.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          // Notification test widget temporarily disabled
          /*Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF6366F1).withOpacity(0.08),
                  Color(0xFF9333EA).withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(19.r),
            ),
            child: IconButton(
              icon: Icon(Icons.notification_add,
                  color: Colors.white, size: 41.sp),
              onPressed: () async {
                await _notificationService.sendTestNotification();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Test notification sent!',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: Color(0xFF1DB954),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                );
              },
            ),
          ),*/
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Colors.white.withOpacity(0.1),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildConversationsList() {
    return Expanded(
      child: FutureBuilder<List<Conversations>>(
        future: _chatDatabaseService.getConversations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF1DB954)));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No conversations yet',
                style: TextStyle(color: Colors.white70, fontSize: 16.sp),
              ),
            );
          }
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) => FutureBuilder<UserModel?>(
              future: _chatDatabaseService
                  .getUserDataForMessageBox(snapshot.data![index].receiverID),
              builder: (context, snapshotForUserInfo) {
                if (!snapshotForUserInfo.hasData) {
                  return const SizedBox.shrink();
                }
                var data = snapshotForUserInfo.data!;
                return _buildConversationTile(data, snapshot.data![index]);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildConversationTile(UserModel user, Conversations conversation) {
    return InkWell(
      onTap: () {
        _chatDatabaseService.changeIsSeenStatus(conversation.receiverID);
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => ChatScreen(
              user.userId.toString(),
              user.profilePhotos.isNotEmpty
                  ? user.profilePhotos[0].toString()
                  : '',
              user.name.toString(),
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 34.w, vertical: 20.h),
        decoration: BoxDecoration(
          gradient: !conversation.isSeen
              ? LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFF6366F1).withOpacity(0.08),
                    Color(0xFF9333EA).withOpacity(0.08),
                  ],
                )
              : null,
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF6366F1).withOpacity(0.08),
                        Color(0xFF9333EA).withOpacity(0.08),
                      ],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 47.r,
                    backgroundColor: Colors.black12,
                    backgroundImage: user.profilePhotos.isNotEmpty
                        ? NetworkImage(user.profilePhotos[0])
                        : null,
                    child: user.profilePhotos.isEmpty
                        ? Icon(Icons.person, color: Colors.white70, size: 54.sp)
                        : null,
                  ),
                ),
                if (!conversation.isSeen)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 20.w,
                      height: 20.w,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF6366F1).withOpacity(0.08),
                            Color(0xFF9333EA).withOpacity(0.08),
                          ],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Color(0xFF191414),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 26.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name ?? 'Unknown',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 26.sp,
                      fontWeight: !conversation.isSeen
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 7.h),
                  Text(
                    conversation.lastMessageSent.startsWith('@@@')
                        ? '🎵 A song...'
                        : conversation.lastMessageSent,
                    style: GoogleFonts.poppins(
                      color: !conversation.isSeen
                          ? Colors.white.withOpacity(0.9)
                          : Colors.white.withOpacity(0.6),
                      fontSize: 24.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: !conversation.isSeen
                  ? Color(0xFF6366F1).withOpacity(0.9)
                  : Colors.white30,
              size: 41.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLikedUsersSection() {
    return Container(
      height: 168.h,
      child: FutureBuilder<List<UserModel>>(
        future: firestoreDatabaseService.getLikedPeople(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF1DB954)));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No liked users yet',
                style: TextStyle(color: Colors.white70, fontSize: 16.sp),
              ),
            );
          }

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 34.w),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              UserModel user = snapshot.data![index];
              return GestureDetector(
                onTap: () => Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (context) => ChatScreen(
                      user.userId!,
                      user.profilePhotos.first,
                      user.name!,
                    ),
                  ),
                ),
                child: Container(
                  margin: EdgeInsets.only(right: 26.w),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF6366F1).withOpacity(0.08),
                              Color(0xFF9333EA).withOpacity(0.08),
                            ],
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 50.r,
                          backgroundColor: Colors.black12,
                          backgroundImage: user.profilePhotos.isNotEmpty
                              ? NetworkImage(user.profilePhotos[0])
                              : null,
                          child: user.profilePhotos.isEmpty
                              ? Icon(Icons.person,
                                  color: Colors.white70, size: 54.sp)
                              : null,
                        ),
                      ),
                      SizedBox(height: 13.h),
                      Text(
                        user.name ?? 'Unknown',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 22.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
