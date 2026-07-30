import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/admin_product_model.dart';
import '../../data/services/firestore_service.dart';

enum SortField { id, price, rating }

enum SortDirection { asc, desc }

class ProductsController extends GetxController {
  final products = <AdminProduct>[].obs;
  final isLoading = true.obs;

  final searchQuery = ''.obs;

  final sortStates = <SortField, SortDirection?>{
    SortField.id: null,
    SortField.price: null,
    SortField.rating: null,
  }.obs;
  final sortPriority = <SortField>[].obs;

  final selectedCategories = <String>{}.obs;

  //  Advanced filters
  static const double priceMin = 1;
  static const double priceMax = 1000;
  static const double ratingMin = 1.0;
  static const double ratingMax = 5.0;
  static const double reviewCountMin = 1;
  static const double reviewCountMax = 300;

  final Rxn<RangeValues> priceRangeFilter = Rxn<RangeValues>();
  final Rxn<RangeValues> ratingRangeFilter = Rxn<RangeValues>();
  final Rxn<RangeValues> reviewCountRangeFilter = Rxn<RangeValues>();
  final Rxn<int> idRangeStart = Rxn<int>();
  final Rxn<int> idRangeEnd = Rxn<int>();

  @override
  void onInit() {
    super.onInit();
    FirestoreService.productsStream().listen((list) {
      products.assignAll(list);
      isLoading(false);
    });
  }

  Future<void> deleteProduct(String id) => FirestoreService.deleteProduct(id);

  void setSearchQuery(String q) => searchQuery.value = q;

  void setSort(SortField? field, SortDirection? direction) {
    sortStates.updateAll((key, value) => null);
    sortPriority.clear();
    if (field != null && direction != null) {
      sortStates[field] = direction;
      sortPriority.add(field);
    }
    sortStates.refresh();
  }

  bool get isSortAllSelected => sortPriority.isEmpty;

  void setCategoryFilter(Set<String> categories, int totalCategoryCount) {
    if (categories.length >= totalCategoryCount) {
      selectedCategories.clear();
    } else {
      selectedCategories
        ..clear()
        ..addAll(categories);
    }
  }

  bool get isAllCategoriesSelected => selectedCategories.isEmpty;

  int? get productIdMin {
    final ids = products.map((p) => int.tryParse(p.id)).whereType<int>();
    return ids.isEmpty ? null : ids.reduce((a, b) => a < b ? a : b);
  }

  int? get productIdMax {
    final ids = products.map((p) => int.tryParse(p.id)).whereType<int>();
    return ids.isEmpty ? null : ids.reduce((a, b) => a > b ? a : b);
  }

  void applyAdvancedFilters({
    RangeValues? priceRange,
    RangeValues? ratingRange,
    RangeValues? reviewCountRange,
    int? idStart,
    int? idEnd,
  }) {
    priceRangeFilter.value = priceRange;
    ratingRangeFilter.value = ratingRange;
    reviewCountRangeFilter.value = reviewCountRange;
    idRangeStart.value = idStart;
    idRangeEnd.value = idEnd;
  }

  bool get hasActiveFilters =>
      !isSortAllSelected ||
      !isAllCategoriesSelected ||
      priceRangeFilter.value != null ||
      ratingRangeFilter.value != null ||
      reviewCountRangeFilter.value != null ||
      (idRangeStart.value != null && idRangeEnd.value != null);

  List<AdminProduct> get filteredProducts {
    var list = products.toList();

    final q = searchQuery.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((p) {
        return p.id.toLowerCase().contains(q) ||
            p.title.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q);
      }).toList();
    }

    if (selectedCategories.isNotEmpty) {
      list = list
          .where((p) => selectedCategories.contains(p.category))
          .toList();
    }

    final pr = priceRangeFilter.value;
    if (pr != null) {
      list = list
          .where((p) => p.price >= pr.start && p.price <= pr.end)
          .toList();
    }

    final rr = ratingRangeFilter.value;
    if (rr != null) {
      list = list
          .where((p) => p.rating >= rr.start && p.rating <= rr.end)
          .toList();
    }

    final rc = reviewCountRangeFilter.value;
    if (rc != null) {
      list = list
          .where((p) => p.ratingCount >= rc.start && p.ratingCount <= rc.end)
          .toList();
    }

    final idStart = idRangeStart.value;
    final idEnd = idRangeEnd.value;
    if (idStart != null && idEnd != null) {
      list = list.where((p) {
        final id = int.tryParse(p.id);
        return id != null && id >= idStart && id <= idEnd;
      }).toList();
    }

    if (sortPriority.isNotEmpty) {
      final field = sortPriority.first;
      final dir = sortStates[field];
      if (dir != null) {
        list.sort((a, b) {
          int cmp;
          switch (field) {
            case SortField.id:
              cmp = a.id.compareTo(b.id);
              break;
            case SortField.price:
              cmp = a.price.compareTo(b.price);
              break;
            case SortField.rating:
              cmp = a.rating.compareTo(b.rating);
              break;
          }
          return dir == SortDirection.desc ? -cmp : cmp;
        });
      }
    }

    return list;
  }
}
