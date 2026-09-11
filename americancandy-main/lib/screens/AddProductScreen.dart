import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:american_sweets/models/AmProduct.dart';
import 'package:american_sweets/models/AmBrand.dart';
import 'package:american_sweets/models/AmCategory.dart';
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/utils/AmConstant.dart';
import 'package:american_sweets/utils/AmStrings.dart';
import 'package:american_sweets/screens/AmHomeScreen.dart';
import 'package:american_sweets/screens/AdminDashboardScreen.dart';
import 'package:american_sweets/screens/OrderManagementScreen.dart';
import 'package:american_sweets/screens/ProductManagementScreen.dart';
import 'package:american_sweets/screens/CustomerManagementScreen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:american_sweets/firebase_options.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({Key? key}) : super(key: key);
  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  List<AmBrand> _brands = [];
  String? _selectedBrand;
  int _currentTab = 3;
  int? _selectedCategory;
  int _selectedMainCategoryId = 0;
  int _selectedSubCategoryId = 0;
  List<AmCategory> _categories = [];

  final _nameCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _ingCtrl = TextEditingController();
  final _priceCtrl = TextEditingController(text: '');
  final _unitPriceCtrl = TextEditingController(text: '');
  final _availableQtyCtrl = TextEditingController();
  final _priceDescCtrl = TextEditingController();
  final _vatRateCtrl = TextEditingController(text: '');
  List<String> _productImages = [];
  bool _uploadingImages = false;
  int _uploadDone = 0;
  int _uploadTotal = 0;

  List<String> _sizes = const ['Small', 'Medium', 'Large'];
  List<String> _flavors = const ['Caramel', 'Strawberry', 'Mint', 'Vanilla'];
  List<String> _packagings = const ['Pouch', 'Box', 'Jar'];
  List<String> _countries = const ['USA', 'UK', 'Canada'];

  String _size = 'Small';
  String _flavor = 'Caramel';
  String _packaging = 'Pouch';
  String _country = 'USA';
  String _status = 'active';
  bool _featured = false;

  final List<String> _statuses = ['active', 'inactive', 'hold'];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchBrands();
    _fetchCategories();
    _loadVariantOptions();
  }

  Future<void> _loadVariantOptions() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('admin_setting')
          .doc('vw0U6xyVtJRKsL2b7F57')
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final sizes = (data['variant_sizes'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            _sizes;
        final flavors = (data['variant_flavors'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            _flavors;
        final packagings = (data['variant_packagings'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            _packagings;
        final countries = (data['variant_countries'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            _countries;
        if (mounted) {
          setState(() {
            _sizes = sizes.isNotEmpty ? sizes : _sizes;
            _flavors = flavors.isNotEmpty ? flavors : _flavors;
            _packagings = packagings.isNotEmpty ? packagings : _packagings;
            _countries = countries.isNotEmpty ? countries : _countries;
            if (!_sizes.contains(_size) && _sizes.isNotEmpty) {
              _size = _sizes.first;
            }
            if (!_flavors.contains(_flavor) && _flavors.isNotEmpty) {
              _flavor = _flavors.first;
            }
            if (!_packagings.contains(_packaging) && _packagings.isNotEmpty) {
              _packaging = _packagings.first;
            }
            if (!_countries.contains(_country) && _countries.isNotEmpty) {
              _country = _countries.first;
            }
          });
        }
      }
    } catch (e) {
      print('Error loading variant options: $e');
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('Categories').get();
      if (mounted) {
        setState(() {
          _categories = snapshot.docs
              .map((doc) => AmCategory.fromQuerySnapshot(doc))
              .toList();
          if (_categories.isNotEmpty && _selectedCategory == null) {
            _selectedCategory = _categories.first.id;
            _initializeCategorySelection();
          }
        });
      }
    } catch (e) {
      print("Error fetching categories: $e");
    }
  }
  
  void _initializeCategorySelection() {
    if (_selectedCategory == null) {
      _selectedMainCategoryId = 0;
      _selectedSubCategoryId = 0;
      return;
    }
    
    // Check if the selected category is a subcategory
    final selectedCat = _categories.firstWhere(
      (c) => c.id == _selectedCategory,
      orElse: () => _categories.first,
    );
    
    if (selectedCat.parent != null && selectedCat.parent != 0 && selectedCat.parent != -999999) {
      // The selected category is a subcategory, so set both main and sub
      _selectedMainCategoryId = selectedCat.parent!;
      _selectedSubCategoryId = _selectedCategory!;
    } else {
      // The selected category is a main category
      _selectedMainCategoryId = _selectedCategory!;
      _selectedSubCategoryId = 0;
    }
  }
  
  List<AmCategory> getMainCategories() {
    return _categories.where((c) => 
      c.parent == null || c.parent == 0 || c.parent == -999999
    ).toList();
  }
  
  List<AmCategory> getSubcategoriesForMainCategory(int mainCategoryId) {
    if (mainCategoryId == 0 || mainCategoryId == -999999) {
      return [];
    }
    return _categories.where((c) => c.parent == mainCategoryId).toList();
  }

  Future<void> _fetchBrands() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('Brands').get();
      if (mounted) {
        setState(() {
          _brands = snapshot.docs
              .map((doc) => AmBrand.fromQuerySnapshot(doc))
              .toList();
        });
      }
    } catch (e) {
      print("Error fetching brands: $e");
    }
  }

  Future<void> _pickAndUploadImages() async {
    final List<XFile>? images = await _picker.pickMultiImage();
    if (images != null && images.isNotEmpty) {
      setState(() {
        _uploadingImages = true;
        _uploadDone = 0;
        _uploadTotal = images.length;
      });
      toast('Uploading ${images.length} images...');
      for (var image in images) {
        String fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
        final path = "products/$fileName";

        // Upload
        try {
          String downloadUrl = await _uploadWithFallback(image, path);

          setState(() {
            _productImages.add(downloadUrl);
            _uploadDone += 1;
          });
        } catch (e, st) {
          if (e is FirebaseException) {
            toast(
                'Upload failed for ${image.name} [${e.plugin}/${e.code}]: ${e.message ?? 'Error'}');
          } else {
            toast('Upload failed for ${image.name}: $e');
          }
          print('Upload error: $e');
          print(st);
        }
      }
      setState(() {
        _uploadingImages = false;
      });
      toast('Upload process completed');
    }
  }

  Future<String> _uploadWithFallback(XFile image, String path) async {
    final ext = (image.name.split('.').last).toLowerCase();
    final contentType = ext == 'png'
        ? 'image/png'
        : (ext == 'webp'
            ? 'image/webp'
            : (ext == 'jpg' || ext == 'jpeg' ? 'image/jpeg' : 'image/*'));
    final refPrimary = FirebaseStorage.instance.ref().child(path);
    try {
      if (!kIsWeb && image.path.isNotEmpty) {
        await refPrimary.putFile(
            File(image.path), SettableMetadata(contentType: contentType));
      } else {
        final bytes = await image.readAsBytes();
        await refPrimary.putData(
            bytes, SettableMetadata(contentType: contentType));
      }
      return await refPrimary.getDownloadURL();
    } on FirebaseException {
      final opts = DefaultFirebaseOptions.currentPlatform;
      final bucket = opts.storageBucket;
      final projectId = opts.projectId;
      final altGs = bucket != null && bucket.isNotEmpty
          ? 'gs://${bucket.replaceAll('.firebasestorage.app', '.appspot.com')}'
          : 'gs://${projectId}.appspot.com';
      final refAlt =
          FirebaseStorage.instanceFor(bucket: altGs).ref().child(path);
      if (!kIsWeb && image.path.isNotEmpty) {
        await refAlt.putFile(
            File(image.path), SettableMetadata(contentType: contentType));
      } else {
        final bytes = await image.readAsBytes();
        await refAlt.putData(bytes, SettableMetadata(contentType: contentType));
      }
      return await refAlt.getDownloadURL();
    }
  }

  Future<void> _saveProduct() async {
    // Determine the actual category ID based on main and subcategory selection
    int actualCategoryId = _selectedSubCategoryId > 0 ? _selectedSubCategoryId : _selectedMainCategoryId;
    
    final newProduct = AmProductModel(
      name: _nameCtrl.text,
      brand: _selectedBrand,
      sku: _skuCtrl.text,
      description: _descCtrl.text,
      ingredients: _ingCtrl.text,
      price: double.tryParse(_priceCtrl.text) ?? 0.0,
      unitPrice: double.tryParse(_unitPriceCtrl.text) ?? 0.0,
      vatRate: double.tryParse(_vatRateCtrl.text) ?? 0.0,
      priceDescription: _priceDescCtrl.text,
      category: actualCategoryId,
      currency: "GBP",
      thumbnail: _productImages.isNotEmpty ? _productImages.first : '',
      images: _productImages,
      variants: AmVariant(
        size: _size,
        flavor: _flavor,
        packaging: _packaging,
        country: _country,
      ),
      availableQuantity: int.tryParse(_availableQtyCtrl.text.trim().isEmpty
          ? '0'
          : _availableQtyCtrl.text.trim()),
      status: _status,
      featured: _featured,
    );

    try {
      final data = newProduct.toJson();
      data['created_at'] = FieldValue.serverTimestamp();
      data['updated_at'] = FieldValue.serverTimestamp();
      await FirebaseFirestore.instance.collection('Products').add(data);
      toast('Product created successfully');
      finish(context);
      const ProductManagementScreen().launch(context);
    } catch (e) {
      toast('Error creating product: $e');
    }
  }

  Widget _buildImagesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Product Images'),
        8.height,
        Stack(children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._productImages.map((url) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: url.startsWith('http')
                          ? CachedNetworkImage(
                              imageUrl: url,
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                  height: 100,
                                  width: 100,
                                  color: Colors.grey[200],
                                  alignment: Alignment.center,
                                  child: const CircularProgressIndicator()),
                              errorWidget: (context, url, error) => Container(
                                  height: 100,
                                  width: 100,
                                  color: Colors.grey[200],
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.error,
                                      color: Colors.red)),
                            )
                          : Image.asset(
                              url,
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                      height: 100,
                                      width: 100,
                                      color: Colors.grey[200],
                                      alignment: Alignment.center,
                                      child: const Icon(Icons.broken_image,
                                          color: Colors.grey)),
                            ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _productImages.remove(url);
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(Icons.close,
                              size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
              InkWell(
                onTap: _pickAndUploadImages,
                child: Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  alignment: Alignment.center,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, color: Colors.grey),
                      SizedBox(height: 4),
                      Text('Add', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_uploadingImages)
            Positioned.fill(
              child: Container(
                color: Colors.white.withValues(alpha: 0.75),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    8.height,
                    Text('Uploading ${_uploadDone}/${_uploadTotal}',
                        style: primaryTextStyle()),
                  ],
                ),
              ),
            ),
        ]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: sh_background_color,
      body: SafeArea(
        child: Column(
          children: [
            8.height,
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                      colors: [sh_gradient_1st, sh_gradient_2nd],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight)
                  .createShader(
                      Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
              child: Text(sh_app_name,
                  style: GoogleFonts.workSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
            12.height,
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: spacing_standard_new),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                      onTap: () => finish(context),
                      child: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: defaultBoxShadow(
                                  shadowColor: appShadowColor)),
                          child: const Icon(Icons.arrow_back))),
                  Text('Add Product',
                      style: GoogleFonts.workSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: sh_colorPrimary)),
                  Stack(children: [
                    const Icon(Icons.notifications_none,
                        color: sh_colorPrimary),
                    Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle)))
                  ])
                ],
              ),
            ),
            12.height,
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: spacing_standard_new),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel('Product Name'),
                    _InputField(
                        controller: _nameCtrl, hint: 'e.g., Gummy Bears'),
                    12.height,
                    _SectionLabel('SKU'),
                    _InputField(controller: _skuCtrl, hint: 'SKU'),
                    12.height,
                    _SectionLabel('Description'),
                    _InputField(
                        controller: _descCtrl,
                        hint: 'Describe the product...',
                        maxLines: 4),
                    12.height,
                    _SectionLabel('Ingredients'),
                    _InputField(controller: _ingCtrl, hint: 'Ingredients....'),
                    12.height,
                    Row(children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionLabel('Main Category'),
                            _DropdownField<int>(
                                value: _selectedMainCategoryId,
                                items: [0, ...getMainCategories().map((e) => e.id ?? 0)],
                                itemLabels: ['None', ...getMainCategories().map((e) => e.name ?? 'Unknown')],
                                onChanged: (v) {
                                  setState(() {
                                    _selectedMainCategoryId = v!;
                                    _selectedSubCategoryId = 0; // Reset subcategory when main changes
                                  });
                                }),
                          ],
                        ),
                      ),
                      12.width,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionLabel('Brand'),
                            _DropdownField<String?>(
                                value: _selectedBrand,
                                items: _brands
                                    .map((e) => e.name)
                                    .where((element) =>
                                        element != null &&
                                        element.toString().isNotEmpty)
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _selectedBrand = v)),
                          ],
                        ),
                      ),
                    ]),
                    12.height,
                    // Show subcategory dropdown only if main category has subcategories
                    if (_selectedMainCategoryId > 0 && _selectedMainCategoryId != -999999)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionLabel('Sub Category (Optional)'),
                          _DropdownField<int>(
                            value: _selectedSubCategoryId,
                            items: [0, ...getSubcategoriesForMainCategory(_selectedMainCategoryId).map((c) => c.id ?? 0)],
                            itemLabels: ['None', ...getSubcategoriesForMainCategory(_selectedMainCategoryId).map((c) => c.name ?? 'Unknown')],
                            onChanged: (v) => setState(() => _selectedSubCategoryId = v!),
                          ),
                          12.height,
                        ],
                      ),
                    12.height,
                    Row(children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionLabel('Price'),
                            _CurrencyField(controller: _priceCtrl),
                          ],
                        ),
                      ),
                      12.width,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionLabel('Unit Price'),
                            _CurrencyField(controller: _unitPriceCtrl),
                          ],
                        ),
                      ),
                    ]),
                    12.height,
                    Row(children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionLabel('Available Quantity'),
                            _InputField(
                                controller: _availableQtyCtrl,
                                hint: 'e.g., 100'),
                          ],
                        ),
                      ),
                      12.width,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionLabel('VAT Rate (%)'),
                            _InputField(controller: _vatRateCtrl,hint: "0.00",),
                          ],
                        ),
                      ),
                    ]),
                    12.height,
                    _SectionLabel('Price Description'),
                    _InputField(
                        controller: _priceDescCtrl,
                        hint: 'Price Description....'),
                    12.height,
                    16.height,
                    _buildImagesList(),
                    20.height,
                    Row(children: [
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            _SectionLabel('Status'),
                            _DropdownField<String>(
                                value: _status,
                                items: _statuses,
                                onChanged: (v) => setState(() => _status = v!)),
                          ])),
                      12.width,
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            _SectionLabel('Featured'),
                            _DropdownField<bool>(
                                value: _featured,
                                items: const [true, false],
                                itemLabels: const ['Yes', 'No'],
                                onChanged: (v) =>
                                    setState(() => _featured = v ?? false)),
                          ])),
                    ]),
                    20.height,
                    Row(children: [
                      Expanded(
                          child: _PillButton(
                              label: 'Save',
                              bgColor: sh_colorPrimary,
                              onTap: _saveProduct)),
                      12.width,
                      Expanded(
                          child: _PillButton(
                              label: 'Cancel',
                              gradient: const LinearGradient(
                                  colors: [sh_gradient_1st, sh_gradient_2nd]),
                              onTap: () => finish(context))),
                    ]),
                    24.height,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        child: BottomNavigationBar(
          currentIndex: _currentTab,
          onTap: (i) {
            if (i == _currentTab) return;
            setState(() => _currentTab = i);
            if (i == 0) AmHomeScreen().launch(context);
            if (i == 1) const AdminDashboardScreen().launch(context);
            if (i == 2) OrderManagementScreen().launch(context);
            if (i == 3) ProductManagementScreen().launch(context);
            if (i == 4) CustomerManagementScreen().launch(context);
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: sh_colorPrimary,
          unselectedItemColor: Colors.black54,
          backgroundColor: Colors.white,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
            BottomNavigationBarItem(
                icon: Icon(Icons.inventory_2_outlined), label: 'Orders'),
            BottomNavigationBarItem(
                icon: Icon(Icons.shopping_bag_outlined), label: 'Products'),
            BottomNavigationBarItem(
                icon: Icon(Icons.group_outlined), label: 'Customers'),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text, {Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: GoogleFonts.workSans(
            fontSize: 14, fontWeight: FontWeight.w800, color: sh_colorPrimary));
  }
}

class _SubLabel extends StatelessWidget {
  final String text;
  const _SubLabel(this.text, {Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: GoogleFonts.workSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: sh_textColorPrimary));
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  const _InputField(
      {Key? key,
      required this.controller,
      required this.hint,
      this.maxLines = 1})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.workSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: sh_textColorPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.workSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: sh_textColorSecondary),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.0),
            borderSide: BorderSide(color: sh_view_color)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.0),
            borderSide: BorderSide(color: sh_view_color)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}

class _CurrencyField extends StatelessWidget {
  final TextEditingController controller;
  const _CurrencyField({Key? key, required this.controller}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: GoogleFonts.workSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: sh_textColorPrimary),
      decoration: InputDecoration(
        prefixText: '£  ',
        prefixStyle: GoogleFonts.workSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: sh_textColorPrimary),
        hintText: '0.00',
        hintStyle: GoogleFonts.workSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: sh_textColorSecondary),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.0),
            borderSide: BorderSide(color: sh_view_color)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.0),
            borderSide: BorderSide(color: sh_view_color)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final T? value;
  final List<T> items;
  final List<String>? itemLabels;
  final ValueChanged<T?> onChanged;
  const _DropdownField(
      {Key? key,
      required this.value,
      required this.items,
      this.itemLabels,
      required this.onChanged})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    List<T> effectiveItems = List<T>.from(items);
    List<String>? effectiveLabels =
        itemLabels != null ? List<String>.from(itemLabels!) : null;
    T? dropdownValue = value;
    if (dropdownValue != null && !effectiveItems.contains(dropdownValue)) {
      effectiveItems.insert(0, dropdownValue);
      if (effectiveLabels != null) {
        effectiveLabels.insert(0, dropdownValue.toString());
      }
    }
    return DropdownButtonFormField<T>(
      initialValue: dropdownValue,
      isExpanded: true,
      items: List.generate(effectiveItems.length, (index) {
        return DropdownMenuItem<T>(
          value: effectiveItems[index],
          child: Text(
            effectiveLabels != null
                ? effectiveLabels[index]
                : effectiveItems[index].toString(),
            style: GoogleFonts.workSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: sh_textColorPrimary,
            ),
          ),
        );
      }),
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.0),
            borderSide: BorderSide(color: sh_view_color)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.0),
            borderSide: BorderSide(color: sh_view_color)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
    );
  }
}

class _UploadBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: sh_view_color)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: const Color(0xFFF4F6F8),
                borderRadius: BorderRadius.circular(12)),
            child:
                const Icon(Icons.image_outlined, color: sh_textColorSecondary)),
        12.height,
        ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
                    colors: [sh_gradient_1st, sh_gradient_2nd],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight)
                .createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
            child: Text('Upload a file',
                style: GoogleFonts.workSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white))),
        6.height,
        Text('or drag and drop',
            style: GoogleFonts.workSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: sh_textColorSecondary)),
        4.height,
        Text('PNG, JPG, GIF up to 10MB',
            style: GoogleFonts.workSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: sh_textColorSecondary)),
      ]),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final Color? bgColor;
  final LinearGradient? gradient;
  final VoidCallback onTap;
  const _PillButton(
      {Key? key,
      required this.label,
      required this.onTap,
      this.bgColor,
      this.gradient})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: bgColor,
            gradient: gradient,
            borderRadius: BorderRadius.circular(32),
            boxShadow: defaultBoxShadow(shadowColor: appShadowColor)),
        child: Text(label,
            style: GoogleFonts.workSans(
                fontSize: 16, fontWeight: FontWeight.w700, color: sh_white)),
      ),
    );
  }
}
