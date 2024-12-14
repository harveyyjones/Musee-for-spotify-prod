import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';

class MatchLoadingWidget extends StatefulWidget {
  const MatchLoadingWidget({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<MatchLoadingWidget> createState() => _MatchLoadingWidgetState();
}

class _MatchLoadingWidgetState extends State<MatchLoadingWidget> {
  @override
  Widget build(BuildContext context) {
    final mediaQueryData = MediaQuery.of(context);
    final screenWidth = mediaQueryData.size.width;
    final screenHeight = mediaQueryData.size.height;

    return SizedBox(
      width: widget.width ?? screenWidth,
      height: widget.height ?? screenHeight,
      child: Padding(
        padding: EdgeInsets.only(
          left: screenWidth * 0.2,
          right: screenWidth * 0.2,
          top: screenHeight * 0.6,
          bottom: screenHeight * 0.2,
        ),
        child: const LoadingIndicator(
          indicatorType: Indicator.lineScale,
          colors: [Colors.white],
          strokeWidth: 3,
          backgroundColor: Color.fromARGB(255, 0, 0, 0),
          pathBackgroundColor: Colors.black,
        ),
      ),
    );
  }
}
