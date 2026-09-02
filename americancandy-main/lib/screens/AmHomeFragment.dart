import 'package:american_sweets/models/AmAttribute.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:american_sweets/models/AmCategory.dart';
import 'package:american_sweets/models/AmProduct.dart';
import 'package:american_sweets/models/AmBrand.dart';
import 'package:american_sweets/screens/AmViewAllProducts.dart';
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/screens/AmFilterScreen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:american_sweets/utils/AmProductCard.dart';
import 'package:american_sweets/main.dart';

class AmHomeFragment extends StatefulWidget {
  static String tag = '/AmHomeFragment';

  const AmHomeFragment({Key? key}) : super(key: key);

  @override
  AmHomeFragmentState createState() => AmHomeFragmentState();
}

class AmHomeFragmentState extends State<AmHomeFragment> {
  List<String> banners = [];
  List<AmProductModel> newestProducts = [];
  List<AmProductModel> featuredProducts = [];
  List<AmProductModel> searchResults = [];
  TextEditingController searchController = TextEditingController();
  bool isSearching = false;
  var position = 0;
  var colors = [sh_cat_1, sh_cat_2, sh_cat_3, sh_cat_4, sh_cat_5];

  // Filter dropdown states
  bool showPriceDropdown = false;
  bool showCategoryDropdown = false;
  bool showCountryDropdown = false;
  bool showBrandDropdown = false;

  // Selected values
  String selectedPriceRange = 'Prices';
  String selectedCountry = 'Countries';
  Map<String, dynamic>? advancedFilters;

  // Price Filter
  double minPrice = 0.0;
  double maxPrice = 1000.0;
  RangeValues currentRangeValues = RangeValues(0, 1000);

  // Product tabs
  int selectedProductTab = 0; // 0 for Newest Arrivals, 1 for Featured

  List<AmProductModel> allProducts = [];
  List<AmProductModel> countryFilteredProducts = [];
  List<String> countries = [];
  bool isLoading = true;
  bool includeVat = getBoolAsync('include_vat', defaultValue: true);

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  fetchData() async {
    // Load Firestore products
    List<AmProductModel> firestoreProducts = [];
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('Products').get();
      firestoreProducts = querySnapshot.docs
          .map((doc) => AmProductModel.fromQuerySnapshot(doc))
          .where((p) => p.status == 'active' || p.status == null)
          .toList()
          ..sort((a, b) =>
              (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    } catch (e) {
      print('Error loading Firestore products: $e');
    }

    // Load Local JSON products (legacy support)
    // List<AmProductModel> jsonProducts = await loadProducts();

    setState(() {
      isLoading = false;
      allProducts = [...firestoreProducts];

      // Calculate Min/Max Price
      if (allProducts.isNotEmpty) {
        double minP = double.infinity;
        double maxP = double.negativeInfinity;
        String maxPriceName = "";
        for (var p in allProducts) {
          double price = p.price ?? 0.0;
          if (price < minP) minP = price;
          if (price > maxP) {
            maxP = price;
            maxPriceName = p.name ?? "Unknown";
          }
        }
        print("Max Price Product: $maxPriceName, Price: $maxP");
        if (minP == double.infinity) minP = 0.0;
        if (maxP == double.negativeInfinity) maxP = 100.0;

        // Ensure some range
        if (maxP <= minP) maxP = minP + 100.0;

        minPrice = minP;
        maxPrice = maxP;
        currentRangeValues = RangeValues(minPrice, maxPrice);
      }

      Set<String> uniqueCountries = {};
      for (var p in allProducts) {
        if (p.variants?.country != null && p.variants!.country!.isNotEmpty) {
          uniqueCountries.add(p.variants!.country!);
        }
      }
      countries = uniqueCountries.toList();
      countries.sort();

      _applyFiltersInternal();
    });
  }

  void _applyFiltersInternal() {
    List<AmProductModel> filtered = allProducts;

    // Advanced Filters from AmFilterScreen
    if (advancedFilters != null) {
      // 1. Categories
      List<AmCategory> cats = advancedFilters!['categories'] ?? [];
      if (cats.isNotEmpty) {
        List<int> catIds =
            cats.where((c) => c.id != null).map((c) => c.id!).toList();
        List<String> catNames = cats
            .where((c) => c.name != null)
            .map((c) => c.name!.toLowerCase().trim())
            .toList();

        filtered = filtered.where((p) {
          bool idMatch = p.category != null && catIds.contains(p.category);
          bool nameMatch = p.categoryName != null &&
              catNames.contains(p.categoryName!.toLowerCase().trim());
          return idMatch || nameMatch;
        }).toList();
      }

      // 2. Brands
      List<AmBrand> brands = advancedFilters!['brands'] ?? [];
      if (brands.isNotEmpty) {
        final brandNames = brands
            .where((b) => (b.name ?? '').trim().isNotEmpty)
            .map((b) => b.name!.trim().toLowerCase())
            .toSet();
        filtered = filtered.where((p) {
          final bn = (p.brand ?? '').trim().toLowerCase();
          return bn.isNotEmpty && brandNames.contains(bn);
        }).toList();
      }

      // 3. Price Range (Override local price range if set)
      if (advancedFilters!['priceRange'] != null) {
        RangeValues range = advancedFilters!['priceRange'];
        filtered = filtered.where((p) {
          double price = p.price ?? 0.0;
          return price >= range.start && price <= range.end;
        }).toList();
        // Update local range visual
        currentRangeValues = range;
        minPrice = range.start;
        maxPrice = range.end;
      } else {
        // Use local price range if not overridden
        filtered = filtered.where((p) {
          double price = p.price ?? 0.0;
          return price >= currentRangeValues.start &&
              price <= currentRangeValues.end;
        }).toList();
      }

      // 4. Sizes
      List<AmSize> sizes = advancedFilters!['sizes'] ?? [];
      if (sizes.isNotEmpty) {
        final sizeNames = sizes
            .where((s) => (s.name ?? '').trim().isNotEmpty)
            .map((s) => s.name!.trim().toLowerCase())
            .toSet();
        filtered = filtered.where((p) {
          final sv = (p.variants?.size ?? '').trim().toLowerCase();
          return sv.isNotEmpty && sizeNames.contains(sv);
        }).toList();
      }

      // 5. Flavors
      List<AmFlavor> flavors = advancedFilters!['flavors'] ?? [];
      if (flavors.isNotEmpty) {
        final flavorNames = flavors
            .where((f) => (f.name ?? '').trim().isNotEmpty)
            .map((f) => f.name!.trim().toLowerCase())
            .toSet();
        filtered = filtered.where((p) {
          final fv = (p.variants?.flavor ?? '').trim().toLowerCase();
          return fv.isNotEmpty && flavorNames.contains(fv);
        }).toList();
      }

      // 6. Sort
      String sort = advancedFilters!['sort'] ?? '';
      if (sort == 'Price High to Low') {
        filtered.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
      } else if (sort == 'Price Low to High') {
        filtered.sort((a, b) => (a.price ?? 0).compareTo(b.price ?? 0));
      } else if (sort == 'New Arrivals') {
        filtered.sort((a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      }
    } else {
      // Basic Filters (Dropdowns)

      if (selectedCountry != 'Countries') {
        filtered = filtered
            .where((p) => p.variants?.country == selectedCountry)
            .toList();
      }

      // Price Filter
      filtered = filtered.where((p) {
        double price = p.price ?? 0.0;
        return price >= currentRangeValues.start &&
            price <= currentRangeValues.end;
      }).toList();
    }

    countryFilteredProducts = filtered;

    newestProducts.clear();
    featuredProducts.clear();

    // Logic for Newest Arrivals: last added 10 products (DESC by createdAt)
    final newest = filtered.toList()
      ..sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    newestProducts.addAll(newest.take(10));

    final featured = filtered.where((p) => p.featured == true).toList()
      ..sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    featuredProducts.addAll(featured);

    if (isSearching) {
      performSearch(searchController.text);
    }
  }

  void performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        isSearching = false;
        searchResults.clear();
      });
      return;
    }

    setState(() {
      isSearching = true;
      searchResults = countryFilteredProducts
          .where((product) =>
              product.name!.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void openFilterScreen() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => AmFilterScreen()),
    );
    if (!mounted) return;
    if (result is Map<String, dynamic>) {
      applyFilters(result);
    }
  }

  void applyFilters(Map<String, dynamic> filters) {
    print('Applying filters: $filters');
    setState(() {
      advancedFilters = filters;
      _applyFiltersInternal();
    });
  }

  void toggleDropdown(String type) {
    setState(() {
      showPriceDropdown = type == 'price' ? !showPriceDropdown : false;
      showCategoryDropdown = type == 'category' ? !showCategoryDropdown : false;
      showCountryDropdown = type == 'country' ? !showCountryDropdown : false;
      showBrandDropdown = type == 'brand' ? !showBrandDropdown : false;
    });
  }

  void selectPriceRange(String range) {
    setState(() {
      selectedPriceRange = range;
      showPriceDropdown = false;
    });
  }

  void selectCountry(String country) {
    setState(() {
      if (selectedCountry == country) {
        selectedCountry = 'Countries';
      } else {
        selectedCountry = country;
      }
      showCountryDropdown = false;
      _applyFiltersInternal();
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    // width not required here

    return SafeArea(
      child: Scaffold(
        body: !isLoading
            ? SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.only(bottom: 30),
                  child: Column(
                    children: <Widget>[
                      // Search Bar and Filter Button Section
                      Container(
                        padding: EdgeInsets.all(16),
                        color: context.cardColor,
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: context.scaffoldBackgroundColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: sh_view_color, width: 1),
                                ),
                                child: TextFormField(
                                  controller: searchController,
                                  onChanged: performSearch,
                                  decoration: InputDecoration(
                                    hintText: "Search products...",
                                    hintStyle: secondaryTextStyle(),
                                    border: InputBorder.none,
                                    prefixIcon: Icon(Icons.search,
                                        color: sh_textColorSecondary),
                                    suffixIcon: searchController.text.isNotEmpty
                                        ? IconButton(
                                            icon: Icon(Icons.clear,
                                                color: sh_textColorSecondary),
                                            onPressed: () {
                                              searchController.clear();
                                              performSearch('');
                                            },
                                          )
                                        : null,
                                    contentPadding: EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 16),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: sh_colorPrimary,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        sh_colorPrimary.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: Icon(Icons.filter_list,
                                    color: white, size: 24),
                                onPressed: openFilterScreen,
                                tooltip: 'Filter Products',
                              ),
                            ),

                          ],
                        ),
                      ),

                      // Show search results or normal content
                      if (isSearching) ...[
                        if (searchResults.isEmpty)
                          Container(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Icon(Icons.search_off,
                                    size: 60, color: sh_textColorSecondary),
                                SizedBox(height: 16),
                                Text("No products found",
                                    style: boldTextStyle()),
                                SizedBox(height: 8),
                                Text("Try different keywords or adjust filters",
                                    style: secondaryTextStyle()),
                                SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: openFilterScreen,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: sh_colorPrimary,
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 12),
                                  ),
                                  child: Text("Adjust Filters",
                                      style: primaryTextStyle(color: white)),
                                ),
                              ],
                            ),
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                        "Search Results (${searchResults.length})",
                                        style: boldTextStyle(size: 18)),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: sh_colorPrimary,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: IconButton(
                                        icon: Icon(Icons.filter_list,
                                            color: white, size: 20),
                                        onPressed: openFilterScreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _buildProductGrid(searchResults),
                              SizedBox(height: 30),
                            ],
                          ),
                      ] else ...[
                        // Product Tabs Section
                        Container(
                          margin:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: context.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: sh_view_color, width: 1),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildProductTab('Newest Arrivals', 0),
                              ),
                              Expanded(
                                child: _buildProductTab('Featured Products', 1),
                              ),
                            ],
                          ),
                        ),

                        // Products Grid based on selected tab
                        if ((selectedProductTab == 0
                                ? newestProducts
                                : featuredProducts)
                            .isEmpty)
                          Container(
                            padding: EdgeInsets.all(40),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.filter_list_off,
                                      size: 60, color: sh_textColorSecondary),
                                  SizedBox(height: 16),
                                  Text(
                                      selectedProductTab == 0
                                          ? "No products found"
                                          : "No featured products found",
                                      style: boldTextStyle(size: 18)),
                                  SizedBox(height: 8),
                                  Text(
                                      selectedProductTab == 0
                                          ? "Try clearing filters or check back later"
                                          : "Mark products as Featured = Yes to show them here",
                                      style: secondaryTextStyle(),
                                      textAlign: TextAlign.center),
                                  SizedBox(height: 24),
                                  OutlinedButton(
                                    onPressed: () {
                                      setState(() {
                                        advancedFilters = null;
                                        selectedCountry = 'Countries';
                                        selectedPriceRange = 'Prices';
                                        currentRangeValues =
                                            RangeValues(minPrice, maxPrice);
                                        showPriceDropdown = false;
                                        showCategoryDropdown = false;
                                        showCountryDropdown = false;
                                        showBrandDropdown = false;
                                        isSearching = false;
                                        searchController.clear();
                                        searchResults.clear();
                                        _applyFiltersInternal();
                                      });
                                    },
                                    child: Text("Clear All Filters"),
                                  )
                                ],
                              ),
                            ),
                          )
                        else
                          _buildProductGrid(selectedProductTab == 0
                              ? newestProducts
                              : featuredProducts),
                        SizedBox(height: 60),
                      ],
                    ],
                  ),
                ),
              )
            : _HomeSkeletonLoader(),
      ),
    );
  }

  Widget _buildProductTab(String title, int tabIndex) {
    return Container(
      decoration: BoxDecoration(
        color: selectedProductTab == tabIndex
            ? sh_colorPrimary
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              selectedProductTab = tabIndex;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(
                title,
                style: boldTextStyle(
                  size: 16,
                  color: selectedProductTab == tabIndex
                      ? white
                      : (appStore.isDarkModeOn
                          ? Colors.white70
                          : sh_textColorPrimary),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductGrid(List<AmProductModel> products) {
    final double w = MediaQuery.of(context).size.width;
    double aspect = 0.72;
    if (w < 320) {
      aspect = 0.62;
    } else if (w < 360) {
      aspect = 0.66;
    }
    return Container(
      padding: EdgeInsets.all(16),
      child: GridView.builder(
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: aspect,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          return AmProductCard(product: products[index]);
        },
      ),
    );
  }

  Widget _HomeSkeletonLoader() {
    final base = Colors.grey.shade300;
    final highlight = Colors.grey.shade100;
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: _Shimmer(
          base: base,
          highlight: highlight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: List.generate(
                  4,
                  (i) => Expanded(
                    child: Container(
                      height: 44,
                      margin: EdgeInsets.only(right: i < 3 ? 12 : 0),
                      decoration: BoxDecoration(
                        color: base,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: base,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: base,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              GridView.builder(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: 8,
                itemBuilder: (_, __) {
                  return Container(
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  );
                },
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
    required String selectedValue,
  }) {
    // ... (implementation unchanged)
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: sh_view_color, width: 1),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: primaryTextStyle(
                              size: 12, color: sh_textColorSecondary),
                        ),
                        SizedBox(height: 2),
                        Text(
                          selectedValue,
                          style: boldTextStyle(size: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: sh_textColorSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceDropdown() {
    return StatefulBuilder(
      builder: (context, setStateInner) {
        return Container(
          margin: EdgeInsets.only(top: 12),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: sh_view_color, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Price Range', style: boldTextStyle(size: 16)),
              SizedBox(height: 16),

              // Current Selected Range Display
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: sh_colorPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: sh_colorPrimary.withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: Text(
                    '\$${currentRangeValues.start.round()} - \$${currentRangeValues.end.round()}',
                    style: boldTextStyle(size: 18, color: sh_colorPrimary),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Range Slider
              RangeSlider(
                values: currentRangeValues,
                min: minPrice,
                max: maxPrice,
                labels: RangeLabels(
                  '\$${currentRangeValues.start.round()}',
                  '\$${currentRangeValues.end.round()}',
                ),
                onChanged: (RangeValues values) {
                  setStateInner(() {
                    currentRangeValues = values;
                  });
                },
                activeColor: sh_colorPrimary,
                inactiveColor: sh_view_color,
              ),

              // Min Max Labels
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('\$${minPrice.round()}',
                      style: secondaryTextStyle(size: 12)),
                  Text('\$${maxPrice.round()}',
                      style: secondaryTextStyle(size: 12)),
                ],
              ),
              SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Reset to default range
                        setStateInner(() {
                          currentRangeValues = RangeValues(minPrice, maxPrice);
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: sh_textColorSecondary),
                      ),
                      child: Text('Reset',
                          style:
                              primaryTextStyle(color: sh_textColorSecondary)),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Apply the selected price range
                        this.setState(() {
                          selectedPriceRange =
                              '\$${currentRangeValues.start.round()} - \$${currentRangeValues.end.round()}';
                          showPriceDropdown = false;
                          _applyFiltersInternal();
                        });
                        print(
                            'Price range applied: ${currentRangeValues.start} - ${currentRangeValues.end}');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: sh_colorPrimary,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child:
                          Text('Apply', style: primaryTextStyle(color: white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      margin: EdgeInsets.only(top: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: sh_view_color, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Category', style: boldTextStyle(size: 16)),
          SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Categories')
                .snapshots()
                .asBroadcastStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Something went wrong');
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              final categories = snapshot.data!.docs
                  .map((doc) => AmCategory.fromQuerySnapshot(doc))
                  .toList();

              return Container(
                height: 100,
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
                              color: sh_view_color,
                              border:
                                  Border.all(color: sh_view_color, width: 2),
                            ),
                            child: category.image != null &&
                                    category.image!.isNotEmpty
                                ? ClipOval(
                                    child: category.image!.startsWith('http')
                                        ? CachedNetworkImage(
                                            imageUrl: category.image!,
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                CircularProgressIndicator(),
                                            errorWidget:
                                                (context, url, error) =>
                                                    Icon(Icons.error),
                                          )
                                        : Image.asset(
                                            category.image!,
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                          ),
                                  )
                                : Icon(Icons.category,
                                    color: sh_textColorSecondary),
                          ),
                          SizedBox(height: 8),
                          Text(
                            category.name ?? '',
                            style: primaryTextStyle(size: 12),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ).onTap(() {
                        setState(() {
                          showCategoryDropdown = false;
                        });
                        AmViewAllProductscreen(
                                category: category, title: category.name)
                            .launch(context);
                      }),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCountryDropdown() {
    return Container(
      margin: EdgeInsets.only(top: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: sh_view_color, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Country', style: boldTextStyle(size: 16)),
          SizedBox(height: 16),
          Container(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: countries.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  final bool isSelectedAll = selectedCountry == 'Countries';
                  return Container(
                    margin: EdgeInsets.only(right: 12),
                    child: FilterChip(
                      label: Text(
                        "All Countries",
                        style: TextStyle(
                            color: isSelectedAll ? white : sh_textColorPrimary),
                      ),
                      selected: isSelectedAll,
                      onSelected: (selected) => selectCountry('Countries'),
                      selectedColor: sh_colorPrimary,
                      checkmarkColor: white,
                    ),
                  );
                }
                final country = countries[index - 1];
                return Container(
                  margin: EdgeInsets.only(right: 12),
                  child: FilterChip(
                    label: Text(
                      country,
                      style: TextStyle(
                          color: selectedCountry == country
                              ? white
                              : sh_textColorPrimary),
                    ),
                    selected: selectedCountry == country,
                    onSelected: (selected) => selectCountry(country),
                    selectedColor: sh_colorPrimary,
                    checkmarkColor: white,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandDropdown() {
    return Container(
      margin: EdgeInsets.only(top: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: sh_view_color, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Brand', style: boldTextStyle(size: 16)),
          SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Brands')
                .snapshots()
                .asBroadcastStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Something went wrong');
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              final brands = snapshot.data!.docs
                  .map((doc) => AmBrand.fromQuerySnapshot(doc))
                  .toList();

              return Container(
                height: 100,
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
                              color: sh_view_color,
                              border:
                                  Border.all(color: sh_view_color, width: 2),
                            ),
                            child:
                                brand.image != null && brand.image!.isNotEmpty
                                    ? ClipOval(
                                        child: brand.image!.startsWith('http')
                                            ? CachedNetworkImage(
                                                imageUrl: brand.image!,
                                                width: 50,
                                                height: 50,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) =>
                                                    CircularProgressIndicator(),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        Icon(Icons.error),
                                              )
                                            : Image.asset(
                                                brand.image!,
                                                width: 50,
                                                height: 50,
                                                fit: BoxFit.cover,
                                              ),
                                      )
                                    : Icon(Icons.business,
                                        color: sh_textColorSecondary),
                          ),
                          SizedBox(height: 8),
                          Text(
                            brand.name ?? '',
                            style: primaryTextStyle(size: 12),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ).onTap(() {
                        setState(() {
                          showBrandDropdown = false;
                        });
                        AmViewAllProductscreen(
                                title: brand.name, brandName: brand.name)
                            .launch(context);
                      }),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Shimmer extends StatefulWidget {
  final Widget child;
  final Color base;
  final Color highlight;
  const _Shimmer(
      {required this.child, required this.base, required this.highlight});
  @override
  _ShimmerState createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 1500))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return ShaderMask(
          shaderCallback: (rect) {
            final dx = (1.0 + 2.0) * _controller.value - 1.0;
            return LinearGradient(
              begin: Alignment(-1.0 + dx, 0),
              end: Alignment(1.0 + dx, 0),
              colors: [widget.base, widget.highlight, widget.base],
              stops: [0.2, 0.5, 0.8],
            ).createShader(rect);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}
