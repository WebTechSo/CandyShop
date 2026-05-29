import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:american_sweets/models/AmBrand.dart';
import 'package:american_sweets/firebase_options.dart';
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/utils/AmConstant.dart';
import 'package:american_sweets/utils/AmStrings.dart';
import 'package:american_sweets/screens/AmHomeScreen.dart';
import 'package:american_sweets/screens/AdminDashboardScreen.dart';
import 'package:american_sweets/screens/OrderManagementScreen.dart';
import 'package:american_sweets/screens/ProductManagementScreen.dart';
import 'package:american_sweets/screens/CustomerManagementScreen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AddBrandScreen extends StatefulWidget {
  final AmBrand? brand;

  const AddBrandScreen({Key? key, this.brand}) : super(key: key);

  @override
  State<AddBrandScreen> createState() => _AddBrandScreenState();
}

class _AddBrandScreenState extends State<AddBrandScreen> {
  int _currentTab = 3; // Default to Product/Category tab
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  final _slugCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  final _menuOrderCtrl = TextEditingController(text: '0');
  bool _isSelected = false;
  bool _isSlugEdited = false;
  int _selectedParentId = 0;
  List<AmBrand> brandList = [];

  final ImagePicker _picker = ImagePicker();
  UploadTask? uploadTask;

  @override
  void initState() {
    super.initState();
    _fetchBrands();
    if (widget.brand != null) {
      _nameCtrl.text = widget.brand!.name ?? '';
      _descCtrl.text = widget.brand!.description ?? '';
      _idCtrl.text = widget.brand!.id?.toString() ?? '';
      _selectedParentId = widget.brand!.parent ?? 0;
      _slugCtrl.text = widget.brand!.slug ?? '';
      _imageCtrl.text = widget.brand!.image ?? '';

      if (_imageCtrl.text.startsWith('gs://')) {
        _resolveGsUrl(_imageCtrl.text);
      }

      _menuOrderCtrl.text = widget.brand!.menu_order?.toString() ?? '0';
      _isSelected = widget.brand!.isSelected ?? false;
      _isSlugEdited =
          true; // Don't auto-update slug when editing existing brand
    }
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

  Future<void> _fetchBrands() async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance.collection('Brands').get();
      List<AmBrand> loaded =
          snapshot.docs.map((doc) => AmBrand.fromSnapshot(doc)).toList();

      // Auto-calculate next ID for new brands
      if (widget.brand == null) {
        int maxId = 0;
        for (var b in loaded) {
          if ((b.id ?? 0) > maxId) {
            maxId = b.id!;
          }
        }
        _idCtrl.text = (maxId + 1).toString();
      }

      // If editing, remove self from parent options to avoid cycles
      if (widget.brand != null) {
        loaded.removeWhere((b) => b.id == widget.brand!.id);
      }

      setState(() {
        brandList = loaded;
      });
    } catch (e) {
      toast('Error fetching brands: $e');
    }
  }

  Uint8List? pickedFileBytes;
  String? pickedFilePath;

  Future<String> _uploadBrandImage(Uint8List bytes, String path,
      {String? contentType}) async {
    final meta = SettableMetadata(contentType: contentType);
    final opts = DefaultFirebaseOptions.currentPlatform;
    final rawBucket = (opts.storageBucket ?? '').trim();
    final candidates = <FirebaseStorage>[
      FirebaseStorage.instance,
      if (rawBucket.isNotEmpty)
        FirebaseStorage.instanceFor(
            bucket:
                rawBucket.replaceAll('.firebasestorage.app', '.appspot.com')),
    ];

    Object? last;
    for (final storage in candidates) {
      final ref = storage.ref().child(path);
      try {
        await ref.putData(bytes, meta);
        try {
          return await ref.getDownloadURL();
        } on FirebaseException {
          return 'gs://${ref.bucket}/${ref.fullPath}';
        }
      } catch (e) {
        last = e;
      }
    }

    throw last ?? Exception('Upload failed');
  }

  Future<void> _pickAndUploadImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final bytes = await image.readAsBytes();
    final lower = image.name.toLowerCase();
    final contentType = lower.endsWith('.png')
        ? 'image/png'
        : (lower.endsWith('.webp')
            ? 'image/webp'
            : (lower.endsWith('.jpg') || lower.endsWith('.jpeg')
                ? 'image/jpeg'
                : 'image/*'));
    final path =
        'brands/${DateTime.now().millisecondsSinceEpoch}_${image.name}';

    // Show local preview immediately
    setState(() {
      pickedFileBytes = bytes;
      pickedFilePath = image.path;
    });

    try {
      // Create upload task and store it
      final storage = FirebaseStorage.instance;
      final opts = DefaultFirebaseOptions.currentPlatform;
      final rawBucket = (opts.storageBucket ?? '').trim();

      UploadTask? currentTask;
      final ref = storage.ref().child(path);

      // Start the upload and track progress
      final metadata = SettableMetadata(contentType: contentType);
      currentTask = ref.putData(bytes, metadata);

      setState(() {
        uploadTask = currentTask;
      });

      // Wait for upload to complete
      final snapshot = await currentTask;

      // Get download URL
      String url;
      try {
        url = await ref.getDownloadURL();
      } on FirebaseException {
        url = 'gs://${ref.bucket}/${ref.fullPath}';
      }

      setState(() {
        _imageCtrl.text = url;
        pickedFileBytes = null;
        pickedFilePath = null;
        uploadTask = null; // Clear upload task when done
      });
      toast('Upload successful');
    } on FirebaseException catch (e, st) {
      print(
          'Brand image upload failed [${e.plugin}/${e.code}]: ${e.message}\n$st');
      toast('Upload failed: [${e.plugin}/${e.code}] ${e.message ?? ''}');
      setState(() {
        pickedFileBytes = null;
        pickedFilePath = null;
        uploadTask = null;
      });
    } catch (e, st) {
      print('Brand image upload failed: $e\n$st');
      toast('Upload failed: $e');
      setState(() {
        pickedFileBytes = null;
        pickedFilePath = null;
        uploadTask = null;
      });
    }
  }

  Future<void> _saveBrand() async {
    if (!_formKey.currentState!.validate()) return;

    String cleanUrl = _imageCtrl.text
        .replaceAll('"', '')
        .replaceAll("'", '')
        .replaceAll('`', '')
        .trim();

    int commaIndex = cleanUrl.indexOf(',');
    if (commaIndex != -1) {
      cleanUrl = cleanUrl.substring(0, commaIndex).trim();
    }

    final newBrand = AmBrand(
      count: 0,
      description: _descCtrl.text,
      id: int.tryParse(_idCtrl.text) ?? 0,
      isSelected: _isSelected,
      menu_order: int.tryParse(_menuOrderCtrl.text) ?? 0,
      name: _nameCtrl.text,
      parent: _selectedParentId,
      slug: _slugCtrl.text.isEmpty
          ? _nameCtrl.text.toLowerCase().replaceAll(' ', '-')
          : _slugCtrl.text,
      image: cleanUrl,
    );

    try {
      if (widget.brand != null && widget.brand!.docId != null) {
        await FirebaseFirestore.instance
            .collection('Brands')
            .doc(widget.brand!.docId)
            .update(newBrand.toJson());
        toast('Brand updated successfully');
      } else {
        await FirebaseFirestore.instance
            .collection('Brands')
            .add(newBrand.toJson());
        toast('Brand created successfully');
      }
      finish(context);
    } catch (e) {
      toast('Error saving brand: $e');
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
    // Show upload progress if active
    if (uploadTask != null) {
      return StreamBuilder<TaskSnapshot>(
        stream: uploadTask!.snapshotEvents,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final data = snapshot.data!;
            double progress = data.bytesTransferred / data.totalBytes;
            return Container(
              height: 150,
              width: double.infinity,
              color: Colors.grey[200],
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(sh_colorPrimary),
                  ),
                  12.height,
                  Text(
                    'Uploading... ${(progress * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.workSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: sh_textColorSecondary,
                    ),
                  ),
                ],
              ),
            );
          }
          return Container(
            height: 150,
            width: double.infinity,
            color: Colors.grey[200],
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(sh_colorPrimary),
                ),
                12.height,
                Text(
                  'Preparing upload...',
                  style: GoogleFonts.workSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: sh_textColorSecondary,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    // Show local file preview if picked (but still uploading - handled above)
    if (pickedFileBytes != null && uploadTask == null) {
      return Image.memory(
        pickedFileBytes!,
        height: 150,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }

    String url = _imageCtrl.text
        .replaceAll('"', '')
        .replaceAll("'", '')
        .replaceAll('`', '')
        .trim();

    if (url.contains(',')) {
      url = url.split(',').first.trim();
    }

    if (url.isEmpty) {
      return _buildAssetFallback();
    }

    if (url.startsWith('gs://')) {
      return FutureBuilder<String>(
        future: FirebaseStorage.instance.refFromURL(url).getDownloadURL(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return CachedNetworkImage(
              imageUrl: snapshot.data!,
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
          if (snapshot.hasError) return _buildAssetFallback();
          return Container(
            height: 150,
            color: Colors.grey[200],
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          );
        },
      );
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
    List<int> parentIds = [0];
    List<String> parentNames = ['Root'];
    for (var b in brandList) {
      if (b.id != null) {
        parentIds.add(b.id!);
        parentNames.add(b.name ?? 'Unknown');
      }
    }

    if (!parentIds.contains(_selectedParentId)) {
      _selectedParentId = 0;
    }

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
                  Text(widget.brand != null ? 'Edit Brand' : 'Add Brand',
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
                      _SectionLabel('Brand Name'),
                      _InputField(
                          controller: _nameCtrl,
                          hint: 'e.g., Nike',
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
                      _SectionLabel('Brand ID'),
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
                          hint: 'Describe the brand...',
                          maxLines: 3),
                      12.height,
                      _SectionLabel('Parent Brand'),
                      _DropdownField<int>(
                        value: _selectedParentId,
                        items: parentIds,
                        itemLabels: parentNames,
                        onChanged: (v) =>
                            setState(() => _selectedParentId = v!),
                      ),
                      12.height,
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
                      _SectionLabel('Brand Image'),
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
                                onTap: _saveBrand)),
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
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: List.generate(items.length, (index) {
        return DropdownMenuItem<T>(
          value: items[index],
          child: Text(
            itemLabels != null ? itemLabels![index] : items[index].toString(),
            style: GoogleFonts.workSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: sh_textColorPrimary),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}
