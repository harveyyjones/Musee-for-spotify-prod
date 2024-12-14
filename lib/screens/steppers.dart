import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:spotify_project/Business_Logic/firestore_database_service.dart';
import 'package:spotify_project/main.dart';
import 'package:spotify_project/screens/register_page.dart';

class OnboardingSlider extends StatefulWidget {
  const OnboardingSlider({Key? key}) : super(key: key);

  @override
  State<OnboardingSlider> createState() => _OnboardingSliderState();
}

class _OnboardingSliderState extends State<OnboardingSlider> {
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
  final int _totalPages = 5;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_onScroll);
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
                  _buildNamePage(),
                  _buildAgePage(),
                  _buildGenderPage(),
                  _buildInterestsPage(),
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
  }
}
