import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:spotify_project/business/payment_service/payment_screen.dart';

class SubscribePremiumScreen extends StatelessWidget {
  const SubscribePremiumScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 20.h),
                _buildHeader(),
                SizedBox(height: 30.h),
                _buildPriceTag(),
                SizedBox(height: 30.h),
                _buildFeatures(),
                SizedBox(height: 30.h),
                _buildComparisonTable(),
                SizedBox(height: 30.h),
                _buildSubscribeButton(context),
                SizedBox(height: 20.h),
                _buildSupportEmail(),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'Upgrade to Premium',
          style: GoogleFonts.poppins(
            fontSize: 32.sp,
            fontWeight: FontWeight.bold,
            foreground: Paint()
              ..shader = const LinearGradient(
                colors: [
                  Color(0xFF1DB954),
                  Color(0xFF1ED760),
                ],
              ).createShader(Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Unlock all features and enhance your experience',
          style: GoogleFonts.poppins(
            fontSize: 16.sp,
            color: Colors.grey[400],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPriceTag() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1DB954), Color(0xFF1ED760)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '25 PLN',
            style: GoogleFonts.poppins(
              fontSize: 36.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            ' / month',
            style: GoogleFonts.poppins(
              fontSize: 18.sp,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatures() {
    return Column(
      children: [
        _featureCard(
          icon: Icons.visibility,
          title: 'Enhanced Visibility',
          description: 'Get more visibility throughout the month',
        ),
        SizedBox(height: 16.h),
        _featureCard(
          icon: Icons.favorite,
          title: 'See Who Likes You',
          description: 'Access your likes section',
        ),
        SizedBox(height: 16.h),
        _featureCard(
          icon: Icons.flash_on,
          title: 'Unlimited Quick Matches',
          description: 'No daily limit on quick matches',
        ),
        SizedBox(height: 16.h),
        _featureCard(
          icon: Icons.message,
          title: 'Message Anyone',
          description: 'Send messages without matching first',
        ),
      ],
    );
  }

  Widget _featureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: const Color(0xFF1DB954).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF1DB954),
              size: 24.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          _tableRow('Features', 'Free', 'Premium', isHeader: true),
          _tableRow('Quick Matches', '10/day', 'Unlimited'),
          _tableRow('Music Matches', 'Unlimited', 'Unlimited'),
          _tableRow('Messaging', 'After Match', 'Anyone'),
          _tableRow('Profile Visibility', 'Standard', 'Enhanced'),
        ],
      ),
    );
  }

  Widget _tableRow(String feature, String free, String premium,
      {bool isHeader = false}) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[800]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Text(
                feature,
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: isHeader ? FontWeight.w600 : FontWeight.normal,
                  color: isHeader ? const Color(0xFF1DB954) : Colors.white,
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                free,
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  color: Colors.grey[400],
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: isHeader ? const Color(0xFF1DB954).withOpacity(0.1) : null,
              child: Center(
                child: Text(
                  premium,
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    color: isHeader ? const Color(0xFF1DB954) : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscribeButton(context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => const PaymentScreen(
              amount: 25.00, // This will be converted to 200 groszy
              currency: 'PLN',
              merchantName: 'Musee Premium',
            ),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1DB954),
        padding: EdgeInsets.symmetric(vertical: 16.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      child: Text(
        'Get Premium Now',
        style: GoogleFonts.poppins(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSupportEmail() {
    return Center(
      child: Text.rich(
        TextSpan(
          text: 'Questions? Contact us at ',
          style: GoogleFonts.poppins(
            fontSize: 14.sp,
            color: Colors.grey[400],
          ),
          children: const [
            TextSpan(
              text: 'museematchofficial@gmail.com',
              style: TextStyle(
                color: Color(0xFF1DB954),
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}









// Navigator.of(context).push(
//                   CupertinoPageRoute(
//                     builder: (context) => const PaymentScreen(
//                       amount: 2.00, // This will be converted to 200 groszy
//                       currency: 'PLN',
//                       merchantName: 'Musee Premium',
//                     ),