import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/firestore_service.dart';

enum CategorySortField { name, price, rating, products }

enum CategorySortDirection { asc, desc }

class CategoryAggregate {
  final String raw; // full combined string, e.g. "Electronics-headphone"
  final String name;
  final String icon;
  final int count;
  final double avgRating;
  final double sumPrice;

  CategoryAggregate({
    required this.raw,
    required this.name,
    required this.icon,
    required this.count,
    required this.avgRating,
    required this.sumPrice,
  });
}

class CategoriesController extends GetxController {
  final categories = <String>[].obs;
  final isAdding = false.obs;
  final productCountByCategory = <String, int>{}.obs;
  final avgRatingByCategory = <String, double>{}.obs;
  final sumPriceByCategory = <String, double>{}.obs;

  // Search bar
  final searchQuery = ''.obs;

  final sortStates = <CategorySortField, CategorySortDirection?>{
    CategorySortField.name: null,
    CategorySortField.price: null,
    CategorySortField.rating: null,
    CategorySortField.products: null,
  }.obs;
  final sortPriority = <CategorySortField>[].obs;

  //  Advanced filters
  static const double productsMin = 1;
  static const double productsMax = 300;
  static const double ratingMin = 1.0;
  static const double ratingMax = 5.0;

  final Rxn<RangeValues> productsRangeFilter = Rxn<RangeValues>();
  final Rxn<RangeValues> ratingRangeFilter = Rxn<RangeValues>();
  final Rxn<RangeValues> priceRangeFilter = Rxn<RangeValues>();

  @override
  void onInit() {
    super.onInit();
    FirestoreService.categoriesStream().listen((list) {
      categories.assignAll(list);
    });
    FirestoreService.productsStream().listen((products) {
      final counts = <String, int>{};
      final ratingSums = <String, double>{};
      final priceSums = <String, double>{};
      for (final p in products) {
        counts[p.category] = (counts[p.category] ?? 0) + 1;
        ratingSums[p.category] = (ratingSums[p.category] ?? 0) + p.rating;
        priceSums[p.category] = (priceSums[p.category] ?? 0) + p.price;
      }
      productCountByCategory.assignAll(counts);
      priceSums.updateAll((_, v) => v);
      sumPriceByCategory.assignAll(priceSums);
      final avgMap = <String, double>{};
      ratingSums.forEach((k, v) => avgMap[k] = v / (counts[k] ?? 1));
      avgRatingByCategory.assignAll(avgMap);
    });
  }

  Future<String?> addCategory(String name) async {
    if (name.trim().isEmpty) return 'Category name is empty';
    isAdding(true);
    final ok = await FirestoreService.addCategory(name);
    isAdding(false);
    return ok ? null : 'This category already exists';
  }

  Future<void> deleteCategory(String name) =>
      FirestoreService.deleteCategory(name);

  Future<String?> updateCategory(
    CategoryAggregate cat,
    String newName,
    String newIcon,
  ) async {
    if (newName.trim().isEmpty) return 'Category name is empty';
    try {
      await FirestoreService.updateCategory(
        oldRaw: cat.raw,
        newName: newName,
        newIcon: newIcon,
      );
      return null;
    } catch (_) {
      return 'This category already exists';
    }
  }

  static (String, String?) splitNameIcon(String raw) {
    final idx = raw.lastIndexOf('-');
    if (idx <= 0 || idx == raw.length - 1) return (raw, null);
    return (raw.substring(0, idx), raw.substring(idx + 1));
  }

  int productCountFor(String rawCategory) =>
      productCountByCategory[rawCategory] ?? 0;

  void setSearchQuery(String q) => searchQuery.value = q;

  void setSort(CategorySortField? field, CategorySortDirection? direction) {
    sortStates.updateAll((key, value) => null);
    sortPriority.clear();
    if (field != null && direction != null) {
      sortStates[field] = direction;
      sortPriority.add(field);
    }
    sortStates.refresh();
  }

  bool get isSortAllSelected => sortPriority.isEmpty;

  // Cheapest category's total price, from live Firestore-derived data.
  double? get categoryPriceMin {
    if (sumPriceByCategory.isEmpty) return null;
    return sumPriceByCategory.values.reduce((a, b) => a < b ? a : b);
  }

  // Most expensive category's total price, from live Firestore-derived data.
  double? get categoryPriceMax {
    if (sumPriceByCategory.isEmpty) return null;
    return sumPriceByCategory.values.reduce((a, b) => a > b ? a : b);
  }

  void applyAdvancedFilters({
    RangeValues? productsRange,
    RangeValues? ratingRange,
    RangeValues? priceRange,
  }) {
    productsRangeFilter.value = productsRange;
    ratingRangeFilter.value = ratingRange;
    priceRangeFilter.value = priceRange;
  }

  bool get hasActiveFilters =>
      !isSortAllSelected ||
      productsRangeFilter.value != null ||
      ratingRangeFilter.value != null ||
      priceRangeFilter.value != null;

  List<CategoryAggregate> get filteredCategories {
    var list = categories.map((raw) {
      final parts = splitNameIcon(raw);
      return CategoryAggregate(
        raw: raw,
        name: parts.$1,
        icon: parts.$2 ?? '',
        count: productCountByCategory[raw] ?? 0,
        avgRating: avgRatingByCategory[raw] ?? 0.0,
        sumPrice: sumPriceByCategory[raw] ?? 0.0,
      );
    }).toList();

    final q = searchQuery.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((c) => c.name.toLowerCase().contains(q)).toList();
    }

    final pcr = productsRangeFilter.value;
    if (pcr != null) {
      list = list
          .where((c) => c.count >= pcr.start && c.count <= pcr.end)
          .toList();
    }

    final rr = ratingRangeFilter.value;
    if (rr != null) {
      list = list
          .where((c) => c.avgRating >= rr.start && c.avgRating <= rr.end)
          .toList();
    }

    final pr = priceRangeFilter.value;
    if (pr != null) {
      list = list
          .where((c) => c.sumPrice >= pr.start && c.sumPrice <= pr.end)
          .toList();
    }

    if (sortPriority.isNotEmpty) {
      final field = sortPriority.first;
      final dir = sortStates[field];
      if (dir != null) {
        list.sort((a, b) {
          int cmp;
          switch (field) {
            case CategorySortField.name:
              cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
              break;
            case CategorySortField.price:
              cmp = a.sumPrice.compareTo(b.sumPrice);
              break;
            case CategorySortField.rating:
              cmp = a.avgRating.compareTo(b.avgRating);
              break;
            case CategorySortField.products:
              cmp = a.count.compareTo(b.count);
              break;
          }
          return dir == CategorySortDirection.desc ? -cmp : cmp;
        });
      }
    }

    return list;
  }
}
