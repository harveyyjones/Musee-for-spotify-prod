// match_screen.dart
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:spotify_project/Business_Logic/Models/message_model.dart';
import 'dart:math';

import 'package:spotify_project/Business_Logic/Models/user_model.dart';
import 'package:spotify_project/Business_Logic/chat_services/chat_database_service.dart';
import 'package:spotify_project/screens/register_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:spotify_project/screens/chat_screen.dart';

class MatchScreen extends StatefulWidget {
  final UserModel matchedUser;

  const MatchScreen({
    Key? key,
    required this.matchedUser,
  }) : super(key: key);

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3))..play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.05,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "It's a Match!",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  CircleAvatar(
                    radius: 100,
                    backgroundImage:
                        NetworkImage(widget.matchedUser.profilePhotos.first),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Keep Swiping'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                widget.matchedUser.userId.toString(),
                                widget.matchedUser.profilePhotos.first,
                                widget.matchedUser.name.toString(),
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text('Start Chat'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
