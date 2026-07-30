import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../app/app_colors.dart';
import '../../data/models/admin_product_model.dart';
import 'product_form_view.dart';
import 'products_controller.dart';
import '../categories/categories_controller.dart';

class ProductsListView extends StatefulWidget {
  const ProductsListView({super.key});

  @override
  State<ProductsListView> createState() => _ProductsListViewState();
}

class _ProductsListViewState extends State<ProductsListView> {
  late final ProductsController ctrl;
  late final CategoriesController catCtrl;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    ctrl = Get.isRegistered<ProductsController>()
        ? Get.find<ProductsController>()
        : Get.put(ProductsController());
    catCtrl = Get.isRegistered<CategoriesController>()
        ? Get.find<CategoriesController>()
        : Get.put(CategoriesController());
    _searchController.text = ctrl.searchQuery.value;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'Products',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),

                ElevatedButton.icon(
                  onPressed: () => Get.to(() => const ProductFormView()),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Product'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          //  Search bar + Filter button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildSearchBar()),
              const SizedBox(width: 12),
              _buildFilterButton(),
            ],
          ),
          const SizedBox(height: 14),

          //  Results count
          Obx(
            () => Text(
              'Results: ${ctrl.filteredProducts.length}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: Obx(() {
              if (ctrl.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (ctrl.products.isEmpty) {
                return const Center(
                  child: Text(
                    'No products yet',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }

              final filtered = ctrl.filteredProducts;

              if (filtered.isEmpty) {
                return const Center(
                  child: Text(
                    'No results found',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }

              return SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          AppColors.background,
                        ),
                        dataRowMinHeight: 56,
                        dataRowMaxHeight: 56,
                        columns: const [
                          DataColumn(label: Text('')),
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Title')),
                          DataColumn(label: Text('Category')),
                          DataColumn(label: Text('Price')),
                          DataColumn(label: Text('Rating')),
                          DataColumn(label: Text('')), // Edit
                          DataColumn(label: Text('')), // Delete
                        ],
                        rows: filtered
                            .map((p) => _row(context, ctrl, p))
                            .toList(),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  //  Search bar
  Widget _buildSearchBar() {
    return SizedBox(
      width: double.infinity,
      child: TextField(
        controller: _searchController,
        onChanged: (v) => ctrl.setSearchQuery(v),
        decoration: InputDecoration(
          hintText: 'Search by ID, Title or Category',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: Obx(
            () => ctrl.searchQuery.value.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      ctrl.setSearchQuery('');
                    },
                  ),
          ),
        ),
      ),
    );
  }

  //  Filter button (opens the filter dialog)
  Widget _buildFilterButton() {
    return Obx(() {
      final active = ctrl.hasActiveFilters;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: active ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: active ? AppColors.primary : AppColors.border,
                width: 1.2,
              ),
            ),
            child: IconButton(
              icon: Icon(
                Icons.tune,
                color: active ? Colors.white : AppColors.textPrimary,
              ),
              onPressed: _showFilterDialog,
            ),
          ),
        ],
      );
    });
  }

  void _showFilterDialog() {
    Get.dialog(
      _ProductFilterDialog(ctrl: ctrl, categories: catCtrl.categories.toList()),
    );
  }

  DataRow _row(BuildContext context, ProductsController ctrl, AdminProduct p) {
    return DataRow(
      cells: [
        DataCell(
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: p.image.isEmpty
                ? Container(width: 40, height: 40, color: AppColors.background)
                : Image.network(
                    p.image,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
          ),
        ),
        DataCell(Text(p.id)),
        DataCell(
          SizedBox(
            width: 220,
            child: Text(p.title, overflow: TextOverflow.ellipsis),
          ),
        ),
        DataCell(Text(CategoriesController.splitNameIcon(p.category).$1)),
        DataCell(Text('\$${p.price.toStringAsFixed(2)}')),
        DataCell(Text('${p.rating.toStringAsFixed(1)} (${p.ratingCount})')),
        DataCell(
          SizedBox(
            width: 40,
            child: IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              onPressed: () => Get.to(() => ProductFormView(existing: p)),
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 40,
            child: IconButton(
              icon: const Icon(
                Icons.delete_outline,
                size: 18,
                color: AppColors.error,
              ),
              onPressed: () => _confirmDelete(context, ctrl, p),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(
    BuildContext context,
    ProductsController ctrl,
    AdminProduct p,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Product'),
        content: Text(
          'Delete "${p.title}" (ID: ${p.id})? This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              ctrl.deleteProduct(p.id);
              Get.back();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

//  Filter dialog
class _ProductFilterDialog extends StatefulWidget {
  final ProductsController ctrl;
  final List<String> categories; // raw category strings, e.g. "Bags-bag"

  const _ProductFilterDialog({required this.ctrl, required this.categories});

  @override
  State<_ProductFilterDialog> createState() => _ProductFilterDialogState();
}

class _ProductFilterDialogState extends State<_ProductFilterDialog> {
  SortField? _sortField;
  SortDirection? _sortDirection;
  late Set<String> _selectedCategories;
  late RangeValues _priceRange;
  late RangeValues _ratingRange;
  late RangeValues _reviewCountRange;
  final _idStartController = TextEditingController();
  final _idEndController = TextEditingController();
  String? _idError;

  @override
  void initState() {
    super.initState();
    final ctrl = widget.ctrl;

    if (ctrl.sortPriority.isNotEmpty) {
      _sortField = ctrl.sortPriority.first;
      _sortDirection = ctrl.sortStates[_sortField];
    }

    _selectedCategories = ctrl.selectedCategories.isEmpty
        ? widget.categories.toSet()
        : ctrl.selectedCategories.toSet();

    _priceRange =
        ctrl.priceRangeFilter.value ??
        const RangeValues(
          ProductsController.priceMin,
          ProductsController.priceMax,
        );

    _ratingRange =
        ctrl.ratingRangeFilter.value ??
        const RangeValues(
          ProductsController.ratingMin,
          ProductsController.ratingMax,
        );

    _reviewCountRange =
        ctrl.reviewCountRangeFilter.value ??
        const RangeValues(
          ProductsController.reviewCountMin,
          ProductsController.reviewCountMax,
        );

    if (ctrl.idRangeStart.value != null) {
      _idStartController.text = ctrl.idRangeStart.value.toString();
    }
    if (ctrl.idRangeEnd.value != null) {
      _idEndController.text = ctrl.idRangeEnd.value.toString();
    }
  }

  @override
  void dispose() {
    _idStartController.dispose();
    _idEndController.dispose();
    super.dispose();
  }

  bool get _isAllCategoriesSelected =>
      _selectedCategories.length == widget.categories.length;

  void _toggleAllCategories() {
    setState(() {
      if (_isAllCategoriesSelected) {
        _selectedCategories.clear();
      } else {
        _selectedCategories = widget.categories.toSet();
      }
    });
  }

  void _toggleCategory(String cat) {
    setState(() {
      if (_selectedCategories.contains(cat)) {
        _selectedCategories.remove(cat);
      } else {
        _selectedCategories.add(cat);
      }
    });
  }

  void _reset() {
    setState(() {
      _sortField = null;
      _sortDirection = null;
      _selectedCategories = widget.categories.toSet();
      _priceRange = const RangeValues(
        ProductsController.priceMin,
        ProductsController.priceMax,
      );
      _ratingRange = const RangeValues(
        ProductsController.ratingMin,
        ProductsController.ratingMax,
      );
      _reviewCountRange = const RangeValues(
        ProductsController.reviewCountMin,
        ProductsController.reviewCountMax,
      );
      _idStartController.clear();
      _idEndController.clear();
      _idError = null;
    });
  }

  void _apply() {
    final startText = _idStartController.text.trim();
    final endText = _idEndController.text.trim();
    int? idStart = startText.isEmpty ? null : int.tryParse(startText);
    int? idEnd = endText.isEmpty ? null : int.tryParse(endText);

    if ((idStart != null) != (idEnd != null)) {
      idStart = null;
      idEnd = null;
    }

    if (idStart != null && idEnd != null && idStart >= idEnd) {
      setState(() => _idError = 'Start must be less than end');
      return;
    }

    const fullPrice = RangeValues(
      ProductsController.priceMin,
      ProductsController.priceMax,
    );
    const fullRating = RangeValues(
      ProductsController.ratingMin,
      ProductsController.ratingMax,
    );
    const fullReviewCount = RangeValues(
      ProductsController.reviewCountMin,
      ProductsController.reviewCountMax,
    );

    widget.ctrl.setSort(_sortField, _sortDirection);
    widget.ctrl.setCategoryFilter(
      _selectedCategories,
      widget.categories.length,
    );
    widget.ctrl.applyAdvancedFilters(
      priceRange: _priceRange == fullPrice ? null : _priceRange,
      ratingRange: _ratingRange == fullRating ? null : _ratingRange,
      reviewCountRange: _reviewCountRange == fullReviewCount
          ? null
          : _reviewCountRange,
      idStart: idStart,
      idEnd: idEnd,
    );

    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isWide = screenWidth >= 700;

    final dialogWidth = isWide
        ? (screenWidth * 0.75).clamp(700.0, 920.0)
        : (screenWidth * 0.92).clamp(280.0, 480.0);

    return Dialog(
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(maxHeight: screenHeight * 0.92),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Filters',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            Flexible(
              child: SingleChildScrollView(
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _sortAndCategorySection()),
                          const SizedBox(width: 24),
                          Expanded(child: _rangeFiltersSection()),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sortAndCategorySection(),
                          const SizedBox(height: 16),
                          _rangeFiltersSection(),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _reset,
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _apply,
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  //  Left column (narrow screen: top section): Sort By + Category
  Widget _sortAndCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Sort By'),
        _sortRadioRow(
          'ID (Ascending to Descending)',
          SortField.id,
          SortDirection.asc,
        ),
        _sortRadioRow(
          'ID (Descending to Ascending)',
          SortField.id,
          SortDirection.desc,
        ),
        _sortRadioRow(
          'Price (High to Low)',
          SortField.price,
          SortDirection.desc,
        ),
        _sortRadioRow(
          'Price (Low to High)',
          SortField.price,
          SortDirection.asc,
        ),
        _sortRadioRow(
          'Rating (High to Low)',
          SortField.rating,
          SortDirection.desc,
        ),
        _sortRadioRow(
          'Rating (Low to High)',
          SortField.rating,
          SortDirection.asc,
        ),
        const SizedBox(height: 16),

        _sectionTitle('Category'),
        _checkboxRow('All', _isAllCategoriesSelected, _toggleAllCategories),
        ...widget.categories.map((cat) {
          final name = CategoriesController.splitNameIcon(cat).$1;
          return _checkboxRow(
            name,
            _selectedCategories.contains(cat),
            () => _toggleCategory(cat),
          );
        }),
      ],
    );
  }

  //  Right column (narrow screen: bottom section): Price/Rating/Review/ID range
  Widget _rangeFiltersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Price Range'),
        RangeSlider(
          values: _priceRange,
          min: ProductsController.priceMin,
          max: ProductsController.priceMax,
          divisions: 200,
          labels: RangeLabels(
            '\$${_priceRange.start.round()}',
            '\$${_priceRange.end.round()}',
          ),
          onChanged: (v) => setState(() => _priceRange = v),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('\$${_priceRange.start.round()}'),
            Text('\$${_priceRange.end.round()}'),
          ],
        ),
        const SizedBox(height: 12),

        _sectionTitle('Rating Range'),
        RangeSlider(
          values: _ratingRange,
          min: ProductsController.ratingMin,
          max: ProductsController.ratingMax,
          divisions: 40,
          labels: RangeLabels(
            _ratingRange.start.toStringAsFixed(2),
            _ratingRange.end.toStringAsFixed(1),
          ),
          onChanged: (v) => setState(() => _ratingRange = v),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_ratingRange.start.toStringAsFixed(2)),
            Text(_ratingRange.end.toStringAsFixed(1)),
          ],
        ),
        const SizedBox(height: 12),

        _sectionTitle('Review Count'),
        RangeSlider(
          values: _reviewCountRange,
          min: ProductsController.reviewCountMin,
          max: ProductsController.reviewCountMax,
          divisions: 299,
          labels: RangeLabels(
            _reviewCountRange.start.round().toString(),
            _reviewCountRange.end.round().toString(),
          ),
          onChanged: (v) => setState(() => _reviewCountRange = v),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_reviewCountRange.start.round().toString()),
            Text(_reviewCountRange.end.round().toString()),
          ],
        ),
        const SizedBox(height: 12),

        _sectionTitle('ID Range'),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _idStartController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText:
                      widget.ctrl.productIdMin?.toString() ?? 'e.g. 12332',
                ),
                onChanged: (_) {
                  if (_idError != null) {
                    setState(() => _idError = null);
                  }
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('→'),
            ),
            Expanded(
              child: TextField(
                controller: _idEndController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText:
                      widget.ctrl.productIdMax?.toString() ?? 'e.g. 69880',
                ),
                onChanged: (_) {
                  if (_idError != null) {
                    setState(() => _idError = null);
                  }
                },
              ),
            ),
          ],
        ),
        if (_idError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _idError!,
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _sortRadioRow(String label, SortField field, SortDirection direction) {
    final selected = _sortField == field && _sortDirection == direction;
    return InkWell(
      onTap: () => setState(() {
        if (selected) {
          _sortField = null;
          _sortDirection = null;
        } else {
          _sortField = field;
          _sortDirection = direction;
        }
      }),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 20,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Text(label),
          ],
        ),
      ),
    );
  }

  Widget _checkboxRow(String label, bool checked, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              checked ? Icons.check_box : Icons.check_box_outline_blank,
              size: 20,
              color: checked ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Text(label),
          ],
        ),
      ),
    );
  }
}
