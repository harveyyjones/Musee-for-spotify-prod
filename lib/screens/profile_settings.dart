import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:spotify_project/Business_Logic/firestore_database_service.dart';
import 'package:spotify_project/Helpers/helpers.dart';
import 'package:spotify_project/screens/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spotify_project/screens/register_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileSettings extends StatefulWidget {
  const ProfileSettings({Key? key}) : super(key: key);

  @override
  State<ProfileSettings> createState() => _ProfileSettingsState();
}

class _ProfileSettingsState extends State<ProfileSettings> {
  final FirestoreDatabaseService _databaseService = FirestoreDatabaseService();
  final FirebaseFirestore _instance = FirebaseFirestore.instance;
  List<String> _profilePhotos = [];
  int _currentPhotoIndex = 0;

  // New state variables for age and gender preferences
  int _selectedAge = 25;
  List<String> _selectedGenders = [];
  String? _selectedGender;
  final ScrollController _scrollController = ScrollController();

  // Add these new controllers and variables
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserPreferences(); // Load user preferences when screen initializes
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // Load saved user preferences from Firestore
  Future<void> _loadUserPreferences() async {
    final userData = await _databaseService.getUserData();
    setState(() {
      _selectedAge = userData.age ?? 25;
      _selectedGenders = userData.interestedIn
              ?.cast<String>()
              .map((e) => e.toLowerCase())
              .toList() ??
          [];
      _nameController.text = userData.name ?? '';
      _bioController.text = userData.biography ?? '';
    });
  }

  Future<void> uploadImageToDatabase(File image, int index) async {
    try {
      String fileName = "profile_$index.jpg";
      Reference ref = FirebaseStorage.instance
          .ref()
          .child("users")
          .child(currentUser!.uid)
          .child(fileName);

      UploadTask uploadTask = ref.putFile(image);
      await uploadTask.whenComplete(() async {
        String url = await ref.getDownloadURL();
        if (mounted) {
          setState(() {
            if (index >= _profilePhotos.length) {
              _profilePhotos.add(url);
            } else {
              _profilePhotos[index] = url;
            }
          });
          await _databaseService.updateUserProfileImages(
            profilePhotos: _profilePhotos,
          );
        }
      });
    } catch (e) {
      print("Error uploading image: $e");
    }
  }

  Future<File?> cropImage(File imageFile) async {
    CroppedFile? croppedImage = await ImageCropper().cropImage(
      aspectRatioPresets: [CropAspectRatioPreset.square],
      sourcePath: imageFile.path,
    );
    return croppedImage != null ? File(croppedImage.path) : null;
  }

  Future<void> pickImage(ImageSource source, int index) async {
    try {
      final image = await ImagePicker().pickImage(source: source);
      if (image == null) return;

      final croppedImage = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 70,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Color(0xFF1DB954),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            minimumAspectRatio: 1.0,
            aspectRatioLockEnabled: true,
          ),
        ],
      );

      if (croppedImage != null) {
        await uploadImageToDatabase(File(croppedImage.path), index);
      }
    } on PlatformException catch (e) {
      print('Failed to pick image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: ${e.message}')),
      );
    }
  }

  // Helper method to create consistent section styling
  Widget _buildSettingsSection(String title, Widget child) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1DB954),
              letterSpacing: 0.3,
            ),
          ),
          SizedBox(height: 16.h),
          child,
        ],
      ),
    );
  }

  // Age selector using Cupertino style picker
  Widget _buildAgeSelector() {
    return Container(
      height: 180.h,
      decoration: BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 76.h,
            left: 0,
            right: 0,
            child: Container(
              height: 36.h,
              decoration: BoxDecoration(
                color: Color(0xFF1DB954).withOpacity(0.1),
                border: Border(
                  top: BorderSide(
                    color: Color(0xFF1DB954).withOpacity(0.3),
                    width: 1,
                  ),
                  bottom: BorderSide(
                    color: Color(0xFF1DB954).withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
          CupertinoPicker(
            itemExtent: 36.h,
            diameterRatio: 1.5,
            backgroundColor: Colors.transparent,
            selectionOverlay: Container(),
            onSelectedItemChanged: (int index) {
              setState(() {
                _selectedAge = index + 18;
              });
              _databaseService.updateAge(_selectedAge);
            },
            children: List<Widget>.generate(82, (int index) {
              final age = index + 18;
              return Center(
                child: Text(
                  age.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 20.sp,
                    fontWeight:
                        age == _selectedAge ? FontWeight.w600 : FontWeight.w400,
                    color: age == _selectedAge
                        ? Color(0xFF1DB954)
                        : Colors.white.withOpacity(0.8),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // Gender preference toggle buttons
  Widget _buildGenderToggle() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildGenderButton('Male', Color(0xFF4A90E2)),
          SizedBox(width: 16.w),
          _buildGenderButton('Female', Color(0xFFE24A85)),
        ],
      ),
    );
  }

  // Individual gender toggle button with animations
  Widget _buildGenderButton(String gender, Color color) {
    bool isSelected = _selectedGenders
        .map((e) => e.toLowerCase())
        .contains(gender.toLowerCase());

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedGenders
                  .removeWhere((g) => g.toLowerCase() == gender.toLowerCase());
            } else {
              if (!_selectedGenders
                  .map((e) => e.toLowerCase())
                  .contains(gender.toLowerCase())) {
                _selectedGenders.add(gender);
              }
            }
          });
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 16.h),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected ? color : Colors.white.withOpacity(0.2),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 0,
                      offset: Offset(0, 2),
                    ),
                    BoxShadow(
                      color: color.withOpacity(0.1),
                      blurRadius: 12,
                      spreadRadius: 4,
                      offset: Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                gender == 'Male' ? Icons.male : Icons.female,
                color: isSelected ? color : Colors.white.withOpacity(0.6),
                size: 28.sp,
              ),
              SizedBox(height: 8.h),
              Text(
                gender,
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color:
                      isSelected ? Colors.white : Colors.white.withOpacity(0.6),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveChanges() async {
    try {
      // Update all preferences at once
      await _databaseService.updatePreferences(
        age: _selectedAge,
        interestedIn: _selectedGenders,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Changes saved successfully!',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: Color(0xFF1DB954),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save changes. Please try again.',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Color(0xFF1DB954)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: StreamBuilder(
        stream: _databaseService.getProfileData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
                child: CircularProgressIndicator(color: Color(0xFF1DB954)));
          }

          _profilePhotos =
              List<String>.from(snapshot.data!["profilePhotos"] ?? []);

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            physics: BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildSettingsSection('Photos', _buildPhotoGrid()),
                _buildSettingsSection(
                    'Personal Information', _buildInfoFields()),
                _buildSettingsSection('Age', _buildAgeSection()),
                _buildSettingsSection('Interested In', _buildGenderToggle()),
                SizedBox(height: 24.h),
                _buildActionButtons(),
                SizedBox(height: 24.h),
                _buildDeleteAccountButton(),
                SizedBox(height: 40.h),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPhotoTile(0),
              _buildPhotoTile(1),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPhotoTile(2),
              _buildPhotoTile(3),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoTile(int index) {
    bool hasPhoto = index < _profilePhotos.length;
    return GestureDetector(
      onTap: () => _showImageSourceDialog(index),
      child: Container(
        width: screenWidth / 2.5,
        height: screenWidth / 2.5,
        decoration: BoxDecoration(
          color: Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(13),
          image: hasPhoto
              ? DecorationImage(
                  image: NetworkImage(_profilePhotos[index]),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: !hasPhoto
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo,
                      size: screenWidth / 8, color: Colors.grey[400]),
                  SizedBox(height: 8),
                  Text(
                    'Add Photo',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  void _showImageSourceDialog(int index) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text('Select Photo Source'),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              pickImage(ImageSource.camera, index);
            },
            child: Text('Camera'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              pickImage(ImageSource.gallery, index);
            },
            child: Text('Gallery'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
          isDestructiveAction: true,
        ),
      ),
    );
  }

  Widget _buildInfoFields() {
    return Column(
      children: [
        _buildInfoField(
          'Name',
          _nameController,
          maxLines: 1,
          onChanged: _databaseService.updateName,
        ),
        SizedBox(height: 16.h),
        _buildInfoField(
          'Bio',
          _bioController,
          maxLines: 3,
          onChanged: _databaseService.updateBiography,
        ),
      ],
    );
  }

  Widget _buildInfoField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.poppins(
          fontSize: 16.sp,
          color: Colors.white,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            fontSize: 14.sp,
            color: Colors.white.withOpacity(0.6),
          ),
          floatingLabelStyle: GoogleFonts.poppins(
            fontSize: 16.sp,
            color: Color(0xFF1DB954),
          ),
          contentPadding: EdgeInsets.all(16),
          border: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(
              color: Color(0xFF1DB954),
              width: 2,
            ),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildLogoutButton() {
    return ElevatedButton(
      onPressed: () async {
        try {
          await FirebaseAuth.instance.signOut();
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => LoginPage()),
            (Route<dynamic> route) => false,
          );
        } catch (e) {
          print("Error signing out: $e");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to log out. Please try again.")),
          );
        }
      },
      child: Text('Logout'),
    );
  }

  Widget _buildDeleteAccountButton() {
    return ElevatedButton(
      onPressed: _showDeleteAccountDialog,
      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
      child: Text('Delete Account'),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF2A2A2A),
          title: Text(
            'Delete Account',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Are you sure you want to delete your account? This action cannot be undone.',
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Color(0xFF1DB954),
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                try {
                  Navigator.pop(context); // Close dialog

                  // Show loading indicator
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1DB954),
                        ),
                      );
                    },
                  );

                  // Sign out first, then delete account
                  await _databaseService.signOut(context);
                  await _databaseService.deleteAccount(context);

                  // Navigate to login page
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => LoginPage()),
                    (Route<dynamic> route) => false,
                  );
                } catch (e) {
                  // If deletion fails, remove loading indicator and show error
                  print(e);
                  Navigator.pop(context); // Remove loading indicator
                }
              },
              child: Text(
                'Delete',
                style: GoogleFonts.poppins(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Redesigned action buttons with consistent styling
  Widget _buildActionButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: _saveChanges,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF1DB954),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              minimumSize: Size(double.infinity, 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.r),
              ),
              elevation: 0,
            ),
            child: Text(
              'Save Changes',
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(height: 16.h), // Add spacing between buttons
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => LoginPage()),
                  (Route<dynamic> route) => false,
                );
              } catch (e) {
                print("Error signing out: $e");
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text("Failed to log out. Please try again.")),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              minimumSize: Size(double.infinity, 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.r),
              ),
              elevation: 0,
            ),
            child: Text(
              'Sign Out',
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          // ... rest of the buttons remain the same ...
        ],
      ),
    );
  }

  Widget _buildAgeSection() {
    return GestureDetector(
      onTap: () => _showAgePickerModal(),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Age',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '$_selectedAge',
                  style: GoogleFonts.poppins(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }

  void _showAgePickerModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        height: 300.h,
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(color: Colors.white60),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _databaseService.updateAge(_selectedAge);
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Done',
                    style: GoogleFonts.poppins(color: Color(0xFF1DB954)),
                  ),
                ),
              ],
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 36.h,
                diameterRatio: 1.5,
                backgroundColor: Colors.transparent,
                selectionOverlay: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top:
                          BorderSide(color: Color(0xFF1DB954).withOpacity(0.3)),
                      bottom:
                          BorderSide(color: Color(0xFF1DB954).withOpacity(0.3)),
                    ),
                  ),
                ),
                onSelectedItemChanged: (int index) {
                  setState(() {
                    _selectedAge = index + 18;
                  });
                },
                children: List<Widget>.generate(82, (int index) {
                  final age = index + 18;
                  return Center(
                    child: Text(
                      age.toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 20.sp,
                        fontWeight: age == _selectedAge
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: age == _selectedAge
                            ? Color(0xFF1DB954)
                            : Colors.white.withOpacity(0.8),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
