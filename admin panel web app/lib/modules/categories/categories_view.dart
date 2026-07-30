import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/app_colors.dart';
import 'categories_controller.dart';

class CategoriesView extends StatefulWidget {
  const CategoriesView({super.key});

  @override
  State<CategoriesView> createState() => _CategoriesViewState();
}

class _CategoriesViewState extends State<CategoriesView> {
  late final CategoriesController ctrl;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    ctrl = Get.isRegistered<CategoriesController>()
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
      child: SingleChildScrollView(
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
                    'Categories',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddDialog(ctrl),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Category'),
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
                'Results: ${ctrl.filteredCategories.length}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 12),

            Obx(() {
              if (ctrl.categories.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: Text(
                      'No categories yet',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                );
              }

              final filtered = ctrl.filteredCategories;

              if (filtered.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: Text(
                      'No results found',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                );
              }

              return Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                        ),
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            AppColors.background,
                          ),
                          dataRowMinHeight: 56,
                          dataRowMaxHeight: 56,
                          columns: const [
                            DataColumn(label: Text('Category')),
                            DataColumn(label: Text('Total Products')),
                            DataColumn(label: Text('Average Rating')),
                            DataColumn(
                              label: Text('Total Price (Expensive/Cheap)'),
                            ),
                            DataColumn(label: Text('')), // Edit
                            DataColumn(label: Text('')), // Delete
                          ],
                          rows: filtered
                              .map((c) => _row(context, ctrl, c))
                              .toList(),
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ],
        ),
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
          hintText: 'Search by category name',
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
      return Container(
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
      );
    });
  }

  void _showFilterDialog() {
    Get.dialog(_CategoryFilterDialog(ctrl: ctrl));
  }

  DataRow _row(
    BuildContext context,
    CategoriesController ctrl,
    CategoryAggregate c,
  ) {
    return DataRow(
      cells: [
        DataCell(
          Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        DataCell(Text('${c.count}')),
        DataCell(Text(c.avgRating.toStringAsFixed(1))),
        DataCell(Text('\$${c.sumPrice.toStringAsFixed(2)}')),
        DataCell(
          SizedBox(
            width: 40,
            child: IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              onPressed: () => _showEditDialog(ctrl, c),
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
              onPressed: () => _confirmDelete(context, ctrl, c),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(
    BuildContext context,
    CategoriesController ctrl,
    CategoryAggregate c,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Delete "${c.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              ctrl.deleteCategory(c.raw);
              Get.back();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(CategoriesController ctrl) {
    final nameController = TextEditingController();
    final iconController = TextEditingController();
    final errorText = ''.obs;

    Get.dialog(
      AlertDialog(
        title: const Text('Add Category'),
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
              final err = await ctrl.addCategory(combined);
              if (err != null) {
                errorText.value = err;
              } else {
                Get.back();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(CategoriesController ctrl, CategoryAggregate c) {
    final nameController = TextEditingController(text: c.name);
    final iconController = TextEditingController(text: c.icon);
    final errorText = ''.obs;
    final isSaving = false.obs;

    Get.dialog(
      AlertDialog(
        title: const Text('Edit Category'),
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
          Obx(
            () => ElevatedButton(
              onPressed: isSaving.value
                  ? null
                  : () async {
                      isSaving(true);
                      final err = await ctrl.updateCategory(
                        c,
                        nameController.text,
                        iconController.text,
                      );
                      isSaving(false);
                      if (err != null) {
                        errorText.value = err;
                      } else {
                        Get.back();
                      }
                    },
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}

//  Filter dialog
class _CategoryFilterDialog extends StatefulWidget {
  final CategoriesController ctrl;

  const _CategoryFilterDialog({required this.ctrl});

  @override
  State<_CategoryFilterDialog> createState() => _CategoryFilterDialogState();
}

class _CategoryFilterDialogState extends State<_CategoryFilterDialog> {
  CategorySortField? _sortField;
  CategorySortDirection? _sortDirection;

  late RangeValues _productsRange;
  late RangeValues _ratingRange;
  late RangeValues _priceRange;

  late double _priceMin;
  late double _priceMax;

  @override
  void initState() {
    super.initState();
    final ctrl = widget.ctrl;

    if (ctrl.sortPriority.isNotEmpty) {
      _sortField = ctrl.sortPriority.first;
      _sortDirection = ctrl.sortStates[_sortField];
    }

    _priceMin = ctrl.categoryPriceMin ?? 0;
    _priceMax = ctrl.categoryPriceMax ?? 1;
    if (_priceMax <= _priceMin) _priceMax = _priceMin + 1;

    _productsRange =
        ctrl.productsRangeFilter.value ??
        const RangeValues(
          CategoriesController.productsMin,
          CategoriesController.productsMax,
        );

    _ratingRange =
        ctrl.ratingRangeFilter.value ??
        const RangeValues(
          CategoriesController.ratingMin,
          CategoriesController.ratingMax,
        );

    _priceRange =
        ctrl.priceRangeFilter.value ?? RangeValues(_priceMin, _priceMax);
  }

  void _reset() {
    setState(() {
      _sortField = null;
      _sortDirection = null;
      _productsRange = const RangeValues(
        CategoriesController.productsMin,
        CategoriesController.productsMax,
      );
      _ratingRange = const RangeValues(
        CategoriesController.ratingMin,
        CategoriesController.ratingMax,
      );
      _priceRange = RangeValues(_priceMin, _priceMax);
    });
  }

  void _apply() {
    const fullProducts = RangeValues(
      CategoriesController.productsMin,
      CategoriesController.productsMax,
    );
    const fullRating = RangeValues(
      CategoriesController.ratingMin,
      CategoriesController.ratingMax,
    );
    final fullPrice = RangeValues(_priceMin, _priceMax);

    widget.ctrl.setSort(_sortField, _sortDirection);
    widget.ctrl.applyAdvancedFilters(
      productsRange: _productsRange == fullProducts ? null : _productsRange,
      ratingRange: _ratingRange == fullRating ? null : _ratingRange,
      priceRange: _priceRange == fullPrice ? null : _priceRange,
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
        constraints: BoxConstraints(maxHeight: screenHeight * 0.85),
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
                          Expanded(child: _sortSection()),
                          const SizedBox(width: 24),
                          Expanded(child: _rangeFiltersSection()),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sortSection(),
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

  //  Left column (narrow screen: top section): Sort By
  Widget _sortSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Sort By'),
        _sortRadioRow('All', null, null),
        _sortRadioRow(
          'Name (A to Z)',
          CategorySortField.name,
          CategorySortDirection.asc,
        ),
        _sortRadioRow(
          'Name (Z to A)',
          CategorySortField.name,
          CategorySortDirection.desc,
        ),
        _sortRadioRow(
          'Total Products (High to Low)',
          CategorySortField.products,
          CategorySortDirection.desc,
        ),
        _sortRadioRow(
          'Total Products (Low to High)',
          CategorySortField.products,
          CategorySortDirection.asc,
        ),
        _sortRadioRow(
          'Total Price (Expensive) (High to Low)',
          CategorySortField.price,
          CategorySortDirection.desc,
        ),
        _sortRadioRow(
          'Total Price (Cheap) (Low to High)',
          CategorySortField.price,
          CategorySortDirection.asc,
        ),
        _sortRadioRow(
          'Average Rating (High to Low)',
          CategorySortField.rating,
          CategorySortDirection.desc,
        ),
        _sortRadioRow(
          'Average Rating (Low to High)',
          CategorySortField.rating,
          CategorySortDirection.asc,
        ),
      ],
    );
  }

  //  Right column (narrow screen: bottom section): range sliders
  Widget _rangeFiltersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Total Products'),
        RangeSlider(
          values: _productsRange,
          min: CategoriesController.productsMin,
          max: CategoriesController.productsMax,
          divisions: 299,
          labels: RangeLabels(
            _productsRange.start.round().toString(),
            _productsRange.end.round().toString(),
          ),
          onChanged: (v) => setState(() => _productsRange = v),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_productsRange.start.round().toString()),
            Text(_productsRange.end.round().toString()),
          ],
        ),
        const SizedBox(height: 12),

        _sectionTitle('Average Rating'),
        RangeSlider(
          values: _ratingRange,
          min: CategoriesController.ratingMin,
          max: CategoriesController.ratingMax,
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

        _sectionTitle('Total Price (Expensive/Cheap)'),
        RangeSlider(
          values: _priceRange,
          min: _priceMin,
          max: _priceMax,
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

  Widget _sortRadioRow(
    String label,
    CategorySortField? field,
    CategorySortDirection? direction,
  ) {
    final selected = _sortField == field && _sortDirection == direction;
    return InkWell(
      onTap: () => setState(() {
        _sortField = field;
        _sortDirection = direction;
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
            Expanded(child: Text(label)),
          ],
        ),
      ),
    );
  }
}
