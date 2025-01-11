import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:spotify_project/screens/register_page.dart';

class ReportBottomSheetSwipeCard extends StatefulWidget {
  const ReportBottomSheetSwipeCard({
    super.key,
    required this.userId,
    required this.onReportSubmitted,
  });

  final String userId;
  final VoidCallback onReportSubmitted;

  @override
  State<ReportBottomSheetSwipeCard> createState() =>
      _ReportBottomSheetSwipeCardState();
}

class _ReportBottomSheetSwipeCardState
    extends State<ReportBottomSheetSwipeCard> {
  final List<String> _reportReasons = [
    'Inappropriate Content',
    'Spam',
    'Fake Profile',
    'Content Promoter',
    'Scam',
    'Other'
  ];
  String? _selectedReason;
  final TextEditingController _commentsController = TextEditingController();

  Future<void> _submitReport() async {
    final userId = widget.userId;
    final reporterId = FirebaseAuth.instance.currentUser!.uid;

    final reportRef =
        FirebaseFirestore.instance.collection('reported').doc(userId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(reportRef);

      if (!snapshot.exists) {
        transaction.set(reportRef, {
          'count': 1,
          'reporter': reporterId,
          'reason': _selectedReason,
          'comments': _commentsController.text,
        });
      } else {
        transaction.update(reportRef, {
          'count': (snapshot.data()?['count'] ?? 0) + 1,
          'reporter': reporterId,
          'reason': _selectedReason,
          'comments': _commentsController.text,
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text(
              'Thanks, we will review your report in less than 24 hours.')),
    );

    widget.onReportSubmitted();

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16.0,
      ),
      body: Padding(
        padding: EdgeInsets.only(
          top: 16.0.h,
          left: 16.0.w,
          right: 16.0.w,
        ),
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Why are you reporting this user?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ..._reportReasons.map((reason) => RadioListTile<String>(
                      title: Text(reason),
                      value: reason,
                      groupValue: _selectedReason,
                      onChanged: (value) {
                        setState(() {
                          _selectedReason = value;
                        });
                      },
                    )),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _selectedReason == null ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.white,
                    disabledForegroundColor: Colors.black.withOpacity(0.38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Submit Report',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
