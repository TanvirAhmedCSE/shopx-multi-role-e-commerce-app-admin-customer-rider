import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../app/app_colors.dart';
import '../../data/services/cloudinary_service.dart';
import '../../data/services/firestore_service.dart';
import 'rider_setup_finishing_view.dart';
import '../../data/services/secondary_auth_service.dart';

class RiderSetupProfileView extends StatefulWidget {
  const RiderSetupProfileView({super.key});

  @override
  State<RiderSetupProfileView> createState() => _RiderSetupProfileViewState();
}

class _RiderSetupProfileViewState extends State<RiderSetupProfileView> {
  final _nameCtrl = TextEditingController();
  Uint8List? _pickedBytes;
  String? _pickedFilename;
  bool _nameError = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _pickedBytes = bytes;
      _pickedFilename = file.name;
    });
  }

  Future<void> _onDone() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = true);
      return;
    }
    setState(() {
      _nameError = false;
      _isSaving = true;
    });

    final uid = SecondaryAuthService.currentUser?.uid;
    if (uid == null) {
      setState(() => _isSaving = false);
      return;
    }

    String avatarUrl = '';
    try {
      if (_pickedBytes != null) {
        avatarUrl = await CloudinaryService.uploadImage(
          _pickedBytes!,
          _pickedFilename ?? 'rider_avatar.jpg',
        );
      }
      await FirestoreService.saveRiderSetupProfile(
        db: await SecondaryAuthService.firestore(),
        uid: uid,
        name: name,
        avatarUrl: avatarUrl,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      Get.snackbar(
        'Error',
        'Profile save failed: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    if (!mounted) return;
    Get.off(() => const RiderSetupFinishingView());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Rider Profile Setup'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary,
                            width: 2.5,
                          ),
                          color: AppColors.surface,
                        ),
                        child: ClipOval(
                          child: _pickedBytes != null
                              ? Image.memory(_pickedBytes!, fit: BoxFit.cover)
                              : const Icon(
                                  Icons.person,
                                  size: 54,
                                  color: AppColors.textSecondary,
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.background,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Click to pick profile picture from device',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Rider Name',
                    errorText: _nameError ? 'Name is required' : null,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _onDone,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Done'),
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
