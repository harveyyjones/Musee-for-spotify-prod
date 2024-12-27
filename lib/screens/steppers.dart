import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:spotify_project/Business_Logic/firestore_database_service.dart';
import 'package:spotify_project/Helpers/helpers.dart';
import 'package:spotify_project/business/Spotify_Logic/constants.dart';
import 'package:spotify_project/business/Spotify_Logic/services/fetch_artists_of_the_user.dart';
import 'package:spotify_project/main.dart';
import 'package:spotify_project/screens/register_page.dart';
import 'package:spotify_project/business/Spotify_Logic/services/fetch_users_saved_tracks.dart';
import 'package:spotify_project/business/Spotify_Logic/services/fetch_recently_played_tracks_service.dart';
import 'package:spotify_project/business/Spotify_Logic/Models/users_saved_tracks_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OnboardingSlider extends StatefulWidget {
  const OnboardingSlider({Key? key}) : super(key: key);

  @override
  State<OnboardingSlider> createState() => _OnboardingSliderState();
}

class _OnboardingSliderState extends State<OnboardingSlider> {
  SpotifyServiceForRecentlyPlayedTracks _spotifyServiceForRecentlyPlayedTracks =
      SpotifyServiceForRecentlyPlayedTracks();
  final FirestoreDatabaseService _firestoreDatabaseService =
      FirestoreDatabaseService();
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  final ValueNotifier<double> _progress = ValueNotifier<double>(0.0);

  String _selectedGender = '';
  List<String> _selectedInterests = [];
  String _selectedAge = '18';
  List<File> _selectedImages = [];
  String? _nameError;

  int _currentPage = 0;
  final int _totalPages = 7;

  final SpotifyServiceForSavedTracks _spotifyService =
      SpotifyServiceForSavedTracks();
  List<Track> savedTracks = [];
  List<Track> selectedTracks = [];
  List<String> selectedHobbies = [];

  bool _hasSpotify = false;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_onScroll);
    _askForSpotifyConnection();
  }

  Future<void> _checkIfHasSpotify() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();

    if (userDoc.exists) {
      setState(() {
        _hasSpotify = userDoc.data()?['hasSpotify'] ?? false;
      });
    }
  }

  void _askForSpotifyConnection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Container(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Connect to',
                      style: TextStyle(
                          fontSize: 25.0, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 20.w),
                    Image.network(
                        'https://storage.googleapis.com/pr-newsroom-wp/1/2023/05/Spotify_Full_Logo_RGB_Green.png',
                        width: 230.w,
                        height: 230.h),
                  ],
                ),
                Text(
                  'Would you like to connect your Spotify account to enhance your experience?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 30.sp,
                  ),
                ),
                SizedBox(height: 20.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _connectToSpotify();
                        _checkIfHasSpotify();
                      },
                      child: Text(
                        'Yes',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w800,
                          fontSize: 40.sp,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser!.uid)
                            .set(
                                {'hasSpotify': false}, SetOptions(merge: true));
                        Navigator.pop(context);

                        _checkIfHasSpotify();
                      },
                      child: Text(
                        'No',
                        style: GoogleFonts.poppins(
                          fontSize: 40.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 90.h),
              ],
            ),
          );
        },
      );
    });
  }

  void _connectToSpotify() async {
    try {
      await businessLogic.connectToSpotifyRemote();
      await _fetchSavedTracks();
      await _spotifyServiceForRecentlyPlayedTracks
          .getRecentlyPlayedTracksFromSpotify();
      await SpotifyServiceForTopArtists()
          .fetchArtists(accessToken: accessToken);

      // Update Firestore to indicate Spotify connection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .set({'hasSpotify': true}, SetOptions(merge: true));
    } catch (e) {
      // Handle any errors here
      print('Error connecting to Spotify: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _progress.dispose();
    super.dispose();
  }

  void _onScroll() {
    final progress = (_pageController.page ?? 0) / (_totalPages - 1);
    _progress.value = progress;
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentPage++;
      });
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentPage--;
      });
    }
  }

  Future<void> _fetchSavedTracks() async {
    final tracksModel = await _spotifyService.getSavedTracks();
    if (tracksModel != null && mounted) {
      setState(() {
        savedTracks = tracksModel.items.map((item) => item.track).toList();
      });
    }
  }

  void _toggleTrackSelection(Track track) {
    setState(() {
      if (selectedTracks.contains(track)) {
        selectedTracks.remove(track);
      } else if (selectedTracks.length < 21) {
        selectedTracks.add(track);
      }
    });
  }

  void _confirmSelection() async {
    final trackData = selectedTracks
        .map((track) => {
              'name': track.name,
              'artist': track.artists.first.name,
              'albumImage': track.album.images.first.url,
              'uri': track.uri,
              'url': track.externalUrls?.spotify,
            })
        .toList();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('spotify')
        .doc('topTracksChoosen')
        .set({'tracks': trackData});

    // Proceed to next onboarding step
    _nextPage();
  }

  Future<void> _saveChosenTopTracks() async {
    final trackData = selectedTracks
        .map((track) => {
              'name': track.name,
              'artist': track.artists.first.name,
              'albumImage': track.album.images.first.url,
              'uri': track.uri,
              'url': track.externalUrls?.spotify,
            })
        .toList();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('spotify')
        .doc('topTracksChoosen')
        .set({'tracks': trackData});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              child: ValueListenableBuilder<double>(
                valueListenable: _progress,
                builder: (context, progress, _) => LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[800],
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFF1DB954)),
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Main Content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  // ******************************** All pages are here ********************************
                  _buildNamePage(),
                  _buildAgePage(),
                  _buildGenderPage(),
                  _buildInterestsPage(),
                  if (_hasSpotify) _buildTrackSelectionPage(),
                  _buildHobbiesSelectionPage(),
                  _buildPhotosPage(),
                ],
              ),
            ),

            // Navigation Buttons
            Padding(
              padding: EdgeInsets.all(24.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: _previousPage,
                      child: Text(
                        'Back',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  ElevatedButton(
                    onPressed: _currentPage == _totalPages - 1
                        ? _completeOnboarding
                        : _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1DB954),
                      padding: EdgeInsets.symmetric(
                        horizontal: 32.w,
                        vertical: 16.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      _currentPage == _totalPages - 1 ? 'Complete' : 'Next',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Page building methods will be added next
  Widget _buildNamePage() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "What's your name?",
            style: TextStyle(
              color: Colors.white,
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'This will be shown to others',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 32.h),
          TextField(
            controller: _nameController,
            style: TextStyle(color: Colors.white, fontSize: 18.sp),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[900],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              hintText: 'Enter your name',
              hintStyle: TextStyle(color: Colors.grey[600]),
              errorText: _nameError,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20.w,
                vertical: 16.h,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _nameError = value.isEmpty ? 'Name is required' : null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAgePage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "How old are you?",
          style: TextStyle(
            color: Colors.white,
            fontSize: 28.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Must be at least 18 years old',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 16.sp,
          ),
        ),
        SizedBox(height: 32.h),
        Container(
          height: 200.h,
          margin: EdgeInsets.symmetric(horizontal: 24.w),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: CupertinoPicker(
            itemExtent: 40,
            backgroundColor: Colors.transparent,
            onSelectedItemChanged: (index) {
              setState(() {
                _selectedAge = (index + 18).toString();
              });
            },
            children: List.generate(
              83, // 18 to 100
              (index) => Center(
                child: Text(
                  '${index + 18}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderPage() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "What's your gender?",
            style: TextStyle(
              color: Colors.white,
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 40.h),
          Row(
            children: [
              Expanded(
                child: _buildGenderButton(
                  'male',
                  'Male',
                  const Color(0xFF2196F3),
                  Icons.male,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildGenderButton(
                  'female',
                  'Female',
                  const Color(0xFFE91E63),
                  Icons.female,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderButton(
      String value, String label, Color color, IconData icon) {
    final isSelected = _selectedGender == value;

    return GestureDetector(
      onTap: () => setState(() => _selectedGender = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 24.h),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey[400],
              size: 40.sp,
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey[400],
                fontSize: 16.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterestsPage() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Who are you interested in?",
            style: TextStyle(
              color: Colors.white,
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Select all that apply',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 40.h),
          Row(
            children: [
              Expanded(
                child: _buildInterestButton(
                  'male',
                  'Men',
                  const Color(0xFF2196F3),
                  Icons.male,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildInterestButton(
                  'female',
                  'Women',
                  const Color(0xFFE91E63),
                  Icons.female,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInterestButton(
      String value, String label, Color color, IconData icon) {
    final isSelected = _selectedInterests.contains(value);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedInterests.remove(value);
          } else {
            _selectedInterests.add(value);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 24.h),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey[400],
              size: 40.sp,
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey[400],
                fontSize: 16.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosPage() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Add your photos",
            style: TextStyle(
              color: Colors.white,
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Add up to 4 photos',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 32.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.w,
              mainAxisSpacing: 16.h,
            ),
            itemCount: 4,
            itemBuilder: (context, index) {
              final hasImage = index < _selectedImages.length;

              return GestureDetector(
                onTap: () => hasImage ? _removeImage(index) : _pickImage(),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                    image: hasImage
                        ? DecorationImage(
                            image: FileImage(_selectedImages[index]),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: !hasImage
                      ? Center(
                          child: Icon(
                            Icons.add_photo_alternate,
                            color: Colors.grey[600],
                            size: 40.sp,
                          ),
                        )
                      : null,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final croppedImage = await ImageCropper().cropImage(
      sourcePath: image.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressQuality: 70,
    );

    if (croppedImage != null && _selectedImages.length < 4) {
      setState(() {
        _selectedImages.add(File(croppedImage.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _completeOnboarding() async {
    // Validate all required fields
    if (_nameController.text.isEmpty) {
      setState(() => _nameError = 'Name is required');
      _pageController.animateToPage(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      return;
    }

    if (_selectedGender.isEmpty) {
      _pageController.animateToPage(2,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      return;
    }

    if (_selectedInterests.isEmpty) {
      _pageController.animateToPage(3,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1DB954)),
          ),
        ),
      );

      // Upload images first if any
      List<String> photoUrls = [];
      if (_selectedImages.isNotEmpty) {
        photoUrls = await _uploadImages();
      }

      // Save all user data
      await _saveUserData(photoUrls);

      // Set the onboarding completion flag
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .set({'isSteppersFinished': true}, SetOptions(merge: true));

      // Navigate to home screen
      if (mounted) {
        Navigator.of(context).pop(); // Dismiss loading indicator
        // Navigate to your home screen
        Navigator.pushReplacement(
            context, CupertinoPageRoute(builder: (context) => Home()));
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Dismiss loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<List<String>> _uploadImages() async {
    List<String> urls = [];
    for (var i = 0; i < _selectedImages.length; i++) {
      final ref = FirebaseStorage.instance
          .ref()
          .child('users/${currentUser!.uid}/profile_$i.jpg');

      final uploadTask = ref.putFile(_selectedImages[i]);
      final snapshot = await uploadTask.whenComplete(() {});
      final url = await snapshot.ref.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }

  Future<void> _saveUserData(List<String> photoUrls) async {
    await _firestoreDatabaseService.saveUser(
      name: _nameController.text,
      age: int.parse(_selectedAge),
      gender: _selectedGender,
      interestedIn: _selectedInterests,
      profilePhotos: photoUrls,
    );

    // Save hobbies to Firebase
    await _saveHobbies();

    // Save top tracks to Firebase only if hasSpotify is true
    if (_hasSpotify) {
      await _saveChosenTopTracks();
    }
  }

  Future<void> _saveHobbies() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final userInterestsDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('interests')
        .doc('hobbies');

    await userInterestsDoc.set({
      'hobbies': selectedHobbies,
    });
  }

  Widget _buildTrackSelectionPage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Select Your Top Tracks",
          style: TextStyle(
            color: Colors.white,
            fontSize: 28.sp * 1.4,
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.all(16.w),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10.h,
              crossAxisSpacing: 16.w,
              childAspectRatio: 2,
            ),
            itemCount: savedTracks.length,
            itemBuilder: (context, index) {
              final track = savedTracks[index];
              final isSelected = selectedTracks.contains(track);
              final imageUrl = track.album.images.isNotEmpty
                  ? track.album.images.first.url
                  : null;

              return GestureDetector(
                onTap: () => _toggleTrackSelection(track),
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 8.h),
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blue.withOpacity(0.2)
                        : Colors.grey[900],
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (imageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: Image.network(
                            imageUrl,
                            width: 80.w * 1.4,
                            height: 80.h * 1.4,
                            fit: BoxFit.cover,
                          ),
                        ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              track.name ?? 'Unknown',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 25.sp,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              track.artists.first.name ?? 'Unknown',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 16.sp * 1.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHobbiesSelectionPage() {
    final categoriesMap = categories['categories'] as Map<String, dynamic>;
    final hobbies = categoriesMap.values
        .expand((category) => (category['interests'] as List<dynamic>))
        .map((interest) => interest['name'] as String)
        .toList();

    // Define a list of colors for categories
    final categoryColors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Select Your Hobbies",
          style: TextStyle(
            color: Colors.white,
            fontSize: 28.sp * 1.5, // Increase font size by 50%
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.all(16.w),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 5.h, // Reduce height
              crossAxisSpacing: 16.w,
              childAspectRatio: 3, // Adjust aspect ratio for smaller height
            ),
            itemCount: hobbies.length,
            itemBuilder: (context, index) {
              final hobby = hobbies[index];
              final isSelected = selectedHobbies.contains(hobby);
              final color = categoryColors[index % categoryColors.length];

              return GestureDetector(
                onTap: () => _toggleHobbySelection(hobby),
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 4.h), // Reduce height
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? color.withOpacity(0.2) : Colors.grey[900],
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: isSelected ? color : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      hobby,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp * 1.5, // Increase font size by 50%
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _toggleHobbySelection(String hobby) {
    setState(() {
      if (selectedHobbies.contains(hobby)) {
        selectedHobbies.remove(hobby);
      } else {
        selectedHobbies.add(hobby);
      }
    });
  }
}
