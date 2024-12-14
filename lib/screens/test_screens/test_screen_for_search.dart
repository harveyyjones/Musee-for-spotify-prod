import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spotify_project/Business_Logic/Models/message_model.dart';
import 'package:spotify_project/Business_Logic/chat_services/chat_database_service.dart';
import 'package:spotify_project/business/Spotify_Logic/Models/track_from_search_model.dart';
import 'package:spotify_project/business/Spotify_Logic/services/spotify_search_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'dart:convert';

class TestSearchScreen extends StatefulWidget {
  const TestSearchScreen({super.key, required this.userIDOfOtherUser});
  final String userIDOfOtherUser;

  @override
  State<TestSearchScreen> createState() => _TestSearchScreenState();
}

class _TestSearchScreenState extends State<TestSearchScreen> {
  // Constants for styling
  static const backgroundColor = Color(0xFF121212);
  static const cardColor = Color(0xFF282828);
  static const primaryPurple = Color(0xFF9C27B0);
  static const accentPurple = Color(0xFFE1BEE7);

  ChatDatabaseService chatDatabaseService = ChatDatabaseService();
  final TextEditingController _searchController = TextEditingController();
  List<TrackFromSearch> _searchResults = [];
  bool _isLoading = false;
  String? _error;
  String? _accessToken;

  @override
  void initState() {
    super.initState();
    _getValidToken();
  }

  Future<void> _getValidToken() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('tokens')
          .doc('spotify')
          .get();

      if (!doc.exists || doc.data()?['tokens'] == null) {
        // No token, get new one
        final newToken = await SpotifySdk.getAccessToken(
            clientId: '32a50962636143748e6779e2f604e07b',
            redirectUrl: 'com-developer-spotifyproject://callback',
            scope: 'app-remote-control '
                'user-modify-playback-state '
                'playlist-read-private '
                'user-library-read '
                'playlist-modify-public '
                'user-read-currently-playing '
                'user-top-read');

        await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .collection('tokens')
            .doc('spotify')
            .set({
          'tokens': newToken,
          'lastUpdated': DateTime.now(),
        });

        _accessToken = newToken;
      } else {
        final lastUpdated = (doc.data()?['lastUpdated'] as Timestamp).toDate();
        if (DateTime.now().difference(lastUpdated).inMinutes < 50) {
          _accessToken = doc.data()?['tokens'];
        } else {
          // Token expired, get new one
          await _getValidToken();
        }
      }
    } catch (e) {
      print('Error getting token: $e');
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_accessToken == null) {
        await _getValidToken();
      }

      final searchResponse =
          await SpotifySearchService(_accessToken!).searchTracks(query);

      setState(() {
        _searchResults = searchResponse.tracks;
        _isLoading = false;
      });
    } catch (e) {
      print('Error during search: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(
          'Search Songs',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 24,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: _buildSearchField(),
          ),
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: 'Search for songs...',
          hintStyle: GoogleFonts.poppins(
            color: Colors.grey[400],
            fontSize: 16,
          ),
          prefixIcon: const Icon(Icons.search, color: primaryPurple),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: _performSearch,
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primaryPurple),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(
          'Error: $_error',
          style: GoogleFonts.poppins(
            color: Colors.red[300],
            fontSize: 16,
          ),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_note,
              size: 48,
              color: Colors.grey[700],
            ),
            const SizedBox(height: 16),
            Text(
              'Start searching for songs',
              style: GoogleFonts.poppins(
                color: Colors.grey[500],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final track = _searchResults[index];
        return _buildTrackCard(track);
      },
    );
  }

  Widget _buildTrackCard(TrackFromSearch track) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _handleTrackSelection(track),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildAlbumArt(track),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.name,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        track.artists.map((artist) => artist.name).join(', '),
                        style: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.send,
                  color: primaryPurple,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumArt(TrackFromSearch track) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: track.album.images.isNotEmpty
            ? _getImageWidget(track.album.images.first)
            : Container(
                color: primaryPurple.withOpacity(0.2),
                child: const Icon(
                  Icons.music_note,
                  color: primaryPurple,
                ),
              ),
      ),
    );
  }

  Widget _getImageWidget(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      // Base64 image
      final base64String = imageUrl.split(',').last;
      final bytes = base64Decode(base64String);
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
      );
    } else {
      // Network image
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
      );
    }
  }

  void _handleTrackSelection(TrackFromSearch track) {
    Message messageToSaveAndSend = Message(
      fromWhom: FirebaseAuth.instance.currentUser!.uid,
      date: FieldValue.serverTimestamp(),
      isSentByMe: true,
      message:
          '@@@Track: ${track.name} -- ArtistName: ${track.artists.map((artist) => artist.name).join(', ')} -- Image: ${track.album.images.first} -- Uri: ${track.uri}',
      toWhom: widget.userIDOfOtherUser,
    );

    chatDatabaseService.sendMessage(messageToSaveAndSend);
    Navigator.of(context).pop();
  }
}
