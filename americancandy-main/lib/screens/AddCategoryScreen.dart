import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:american_sweets/utils/StorageUpload.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';
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

class AddCategoryScreen extends StatefulWidget {
  final AmCategory? category;

  const AddCategoryScreen({Key? key, this.category}) : super(key: key);

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  int _currentTab = 3; // Default to Product/Category tab
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  // final _parentCtrl = TextEditingController(text: '0'); // Removed in favor of dropdown
  final _slugCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  final _menuOrderCtrl = TextEditingController(text: '0');
  bool _isSelected = false;
  bool _isSlugEdited = false;
  int _selectedParentId = 0;
  int _selectedMainCategoryId = 0;
  int _selectedSubCategoryId = 0;
  List<AmCategory> categoryList = [];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    initialSetData();
  }

  Future<void> initialSetData() async{
    await _fetchCategories();
    if (widget.category != null) {
      _nameCtrl.text = widget.category!.name ?? '';
      _descCtrl.text = widget.category!.description ?? '';
      _idCtrl.text = widget.category!.id?.toString() ?? '';
      _selectedParentId = widget.category!.parent ?? 0;
      _slugCtrl.text = widget.category!.slug ?? '';
      _imageCtrl.text = widget.category!.image ?? '';

      if (_imageCtrl.text.startsWith('gs://')) {
        _resolveGsUrl(_imageCtrl.text);
      }

      _menuOrderCtrl.text = widget.category!.menuOrder?.toString() ?? '0';
      _isSelected = widget.category!.isSelected ?? false;
      _isSlugEdited =
      true; // Don't auto-update slug when editing existing category
      
      // Set main category and subcategory based on parent
      _initializeCategorySelection();
    }
  }
  
  void _initializeCategorySelection() {
    if (_selectedParentId == 0 || _selectedParentId == -999999) {
      _selectedMainCategoryId = 0;
      _selectedSubCategoryId = 0;
      return;
    }
    
    // Check if the selected parent is a subcategory
    final parentCategory = categoryList.firstWhere(
      (c) => c.id == _selectedParentId,
      orElse: () => categoryList.first,
    );
    
    if (parentCategory.parent != null && parentCategory.parent != 0 && parentCategory.parent != -999999) {
      // The selected parent is a subcategory, so set both main and sub
      _selectedMainCategoryId = parentCategory.parent!;
      _selectedSubCategoryId = _selectedParentId;
    } else {
      // The selected parent is a main category
      _selectedMainCategoryId = _selectedParentId;
      _selectedSubCategoryId = 0;
    }
  }
  
  List<AmCategory> getSubcategoriesForMainCategory(int mainCategoryId) {
    if (mainCategoryId == 0 || mainCategoryId == -999999) {
      return [];
    }
    return categoryList.where((c) => c.parent == mainCategoryId).toList();
  }

  Future<void> _resolveGsUrl(String gsUrl) async {
    try {
      String url =
          await FirebaseStorage.instance.refFromURL(gsUrl).getDownloadURL();
      setState(() {
        _imageCtrl.text = url;
      });
    } catch (e) {
      print('Error resolving gs:// URL: $e');
    }
  }

  Future<void> _fetchCategories() async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance.collection('Categories').get();
      List<AmCategory> loaded =
          snapshot.docs.map((doc) => AmCategory.fromSnapshot(doc)).toList();

      // Auto-calculate next ID for new categories
      if (widget.category == null) {
        int maxId = 0;
        for (var cat in loaded) {
          if ((cat.id ?? 0) > maxId) {
            maxId = cat.id!;
          }
        }
        _idCtrl.text = (maxId + 1).toString();
      }

      // If editing, remove self from parent options to avoid cycles
      if (widget.category != null) {
        loaded.removeWhere((c) => c.id == widget.category!.id);
      }

      setState(() {
        categoryList = loaded;
      });
    } catch (e) {
      toast('Error fetching categories: $e');
    }
  }

  Future<void> _pickAndUploadImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      String fileName =
          'cat_${DateTime.now().millisecondsSinceEpoch}_${image.name}';

      try {
        toast('Uploading...');
        // Use putData with bytes to avoid Platform.operatingSystem issues in some environments (e.g. Windows)
        // when using dart:io File with XFile path
        final bytes = await image.readAsBytes();
        final url = await StorageUpload.uploadBytes(
          bytes,
          "category/$fileName",
          contentType: 'image/jpeg',
        );

        setState(() {
          _imageCtrl.text = url;
        });
        toast('Upload successful');
      } catch (e) {
        if (e is FirebaseException) {
          toast(
              'Upload failed [${e.plugin}/${e.code}]: ${e.message ?? 'Error'}');
        } else {
          toast('Upload failed: $e');
        }
      }
    }
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    // Determine the actual parent ID based on main and subcategory selection
    int actualParentId = _selectedSubCategoryId > 0 ? _selectedSubCategoryId : _selectedMainCategoryId;

    final newCategory = AmCategory(
      count: 0,
      description: _descCtrl.text,
      id: int.tryParse(_idCtrl.text) ?? 0,
      isSelected: _isSelected,
      menuOrder: int.tryParse(_menuOrderCtrl.text) ?? 0,
      name: _nameCtrl.text,
      parent: actualParentId,
      slug: _slugCtrl.text.isEmpty
          ? _nameCtrl.text.toLowerCase().replaceAll(' ', '-')
          : _slugCtrl.text,
      image: _imageCtrl.text,
    );

    try {
      if (widget.category != null && widget.category!.docId != null) {
        await FirebaseFirestore.instance
            .collection('Categories')
            .doc(widget.category!.docId)
            .update(newCategory.toJson());
        toast('Category updated successfully');
      } else {
        await FirebaseFirestore.instance
            .collection('Categories')
            .add(newCategory.toJson());
        toast('Category created successfully');
      }
      finish(context);
    } catch (e) {
      toast('Error saving category: $e');
    }
  }

  Widget _buildAssetFallback() {
    String cleanName = _nameCtrl.text.trim().toLowerCase().replaceAll(' ', '_');
    if (cleanName.isEmpty) cleanName = 'placeholder';

    // Try png then jpg
    return Image.asset(
      "images/sweets/$cleanName.png",
      height: 150,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          "images/sweets/$cleanName.jpg",
          height: 150,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            height: 150,
            color: Colors.grey[200],
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.broken_image, color: Colors.grey),
                Text('No image found',
                    style: GoogleFonts.workSans(color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImagePreview() {
    String url = _imageCtrl.text.trim();
    if (url.isEmpty) {
      return _buildAssetFallback();
    }

    if (url.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url,
        height: 150,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
            height: 150,
            color: Colors.grey[200],
            alignment: Alignment.center,
            child: const CircularProgressIndicator()),
        errorWidget: (context, url, error) => _buildAssetFallback(),
      );
    }

    // Fallback for non-http strings (e.g. assets)
    return Image.asset(
      url,
      height: 150,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildAssetFallback(),
    );
  }

  @override
  Widget build(BuildContext context) {
    const int rootId = -999999;
    List<int> parentIds = [];
    List<String> parentNames = [];
    List<String?> parentImages = [];

    final addedIds = <int>{};

// Add Root ONLY once
    addedIds.add(rootId);
    parentIds.add(rootId);
    parentNames.add('Root');
    parentImages.add(null);

    // Only add main categories (parent == null, 0, or -999999)
    for (var c in categoryList) {
      final id = c.id;

      // Skip null IDs
      if (id == null) continue;
      // Skip duplicate IDs
      if (addedIds.contains(id)) continue;
      // Only add main categories (not subcategories)
      if (c.parent != null && c.parent != 0 && c.parent != rootId) continue;
      
      addedIds.add(id);
      parentIds.add(id);
      parentNames.add(c.name ?? 'Unknown');
      parentImages.add(c.image);
    }

    if (parentIds.where((e) => e == _selectedParentId).length != 1) {
      _selectedParentId = rootId;
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
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
                  Text(
                      widget.category != null
                          ? 'Edit Category'
                          : 'Add Category',
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel('Category Name'),
                      _InputField(
                          controller: _nameCtrl,
                          hint: 'e.g., Sweets',
                          onChanged: (v) {
                            if (!_isSlugEdited) {
                              _slugCtrl.text = v
                                  .trim()
                                  .toLowerCase()
                                  .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
                                  .replaceAll(RegExp(r'\s+'), '-');
                            }
                          }),
                      12.height,
                      _SectionLabel('Category ID'),
                      _InputField(
                          controller: _idCtrl, hint: 'Unique Integer ID'),
                      12.height,
                      _SectionLabel('Slug (Optional)'),
                      _InputField(
                          controller: _slugCtrl,
                          hint: 'slug-name',
                          onChanged: (v) => _isSlugEdited = true),
                      12.height,
                      _SectionLabel('Description'),
                      _InputField(
                          controller: _descCtrl,
                          hint: 'Describe the category...',
                          maxLines: 3),
                      12.height,
                      _SectionLabel('Main Category'),
                      _DropdownField<int>(
                        value: _selectedMainCategoryId,
                        items: parentIds,
                        itemLabels: parentNames,
                        itemImages: parentImages,
                        onChanged: (v) {
                          setState(() {
                            _selectedMainCategoryId = v!;
                            _selectedSubCategoryId = 0; // Reset subcategory when main changes
                          });
                        },
                      ),
                      12.height,
                      // Show subcategory dropdown only if main category has subcategories
                      if (_selectedMainCategoryId > 0 && _selectedMainCategoryId != -999999 && getSubcategoriesForMainCategory(_selectedMainCategoryId).isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionLabel('Sub Category (Optional)'),
                            _DropdownField<int>(
                              value: _selectedSubCategoryId,
                              items: [0, ...getSubcategoriesForMainCategory(_selectedMainCategoryId).map((c) => c.id ?? 0)],
                              itemLabels: ['None', ...getSubcategoriesForMainCategory(_selectedMainCategoryId).map((c) => c.name ?? 'Unknown')],
                              itemImages: [null, ...getSubcategoriesForMainCategory(_selectedMainCategoryId).map((c) => c.image)],
                              onChanged: (v) => setState(() => _selectedSubCategoryId = v!),
                            ),
                            12.height,
                          ],
                        ),
                      _SectionLabel('Menu Order'),
                      _InputField(controller: _menuOrderCtrl, hint: '0'),
                      12.height,
                      Row(
                        children: [
                          Checkbox(
                              value: _isSelected,
                              activeColor: sh_colorPrimary,
                              onChanged: (v) =>
                                  setState(() => _isSelected = v!)),
                          Text("Is Selected",
                              style: GoogleFonts.workSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: sh_textColorPrimary)),
                        ],
                      ),
                      12.height,
                      _SectionLabel('Category Image'),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildImagePreview(),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _InputField(
                                controller: _imageCtrl,
                                hint: 'Image URL',
                                onChanged: (v) => setState(() {})),
                          ),
                          8.width,
                          Container(
                            decoration: BoxDecoration(
                                color: sh_colorPrimary,
                                borderRadius: BorderRadius.circular(8)),
                            child: IconButton(
                              icon:
                                  const Icon(Icons.upload, color: Colors.white),
                              onPressed: _pickAndUploadImage,
                            ),
                          )
                        ],
                      ),
                      24.height,
                      Row(children: [
                        Expanded(
                            child: _PillButton(
                                label: 'Save',
                                bgColor: sh_colorPrimary,
                                onTap: _saveCategory)),
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

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  const _InputField(
      {Key? key,
      required this.controller,
      required this.hint,
      this.maxLines = 1,
      this.onChanged})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
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

class _DropdownField<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final List<String>? itemLabels;
  final List<String?>? itemImages;
  final ValueChanged<T?> onChanged;
  const _DropdownField(
      {Key? key,
      required this.value,
      required this.items,
      this.itemLabels,
      this.itemImages,
      required this.onChanged})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      items: List.generate(items.length, (index) {
        return DropdownMenuItem<T>(
          value: items[index],
          child: Row(
            children: [
              if (itemImages != null &&
                  index < itemImages!.length &&
                  itemImages![index] != null &&
                  itemImages![index]!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: itemImages![index]!.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: itemImages![index]!,
                          width: 24,
                          height: 24,
                          fit: BoxFit.cover,
                          memCacheWidth: 50,
                          memCacheHeight: 50,
                          placeholder: (_, __) => Container(
                              color: Colors.grey[200], width: 24, height: 24),
                          errorWidget: (_, __, ___) =>
                              const Icon(Icons.image, size: 24),
                        )
                      : Image.asset(
                          itemImages![index]!,
                          width: 24,
                          height: 24,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.image, size: 24),
                        ),
                ),
                8.width,
              ],
              Text(
                itemLabels != null
                    ? itemLabels![index]
                    : items[index].toString(),
                style: GoogleFonts.workSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: sh_textColorPrimary,
                ),
              ),
            ],
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
