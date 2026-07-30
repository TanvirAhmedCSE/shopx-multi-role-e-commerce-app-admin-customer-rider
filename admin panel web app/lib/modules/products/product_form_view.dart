import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/app_colors.dart';
import '../../data/models/admin_product_model.dart';
import '../categories/categories_controller.dart';
import 'product_form_controller.dart';
import '../../../../core/utils/cloudinary_image_utils.dart';

class ProductFormView extends StatelessWidget {
  final AdminProduct? existing;
  const ProductFormView({super.key, this.existing});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(ProductFormController(existing: existing));
    final catsCtrl = Get.isRegistered<CategoriesController>()
        ? Get.find<CategoriesController>()
        : Get.put(CategoriesController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text(ctrl.isEdit ? 'Edit Product' : 'Add Product'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: SizedBox(
            width: 640,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _idField(ctrl),
                const SizedBox(height: 18),
                _labeled('Title', TextField(controller: ctrl.titleController)),
                const SizedBox(height: 18),
                _labeled(
                  'Price (\$)',
                  TextField(
                    controller: ctrl.priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _labeled(
                  'Description',
                  TextField(
                    controller: ctrl.descriptionController,
                    maxLines: 4,
                  ),
                ),
                const SizedBox(height: 18),
                _categoryField(ctrl, catsCtrl),
                const SizedBox(height: 18),
                _imagesField(ctrl),
                const SizedBox(height: 32),
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: ctrl.isSaving.value ? null : ctrl.save,
                      child: ctrl.isSaving.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              ctrl.isEdit ? 'Update Product' : 'Create Product',
                            ),
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

  Widget _labeled(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _idField(ProductFormController ctrl) {
    return _labeled(
      'Product ID (5 digits, unique)',
      Obx(
        () => TextField(
          controller: ctrl.idController,
          enabled: !ctrl.isEdit,
          keyboardType: TextInputType.number,
          maxLength: 5,
          onChanged: ctrl.onIdChanged,
          decoration: InputDecoration(
            counterText: '',
            suffixIcon: _idStatusIcon(ctrl.idStatus.value),
            helperText: _idStatusText(ctrl.idStatus.value),
            helperStyle: TextStyle(
              color:
                  (ctrl.idStatus.value == IdStatus.taken ||
                      ctrl.idStatus.value == IdStatus.invalid)
                  ? AppColors.error
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget? _idStatusIcon(IdStatus status) {
    switch (status) {
      case IdStatus.checking:
        return const Padding(
          padding: EdgeInsets.all(14),
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      case IdStatus.available:
        return const Icon(Icons.check_circle, color: AppColors.success);
      case IdStatus.taken:
      case IdStatus.invalid:
        return const Icon(Icons.error, color: AppColors.error);
      case IdStatus.idle:
        return null;
    }
  }

  String? _idStatusText(IdStatus status) {
    switch (status) {
      case IdStatus.invalid:
        return 'ID অবশ্যই ঠিক 5 digit সংখ্যা হতে হবে';
      case IdStatus.taken:
        return 'এই ID already ব্যবহৃত — অন্য একটা ID দাও';
      case IdStatus.available:
        return 'ID available ✓';
      case IdStatus.checking:
        return 'চেক করা হচ্ছে...';
      case IdStatus.idle:
        return null;
    }
  }

  Widget _categoryField(
    ProductFormController ctrl,
    CategoriesController catsCtrl,
  ) {
    return _labeled(
      'Category',
      Obx(
        () => Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: ctrl.selectedCategory.value,

                items: catsCtrl.categories
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(CategoriesController.splitNameIcon(c).$1),
                      ),
                    )
                    .toList(),
                onChanged: (v) => ctrl.selectedCategory.value = v,
                decoration: const InputDecoration(hintText: 'Select category'),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: ctrl.addNewCategory,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('New'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagesField(ProductFormController ctrl) {
    return _labeled(
      'Images',
      Obx(
        () => Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ...List.generate(ctrl.images.length, (i) {
              final img = ctrl.images[i];
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: img.existingUrl != null
                        ? Image.network(
                            CloudinaryImageUtils.transform(
                              img.existingUrl!,
                              width: 180,
                              height: 180,
                            ),
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                          )
                        : Image.memory(
                            img.bytes!,
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                  ),
                  Positioned(
                    top: -6,
                    right: -6,
                    child: GestureDetector(
                      onTap: () => ctrl.removeImageAt(i),
                      child: const CircleAvatar(
                        radius: 11,
                        backgroundColor: AppColors.error,
                        child: Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            }),
            GestureDetector(
              onTap: ctrl.pickImages,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.add_photo_alternate_outlined,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
