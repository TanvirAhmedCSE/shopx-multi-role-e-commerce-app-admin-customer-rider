import 'dart:async';
import 'package:get/get.dart';
import '../../data/models/product_model.dart';
import '../../data/services/firestore_product_service.dart';

class HomeController extends GetxController {
  final products = <ProductModel>[].obs;
  final categories = <String>[].obs;
  final selectedCategory = 'all'.obs;
  final isLoading = true.obs;
  final error = ''.obs;
  final showPromoBanner = false.obs;

  StreamSubscription<List<ProductModel>>? _productsSub;
  StreamSubscription<List<String>>? _categoriesSub;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  void triggerPromoBanner() {
    if (showPromoBanner.value) return;
    showPromoBanner(true);
    Future.delayed(const Duration(milliseconds: 5000), () {
      showPromoBanner(false);
    });
  }

  Future<void> loadData() async {
    isLoading(true);
    error('');

    await _productsSub?.cancel();
    await _categoriesSub?.cancel();

    _categoriesSub = FirestoreProductService.categoriesStream().listen(
      (cats) => categories.assignAll(cats),
      onError: (_) {},
    );

    _productsSub = FirestoreProductService.productsStream().listen(
      (list) {
        products.assignAll(list);
        isLoading(false);
      },
      onError: (_) {
        error('Failed to load products. Check your internet connection.');
        isLoading(false);
        Future.delayed(const Duration(seconds: 1), () {
          if (error.isNotEmpty) loadData();
        });
      },
    );
  }

  List<ProductModel> get filteredProducts {
    if (selectedCategory.value == 'all') return products;
    return products.where((p) => p.category == selectedCategory.value).toList();
  }

  void selectCategory(String cat) => selectedCategory(cat);

  @override
  void onClose() {
    _productsSub?.cancel();
    _categoriesSub?.cancel();
    super.onClose();
  }
}
