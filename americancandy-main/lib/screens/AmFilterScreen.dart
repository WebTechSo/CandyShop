import 'package:american_sweets/models/AmProduct.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:american_sweets/main.dart';
import 'package:american_sweets/models/AmCategory.dart';
import 'package:american_sweets/models/AmBrand.dart';
import 'package:american_sweets/models/AmAttribute.dart';
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/utils/AmConstant.dart';
import 'package:american_sweets/utils/AmExtension.dart';
import 'package:american_sweets/utils/AmStrings.dart';
import 'package:american_sweets/utils/AmWidget.dart';

class AmFilterScreen extends StatefulWidget {
  static String tag = '/AmFilterScreen';

  @override
  _AmFilterScreenState createState() => _AmFilterScreenState();
}

class _AmFilterScreenState extends State<AmFilterScreen> {
  List<AmCategory> categories = [];
  List<AmBrand> brands = [];
  AmAttributes? attributes;

  double minPrice = 10;
  double maxPrice = 200;
  RangeValues priceRange = RangeValues(10, 200);

  String selectedSort = '';
  int selectedVariantTab = 0; // 0 for Size, 1 for Flavor

  List<String> sortOptions = [
    'Feature',
    'New Arrivals',
    'Price High to Low',
    'Price Low to High'
  ];

  @override
  void initState() {
    super.initState();
    fetchFilterData();
  }

  Future<void> fetchFilterData() async {
    try {
      await Future.wait([
        loadCategories(),
        loadBrands(),
        loadAttributes(),
      ]);
    } catch (_) {}
  }

  Future<void> loadCategories() async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('Categories').get();
      List<AmCategory> fetchedCategories = querySnapshot.docs
          .map((doc) => AmCategory.fromQuerySnapshot(doc))
          .toList();
      if (mounted) {
        setState(() {
          for (final c in fetchedCategories) {
            c.isSelected = false;
          }
          categories = fetchedCategories;
        });
      }
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  Future<void> loadBrands() async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('Brands').get();
      List<AmBrand> fetchedBrands = querySnapshot.docs
          .map((doc) => AmBrand.fromQuerySnapshot(doc))
          .toList();
      if (mounted) {
        setState(() {
          for (final b in fetchedBrands) {
            b.isSelected = false;
          }
          brands = fetchedBrands;
        });
      }
    } catch (e) {
      print('Error loading brands: $e');
    }
  }

  Future<void> loadAttributes() async {
    try {
      final productsSnapshot =
          await FirebaseFirestore.instance.collection('Products').get();
      final products = productsSnapshot.docs
          .map((doc) => AmProductModel.fromQuerySnapshot(doc))
          .where((p) => p.status == null || p.status == 'active')
          .toList();

      final Set<String> uniqueSizes = {};
      final Set<String> uniqueFlavors = {};
      double minP = double.infinity;
      double maxP = double.negativeInfinity;

      for (var product in products) {
        if (product.variants?.size != null &&
            product.variants!.size!.isNotEmpty) {
          uniqueSizes.add(product.variants!.size!);
        }
        if (product.variants?.flavor != null &&
            product.variants!.flavor!.isNotEmpty) {
          uniqueFlavors.add(product.variants!.flavor!);
        }
        final p = product.price ?? 0.0;
        if (p < minP) minP = p;
        if (p > maxP) maxP = p;
      }
      if (minP == double.infinity) minP = 0.0;
      if (maxP == double.negativeInfinity) maxP = minP + 100.0;
      if (maxP <= minP) maxP = minP + 100.0;

      if (mounted) {
        setState(() {
          minPrice = minP;
          maxPrice = maxP;
          priceRange = RangeValues(minPrice, maxPrice);
          attributes = AmAttributes(
            size: uniqueSizes
                .map((s) => AmSize(name: s, slug: s.toLowerCase()))
                .toList(),
            flavor: uniqueFlavors
                .map((f) => AmFlavor(name: f, slug: f.toLowerCase()))
                .toList(),
          );
        });
      }
    } catch (e) {
      print('Error loading attributes: $e');
    }
  }

  void applyFilters() {
    // Implement your filter logic here
    Map<String, dynamic> filters = {
      'categories': categories.where((cat) => cat.isSelected == true).toList(),
      'brands': brands.where((brand) => brand.isSelected == true).toList(),
      'priceRange': priceRange,
      'sort': selectedSort,
      'sizes':
          attributes?.size?.where((size) => size.isSelected).toList() ?? [],
      'flavors':
          attributes?.flavor?.where((flavor) => flavor.isSelected).toList() ??
              [],
    };

    print('Applied Filters: $filters');
    Navigator.pop(context, filters);
  }

  void clearFilters() {
    setState(() {
      // Clear categories
      for (var category in categories) {
        category.isSelected = false;
      }

      // Clear brands
      for (var brand in brands) {
        brand.isSelected = false;
      }

      // Clear attributes
      for (var size in attributes?.size ?? []) {
        size.isSelected = false;
      }
      for (var flavor in attributes?.flavor ?? []) {
        flavor.isSelected = false;
      }

      // Reset price range
      priceRange = RangeValues(minPrice, maxPrice);
      selectedSort = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Filter Products', style: boldTextStyle(size: 22)),
        iconTheme: IconThemeData(
            color: appStore.isDarkModeOn ? white : sh_textColorPrimary),
        actions: [
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Categories Section
            _buildSectionTitle('Categories'),
            SizedBox(height: 12),
            _buildCategoriesList(),
            SizedBox(height: 24),

            // Brands Section
            _buildSectionTitle('Brands'),
            SizedBox(height: 12),
            _buildBrandsList(),
            SizedBox(height: 24),

            // Variants Section
            _buildSectionTitle('Variants'),
            SizedBox(height: 12),
            _buildVariantsSection(),
            SizedBox(height: 24),

            // Price Range Section
            _buildSectionTitle('Price Range'),
            SizedBox(height: 12),
            _buildPriceRangeSection(),
            SizedBox(height: 24),

            // Sort Options Section
            _buildSectionTitle('Sort By'),
            SizedBox(height: 12),
            _buildSortOptions(),
            SizedBox(height: 32),

            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: boldTextStyle(
          size: 18, color: appStore.isDarkModeOn ? white : sh_textColorPrimary),
    );
  }

  Widget _buildCategoriesList() {
    return Container(
      height: 116,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return Container(
            width: 80,
            margin: EdgeInsets.only(right: 12),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: category.isSelected == true
                        ? sh_colorPrimary
                        : sh_view_color,
                    border: Border.all(
                      color: category.isSelected == true
                          ? sh_colorPrimary
                          : sh_view_color,
                      width: 2,
                    ),
                  ),
                  child: category.image != null && category.image!.isNotEmpty
                      ? ClipOval(
                          child: category.image!.startsWith('http')
                              ? CachedNetworkImage(
                                  imageUrl: category.image!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator(),
                                  errorWidget: (context, url, error) => Icon(
                                      Icons.category,
                                      color: category.isSelected == true
                                          ? white
                                          : sh_textColorSecondary),
                                )
                              : Image.asset(
                                  category.image!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(
                                    Icons.category,
                                    color: category.isSelected == true
                                        ? white
                                        : sh_textColorSecondary,
                                  ),
                                ),
                        )
                      : Icon(Icons.category,
                          color: category.isSelected == true
                              ? white
                              : sh_textColorSecondary),
                ),
                SizedBox(height: 8),
                Text(
                  category.name ?? '',
                  style: primaryTextStyle(
                    size: 11,
                    color: appStore.isDarkModeOn ? white : sh_textColorPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ).onTap(() {
              setState(() {
                category.isSelected = !(category.isSelected == true);
              });
            }),
          );
        },
      ),
    );
  }

  Widget _buildBrandsList() {
    return Container(
      height: 116,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: brands.length,
        itemBuilder: (context, index) {
          final brand = brands[index];
          return Container(
            width: 80,
            margin: EdgeInsets.only(right: 12),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: brand.isSelected == true
                        ? sh_colorPrimary
                        : sh_view_color,
                    border: Border.all(
                      color: brand.isSelected == true
                          ? sh_colorPrimary
                          : sh_view_color,
                      width: 2,
                    ),
                  ),
                  child: brand.image != null && brand.image!.isNotEmpty
                      ? ClipOval(
                          child: brand.image!.startsWith('http')
                              ? CachedNetworkImage(
                                  imageUrl: brand.image!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator(),
                                  errorWidget: (context, url, error) => Icon(
                                    Icons.business,
                                    color: brand.isSelected == true
                                        ? white
                                        : sh_textColorSecondary,
                                  ),
                                )
                              : Image.asset(
                                  brand.image!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(
                                    Icons.business,
                                    color: brand.isSelected == true
                                        ? white
                                        : sh_textColorSecondary,
                                  ),
                                ),
                        )
                      : Icon(Icons.business,
                          color: brand.isSelected == true
                              ? white
                              : sh_textColorSecondary),
                ),
                SizedBox(height: 8),
                Text(
                  brand.name ?? '',
                  style: primaryTextStyle(
                    size: 11,
                    color: appStore.isDarkModeOn ? white : sh_textColorPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ).onTap(() {
              setState(() {
                brand.isSelected = !(brand.isSelected == true);
              });
            }),
          );
        },
      ),
    );
  }

  Widget _buildVariantsSection() {
    return Column(
      children: [
        // Tabs for Size and Flavor
        Container(
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: selectedVariantTab == 0
                        ? sh_colorPrimary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        selectedVariantTab = 0;
                      });
                    },
                    child: Text(
                      'Size',
                      style: primaryTextStyle(
                        color: selectedVariantTab == 0
                            ? white
                            : appStore.isDarkModeOn
                                ? white
                                : sh_textColorPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: selectedVariantTab == 1
                        ? sh_colorPrimary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        selectedVariantTab = 1;
                      });
                    },
                    child: Text(
                      'Flavor',
                      style: primaryTextStyle(
                        color: selectedVariantTab == 1
                            ? white
                            : appStore.isDarkModeOn
                                ? white
                                : sh_textColorPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),

        // Variant List based on selected tab
        if (selectedVariantTab == 0) _buildSizeList() else _buildFlavorList(),
      ],
    );
  }

  Widget _buildSizeList() {
    final sizes = attributes?.size ?? [];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: sizes.map((size) {
        return FilterChip(
          label: Text(
            size.name ?? '',
            style: primaryTextStyle(
              color: size.isSelected
                  ? white
                  : appStore.isDarkModeOn
                      ? white
                      : sh_textColorPrimary,
            ),
          ),
          selected: size.isSelected,
          onSelected: (selected) {
            setState(() {
              size.isSelected = selected;
            });
          },
          selectedColor: sh_colorPrimary,
          checkmarkColor: white,
        );
      }).toList(),
    );
  }

  Widget _buildFlavorList() {
    final flavors = attributes?.flavor ?? [];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: flavors.map((flavor) {
        return FilterChip(
          label: Text(
            flavor.name ?? '',
            style: primaryTextStyle(
              color: flavor.isSelected
                  ? white
                  : appStore.isDarkModeOn
                      ? white
                      : sh_textColorPrimary,
            ),
          ),
          selected: flavor.isSelected,
          onSelected: (selected) {
            setState(() {
              flavor.isSelected = selected;
            });
          },
          selectedColor: sh_colorPrimary,
          checkmarkColor: white,
        );
      }).toList(),
    );
  }

  Widget _buildPriceRangeSection() {
    return Column(
      children: [
        RangeSlider(
          values: priceRange,
          min: minPrice,
          max: maxPrice,
          labels: RangeLabels(
            '\$${priceRange.start.round()}',
            '\$${priceRange.end.round()}',
          ),
          onChanged: (values) {
            setState(() {
              priceRange = values;
            });
          },
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('\$${priceRange.start.round()}', style: primaryTextStyle()),
            Text('\$${priceRange.end.round()}', style: primaryTextStyle()),
          ],
        ),
      ],
    );
  }

  Widget _buildSortOptions() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: sortOptions.map((option) {
        return FilterChip(
          label: Text(option),
          selected: selectedSort == option,
          onSelected: (selected) {
            setState(() {
              selectedSort = selected ? option : '';
            });
          },
          selectedColor: sh_colorPrimary,
          checkmarkColor: white,
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: clearFilters,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: sh_colorPrimary),
            ),
            child: Text(
              'Clear',
              style: primaryTextStyle(color: sh_colorPrimary),
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: applyFilters,
            style: ElevatedButton.styleFrom(
              backgroundColor: sh_colorPrimary,
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              'Apply Filter',
              style: primaryTextStyle(color: white),
            ),
          ),
        ),
      ],
    );
  }
}
