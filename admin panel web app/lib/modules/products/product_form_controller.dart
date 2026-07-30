import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/admin_product_model.dart';
import '../../data/services/cloudinary_service.dart';
import '../../data/services/firestore_service.dart';
import '../categories/categories_controller.dart';
import 'package:image/image.dart' as img;

enum IdStatus { idle, invalid, checking, available, taken }

class PickedImage {
  final String? existingUrl;
  final Uint8List? bytes;
  final String filename;
  final bool useContain; // true = transparent bg: contain, false: cover

  PickedImage.existing(this.existingUrl, {this.useContain = false})
    : bytes = null,
      filename = '';

  PickedImage.picked(this.bytes, this.filename, {required this.useContain})
    : existingUrl = null;
}

class ProductFormController extends GetxController {
  final AdminProduct? existing;
  ProductFormController({this.existing});

  final idController = TextEditingController();
  final titleController = TextEditingController();
  final priceController = TextEditingController();
  final descriptionController = TextEditingController();

  final selectedCategory = Rxn<String>();
  final images = <PickedImage>[].obs;
  final idStatus = IdStatus.idle.obs;
  final isSaving = false.obs;

  Timer? _debounce;

  bool get isEdit => existing != null;

  @override
  void onInit() {
    super.onInit();
    if (isEdit) {
      final p = existing!;
      idController.text = p.id;
      titleController.text = p.title;
      priceController.text = p.price.toString();
      descriptionController.text = p.description;
      selectedCategory.value = p.category;
      images.assignAll(
        p.images.asMap().entries.map((e) {
          final contain = e.key < p.imagesPng.length
              ? p.imagesPng[e.key]
              : e.value.toLowerCase().split('?').first.endsWith('.png');
          return PickedImage.existing(e.value, useContain: contain);
        }),
      );
      idStatus.value = IdStatus.available;
    }
  }

  @override
  void onClose() {
    _debounce?.cancel();
    idController.dispose();
    titleController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  void onIdChanged(String value) {
    if (isEdit) return;

    _debounce?.cancel();
    final trimmed = value.trim();

    if (!RegExp(r'^\d{5}$').hasMatch(trimmed)) {
      idStatus.value = IdStatus.invalid;
      return;
    }

    idStatus.value = IdStatus.checking;
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final exists = await FirestoreService.idExists(trimmed);
      idStatus.value = exists ? IdStatus.taken : IdStatus.available;
    });
  }

  Future<void> pickImages() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 85);
    for (final f in files) {
      final bytes = await f.readAsBytes();
      final isPngExt = f.name.toLowerCase().endsWith('.png');

      bool useContain = false;
      if (isPngExt) {
        useContain = await _hasTransparentBackground(bytes);
      }

      images.add(PickedImage.picked(bytes, f.name, useContain: useContain));
    }
  }

  Future<bool> _hasTransparentBackground(Uint8List bytes) async {
    try {
      final image = img.decodeImage(bytes);
      if (image == null || !image.hasAlpha) return false;

      final width = image.width;
      final height = image.height;
      const step = 4;

      int totalSampled = 0;
      int transparentCount = 0;

      for (int y = 0; y < height; y += step) {
        for (int x = 0; x < width; x += step) {
          final pixel = image.getPixel(x, y);
          final alpha = pixel.a;
          totalSampled++;
          if (alpha < 250) transparentCount++;
        }
      }

      if (totalSampled == 0) return false;
      final transparentRatio = transparentCount / totalSampled;
      return transparentRatio >= 0.05;
    } catch (_) {
      return false;
    }
  }

  void removeImageAt(int index) => images.removeAt(index);

  Future<void> addNewCategory() async {
    final nameController = TextEditingController();
    final iconController = TextEditingController();
    final errorText = ''.obs;
    final catsCtrl = Get.isRegistered<CategoriesController>()
        ? Get.find<CategoriesController>()
        : Get.put(CategoriesController());

    await Get.dialog(
      AlertDialog(
        title: const Text('New Category'),
        content: SizedBox(
          width: 360,
          child: Obx(
            () => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'e.g. Electronics',
                    errorText: errorText.value.isEmpty ? null : errorText.value,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: iconController,
                  decoration: const InputDecoration(
                    hintText: 'Iconsax icon name, e.g. headphone',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final combined =
                  '${nameController.text.trim()}-${iconController.text.trim()}';
              final err = await catsCtrl.addCategory(combined);
              if (err != null) {
                errorText.value = err;
              } else {
                selectedCategory.value = combined;
                Get.back();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String? validateForSave() {
    if (!isEdit && idStatus.value != IdStatus.available) {
      return 'Unique 5-digit ID দাও (available দেখাচ্ছে কিনা চেক করো)';
    }
    if (titleController.text.trim().isEmpty) return 'Title দাও';
    if (double.tryParse(priceController.text.trim()) == null)
      return 'সঠিক Price দাও';
    if (descriptionController.text.trim().isEmpty) return 'Description দাও';
    if (selectedCategory.value == null || selectedCategory.value!.isEmpty) {
      return 'Category select করো';
    }
    if (images.isEmpty) return 'অন্তত একটা image দাও';
    return null;
  }

  Future<bool> save() async {
    final error = validateForSave();
    if (error != null) {
      Get.snackbar(
        'Fix this first',
        error,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    isSaving(true);
    try {
      final finalUrls = <String>[];
      final finalPngFlags = <bool>[];
      for (final img in images) {
        if (img.existingUrl != null) {
          finalUrls.add(img.existingUrl!);
          finalPngFlags.add(img.useContain);
        } else {
          final url = await CloudinaryService.uploadImage(
            img.bytes!,
            img.filename,
          );
          finalUrls.add(url);
          finalPngFlags.add(img.useContain);
        }
      }

      final product = AdminProduct(
        id: isEdit ? existing!.id : idController.text.trim(),
        title: titleController.text.trim(),
        price: double.parse(priceController.text.trim()),
        description: descriptionController.text.trim(),
        category: selectedCategory.value!,
        image: finalUrls.first,
        images: finalUrls,
        imagesPng: finalPngFlags,
        rating: isEdit ? existing!.rating : 0.0,
        ratingCount: isEdit ? existing!.ratingCount : 0,
      );

      if (isEdit) {
        await FirestoreService.updateProduct(product);
      } else {
        await FirestoreService.createProduct(product);
      }

      Get.back();
      Get.snackbar(
        'Success',
        isEdit ? 'Product updated' : 'Product created',
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isSaving(false);
    }
  }
}
