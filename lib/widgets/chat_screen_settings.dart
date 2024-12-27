import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:spotify_project/widgets/report_bottom_sheet_swipe.dart';

class ChatScreenSettings extends StatelessWidget {
  final String currentUserId;
  final String otherUserId;

  ChatScreenSettings({required this.currentUserId, required this.otherUserId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SizedBox(
          height: 50,
        ),
      ),
      body: Container(
        child: Column(
          children: [
            ListTile(
              title: Text('Block User'),
              onTap: () {
                _blockUser(context);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Report User'),
              onTap: () {
                _reportUser(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _blockUser(BuildContext context) async {
    try {
      // Add to blockedUsers collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('blockedUsers')
          .doc(otherUserId)
          .set({
        'blockedAt': FieldValue.serverTimestamp(),
        'uid': otherUserId,
      });

      // Add to blockedBy collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(otherUserId)
          .collection('blockedBy')
          .doc(currentUserId)
          .set({
        'blockedAt': FieldValue.serverTimestamp(),
        'uid': currentUserId,
      });

      // Delete messages from conversations
      await _deleteMessages();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User blocked successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to block user: $e')),
      );
    }
  }

  Future<void> _deleteMessages() async {
    // Define the document IDs for the conversation
    final myDocumentId = '$currentUserId--$otherUserId';
    final receiverDocumentId = '$otherUserId--$currentUserId';

    // List of conversation paths
    final conversationPaths = [
      'conversations/$myDocumentId/messages',
      'conversations/$receiverDocumentId/messages',
    ];

    for (var path in conversationPaths) {
      final messages = await FirebaseFirestore.instance.collection(path).get();

      for (var doc in messages.docs) {
        await doc.reference.delete();
      }
    }

    // Optionally, delete the conversation documents themselves
    await FirebaseFirestore.instance
        .collection('conversations')
        .doc(myDocumentId)
        .delete();
    await FirebaseFirestore.instance
        .collection('conversations')
        .doc(receiverDocumentId)
        .delete();
  }

  void _reportUser(BuildContext context) {
    // Implement report user functionality
    showModalBottomSheet(
      context: context,
      builder: (context) => ReportBottomSheetSwipeCard(
        userId: otherUserId,
        onReportSubmitted: () {
          Navigator.pop(context);
        },
      ),
    );
  }
}
