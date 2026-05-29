import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import 'package:american_sweets/firebase_options.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:american_sweets/models/AmProduct.dart';
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/utils/AmConstant.dart';
import 'package:american_sweets/utils/AmStrings.dart';
import 'package:american_sweets/screens/AmHomeScreen.dart';
import 'package:american_sweets/screens/AdminDashboardScreen.dart';
import 'package:american_sweets/screens/OrderManagementScreen.dart';
import 'package:american_sweets/screens/ProductManagementScreen.dart';
import 'package:american_sweets/screens/CustomerManagementScreen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductDetailsScreen extends StatefulWidget {
  final AmProductModel product;

  const ProductDetailsScreen({Key? key, required this.product})
      : super(key: key);

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _currentTab = 3;

  List<Map<String, dynamic>> _categories = [];
  List<String> _brands = [];
  String? _selectedBrand;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _brandCtrl;
  late final TextEditingController _skuCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _ingCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _unitPriceCtrl;
  late final TextEditingController _availableQtyCtrl;
  late final TextEditingController _priceDescCtrl;
  late final TextEditingController _vatRateCtrl;
  late int _selectedCategory;
  List<String> _productImages = [];

  List<String> _sizes = const ['Small', 'Medium', 'Large'];
  List<String> _flavors = const ['Caramel', 'Strawberry', 'Mint', 'Vanilla'];
  List<String> _packagings = const ['Pouch', 'Box', 'Jar'];
  List<String> _countries = const ['USA', 'UK', 'Canada'];

  late String _size;
  late String _flavor;
  late String _packaging;
  late String _country;
  late String _status;
  late bool _featured;
  final List<String> _statuses = ['active', 'inactive', 'hold'];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.product.name);
    _brandCtrl = TextEditingController(text: widget.product.brand);
    _skuCtrl = TextEditingController(text: widget.product.sku);
    _descCtrl = TextEditingController(text: widget.product.description);
    _ingCtrl = TextEditingController(text: widget.product.ingredients);
    _priceCtrl = TextEditingController(
        text: widget.product.price?.toStringAsFixed(2) ?? '0.00');
    _unitPriceCtrl = TextEditingController(
        text: widget.product.unitPrice?.toStringAsFixed(2) ??
            widget.product.price?.toStringAsFixed(2) ??
            '0.00');
    _availableQtyCtrl = TextEditingController(
        text: widget.product.availableQuantity?.toString() ?? '');
    _priceDescCtrl =
        TextEditingController(text: widget.product.priceDescription);
    _vatRateCtrl = TextEditingController(
        text: widget.product.vatRate?.toStringAsFixed(2) ?? '0.00');

    _selectedCategory = widget.product.category ?? 18;
    _selectedBrand = widget.product.brand;

    _productImages = List.from(widget.product.images ?? []);

    _size = widget.product.variants?.size ?? 'Small';
    _flavor = widget.product.variants?.flavor ?? 'Caramel';
    _packaging = widget.product.variants?.packaging ?? 'Pouch';
    _country = widget.product.variants?.country ?? 'USA';
    _status = widget.product.status ?? 'active';
    _featured = widget.product.featured ?? false;
    _loadVariantOptions();
    _loadCategories();
    _loadBrands();
  }

  Future<void> _loadCategories() async {
    try {
      final snap =
          await FirebaseFirestore.instance.collection('Categories').get();
      final cats = snap.docs
          .map((d) => {
                'id': (d.data()['id'] ?? d.id)
                        .toString()
                        .contains(RegExp(r'^\d+$'))
                    ? int.tryParse(d.data()['id'].toString()) ?? 0
                    : int.tryParse(d.id) ?? 0,
                'name': d.data()['name']?.toString() ?? '',
              })
          .where(
              (m) => (m['id'] as int) != 0 && (m['name'] as String).isNotEmpty)
          .toList();
      if (mounted) {
        setState(() {
          _categories = cats;
          if (!_categories.any((e) => e['id'] == _selectedCategory) &&
              _categories.isNotEmpty) {
            _selectedCategory = _categories.first['id'];
          }
        });
      }
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  Future<void> _loadBrands() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('Brands').get();
      final names = snap.docs
          .map((d) => (d.data()['name'] ?? '').toString())
          .where((n) => n.isNotEmpty)
          .toList();
      if (mounted) {
        setState(() {
          _brands = names;
          if (_selectedBrand == null && _brands.isNotEmpty) {
            _selectedBrand = _brands.first;
          }
        });
      }
    } catch (e) {
      print('Error loading brands: $e');
    }
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
              _sizes.insert(0, _size);
            }
            if (!_flavors.contains(_flavor) && _flavors.isNotEmpty) {
              _flavors.insert(0, _flavor);
            }
            if (!_packagings.contains(_packaging) && _packagings.isNotEmpty) {
              _packagings.insert(0, _packaging);
            }
            if (!_countries.contains(_country) && _countries.isNotEmpty) {
              _countries.insert(0, _country);
            }
          });
        }
      }
    } catch (e) {
      print('Error loading variant options: $e');
    }
  }

  Future<void> _saveProduct() async {
    final updatedProduct = AmProductModel(
      id: widget.product.id,
      name: _nameCtrl.text,
      brand: _selectedBrand ?? _brandCtrl.text,
      sku: _skuCtrl.text,
      description: _descCtrl.text,
      ingredients: _ingCtrl.text,
      price: double.tryParse(_priceCtrl.text) ?? 0.0,
      unitPrice: double.tryParse(_unitPriceCtrl.text) ?? 0.0,
      vatRate: double.tryParse(_vatRateCtrl.text) ?? 0.0,
      priceDescription: _priceDescCtrl.text,
      category: _selectedCategory,
      currency: widget.product.currency ?? "GBP",
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
      if (widget.product.id != null) {
        final update = updatedProduct.toJson();
        update['updated_at'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance
            .collection('Products')
            .doc(widget.product.id)
            .update(update);
        toast('Product updated successfully');
      } else {
        // Fallback if ID is missing (shouldn't happen in details screen)
        final data = updatedProduct.toJson();
        data['created_at'] = FieldValue.serverTimestamp();
        data['updated_at'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('Products').add(data);
        toast('Product created successfully');
      }
      finish(context);
    } catch (e) {
      toast('Error updating product: $e');
    }
  }

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndUploadImages() async {
    final List<XFile>? images = await _picker.pickMultiImage();
    if (images != null && images.isNotEmpty) {
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
          });
        } catch (e, st) {
          if (e is FirebaseException) {
            toast(
                'Upload failed for ${image.name} [${e.plugin}/${e.code}]: ${e.message ?? 'Error'}');
          } else {
            toast('Upload failed for ${image.name}: $e');
          }
          print(e);
          print(st);
        }
      }
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

  Widget _buildImagesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Product Images'),
        8.height,
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
                                child:
                                    const Icon(Icons.error, color: Colors.red)),
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
                          color: Colors.red.withOpacity(0.8),
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
                  Text('Product Edit Details',
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
                      _InputField(controller: _nameCtrl, hint: 'Product Name'),
                      12.height,
                      _SectionLabel('SKU'),
                      _InputField(controller: _skuCtrl, hint: 'SKU'),
                      12.height,
                      _SectionLabel('Description'),
                      _InputField(
                          controller: _descCtrl,
                          hint: 'Description...',
                          maxLines: 4),
                      12.height,
                      _SectionLabel('Ingredients'),
                      _InputField(
                          controller: _ingCtrl, hint: 'Ingredients....'),
                      12.height,
                      Row(children: [
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SectionLabel('Category'),
                                _DropdownField<int>(
                                    value: _selectedCategory,
                                    items: _categories
                                        .map((e) => e['id'] as int)
                                        .toList(),
                                    itemLabels: _categories
                                        .map((e) => e['name'] as String)
                                        .toList(),
                                    onChanged: (v) =>
                                        setState(() => _selectedCategory = v!)),
                              ]),
                        ),
                        12.width,
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SectionLabel('Brand'),
                                _DropdownField<String?>(
                                    value: _selectedBrand,
                                    items: _brands,
                                    onChanged: (v) =>
                                        setState(() => _selectedBrand = v)),
                              ]),
                        ),
                      ]),
                      12.height,
                      Row(children: [
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SectionLabel('Price'),
                                _CurrencyField(controller: _priceCtrl),
                              ]),
                        ),
                        12.width,
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SectionLabel('Unit Price'),
                                _CurrencyField(controller: _unitPriceCtrl),
                              ]),
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
                              ]),
                        ),
                        12.width,
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SectionLabel('VAT Rate (%)'),
                                _CurrencyField(controller: _vatRateCtrl),
                              ]),
                        ),
                      ]),
                      12.height,
                      _SectionLabel('Price Description'),
                      _InputField(
                          controller: _priceDescCtrl,
                          hint: 'Price Description....'),
                      16.height,
                      Text('Variants',
                          style: GoogleFonts.workSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: sh_colorPrimary)),
                      12.height,
                      Row(children: [
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              _SubLabel('Size'),
                              _DropdownField<String>(
                                  value: _size,
                                  items: _sizes,
                                  onChanged: (v) => setState(() => _size = v!)),
                            ])),
                        12.width,
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              _SubLabel('Flavor'),
                              _DropdownField<String>(
                                  value: _flavor,
                                  items: _flavors,
                                  onChanged: (v) =>
                                      setState(() => _flavor = v!)),
                            ])),
                      ]),
                      12.height,
                      Row(children: [
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              _SubLabel('Packaging'),
                              _DropdownField<String>(
                                  value: _packaging,
                                  items: _packagings,
                                  onChanged: (v) =>
                                      setState(() => _packaging = v!)),
                            ])),
                        12.width,
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              _SubLabel('Country'),
                              _DropdownField<String>(
                                  value: _country,
                                  items: _countries,
                                  onChanged: (v) =>
                                      setState(() => _country = v!)),
                            ])),
                      ]),
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
                                  onChanged: (v) =>
                                      setState(() => _status = v!)),
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
                    ]),
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
