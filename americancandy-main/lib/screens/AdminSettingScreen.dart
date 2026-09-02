import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/utils/AmConstant.dart';
import 'package:file_picker/file_picker.dart';
import 'package:american_sweets/utils/StorageUpload.dart';
import 'package:country_state_city/country_state_city.dart' as csc;

class AdminSettingScreen extends StatefulWidget {
  const AdminSettingScreen({Key? key}) : super(key: key);
  @override
  State<AdminSettingScreen> createState() => _AdminSettingScreenState();
}

class _AdminSettingScreenState extends State<AdminSettingScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _appNameController = TextEditingController();
  final TextEditingController _vatRateController = TextEditingController();
  final TextEditingController _contactNumberController =
      TextEditingController();
  bool _vatEnable = false;
  bool _loading = true;
  bool _saving = false;
  final TextEditingController _sizeController = TextEditingController();
  final TextEditingController _flavorController = TextEditingController();
  final TextEditingController _packagingController = TextEditingController();
  TextEditingController? _countryAutocompleteController;
  List<String> _sizes = [];
  List<String> _flavors = [];
  List<String> _packagings = [];
  List<String> _countries = [];
  String _defaultCountry = '';
  List<csc.Country> _allCountries = [];

  // Offer section controllers
  final TextEditingController _offerFirstNameCtrl =
      TextEditingController(); // first_name_logo
  final TextEditingController _offerLastNameCtrl =
      TextEditingController(); // last_name_logo
  final TextEditingController _offerTitleCtrl =
      TextEditingController(); // offer_title
  final TextEditingController _offerSubtitleCtrl =
      TextEditingController(); // offer_subtitle
  final TextEditingController _offerDetailsCtrl =
      TextEditingController(); // offer_details
  final TextEditingController _offerButtonCtrl =
      TextEditingController(); // offer_button
  String _offerRoute = 'products'; // offer_route
  String _offerBackgroundUrl = ''; // offer_background
  bool _uploadingOfferBg = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      try {
        _allCountries = await csc.getAllCountries();
      } catch (_) {
        _allCountries = [];
      }

      final doc = await _firestore
          .collection('admin_setting')
          .doc('vw0U6xyVtJRKsL2b7F57')
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _appNameController.text = (data['app_name'] ?? '').toString();
        _vatEnable = (data['vat_enable'] ?? false) == true;
        _vatRateController.text = (data['vat_rate'] ?? '').toString();
        _contactNumberController.text =
            (data['contact_number'] ?? '').toString();
        _defaultCountry = (data['default_country'] ?? '').toString();

        // Offer section
        _offerBackgroundUrl = (data['offer_background'] ?? '').toString();
        _offerFirstNameCtrl.text =
            (data['first_name_logo'] ?? 'American').toString();
        _offerLastNameCtrl.text =
            (data['last_name_logo'] ?? 'Sweets').toString();
        _offerTitleCtrl.text =
            (data['offer_title'] ?? 'Spend £39.99 & Get\nFree UK Shipping')
                .toString();
        _offerSubtitleCtrl.text =
            (data['offer_subtitle'] ?? 'Perfect Time to Stock Up').toString();
        _offerDetailsCtrl.text = (data['offer_details'] ??
                'Most customers add 2–3 favourites to unlock free delivery.')
            .toString();
        _offerButtonCtrl.text =
            (data['offer_button'] ?? 'Unlock Free Shipping').toString();
        _offerRoute = (data['offer_route'] ?? 'products').toString();

        final rawSizes = data['variant_sizes'];
        if (rawSizes is List) {
          _sizes = rawSizes.map((e) => e.toString()).toList();
        } else if (rawSizes is Map) {
          _sizes = rawSizes.values.map((e) => e.toString()).toList();
        } else {
          _sizes = [];
        }

        final rawFlavors = data['variant_flavors'];
        if (rawFlavors is List) {
          _flavors = rawFlavors.map((e) => e.toString()).toList();
        } else if (rawFlavors is Map) {
          _flavors = rawFlavors.values.map((e) => e.toString()).toList();
        } else {
          _flavors = [];
        }

        final rawPackagings = data['variant_packagings'];
        if (rawPackagings is List) {
          _packagings = rawPackagings.map((e) => e.toString()).toList();
        } else if (rawPackagings is Map) {
          _packagings = rawPackagings.values.map((e) => e.toString()).toList();
        } else {
          _packagings = [];
        }

        final rawCountries = data['variant_countries'];
        if (rawCountries is List) {
          _countries = rawCountries.map((e) => e.toString()).toList();
        } else if (rawCountries is Map) {
          _countries = rawCountries.values.map((e) => e.toString()).toList();
        } else {
          _countries = [];
        }

        if (_allCountries.isNotEmpty && _countries.isNotEmpty) {
          final byIso = <String, csc.Country>{
            for (final c in _allCountries) c.isoCode.toUpperCase(): c,
          };
          final byName = <String, csc.Country>{
            for (final c in _allCountries) c.name.toLowerCase(): c,
          };
          final normalized = <String>[];
          for (final raw in _countries) {
            final s = raw.toString().trim();
            if (s.isEmpty) continue;
            final upper = s.toUpperCase();
            if (upper == 'UK') {
              normalized.add('United Kingdom');
              continue;
            }
            if (upper == 'USA') {
              normalized.add('United States');
              continue;
            }
            final hit = byIso[upper] ?? byName[s.toLowerCase()];
            normalized.add(hit?.name ?? s);
          }
          _countries = normalized.toSet().toList();
        }

        if (_defaultCountry.trim().isEmpty && _countries.isNotEmpty) {
          _defaultCountry = _countries.first;
        } else if (_defaultCountry.trim().isNotEmpty &&
            _countries.isNotEmpty &&
            !_countries.contains(_defaultCountry)) {
          _defaultCountry = _countries.first;
        }
      }
    } catch (e) {
      toast('Error loading settings: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    final appName = _appNameController.text.trim();
    if (appName.isEmpty) {
      toast('Enter App Name');
      return;
    }
    final rateText = _vatRateController.text.trim();
    final rate = double.tryParse(rateText);
    if (rate == null) {
      toast('Enter valid VAT rate');
      return;
    }
    setState(() {
      _saving = true;
    });
    try {
      _countries = _countries
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
      if (_countries.isNotEmpty && !_countries.contains(_defaultCountry)) {
        _defaultCountry = _countries.first;
      }
      await _firestore
          .collection('admin_setting')
          .doc('vw0U6xyVtJRKsL2b7F57')
          .set({
        'app_name': appName,
        'vat_enable': _vatEnable,
        'vat_rate': rate,
        'contact_number': _contactNumberController.text.trim(),
        'variant_sizes': _sizes,
        'variant_flavors': _flavors,
        'variant_packagings': _packagings,
        'variant_countries': _countries,
        if (_defaultCountry.trim().isNotEmpty)
          'default_country': _defaultCountry.trim(),
        // Offer section fields
        'offer_background': _offerBackgroundUrl,
        'first_name_logo': _offerFirstNameCtrl.text.trim(),
        'last_name_logo': _offerLastNameCtrl.text.trim(),
        'offer_title': _offerTitleCtrl.text.trim(),
        'offer_subtitle': _offerSubtitleCtrl.text.trim(),
        'offer_details': _offerDetailsCtrl.text.trim(),
        'offer_button': _offerButtonCtrl.text.trim(),
        'offer_route': _offerRoute,
      }, SetOptions(merge: true));
      toast('Settings saved');
    } catch (e) {
      toast('Error saving settings: $e');
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _appNameController.dispose();
    _vatRateController.dispose();
    _contactNumberController.dispose();
    _sizeController.dispose();
    _flavorController.dispose();
    _packagingController.dispose();
    _offerFirstNameCtrl.dispose();
    _offerLastNameCtrl.dispose();
    _offerTitleCtrl.dispose();
    _offerSubtitleCtrl.dispose();
    _offerDetailsCtrl.dispose();
    _offerButtonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickOfferBackground() async {
    try {
      final result = await FilePicker.platform.pickFiles(withData: true);
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.bytes == null) {
        toast('Unable to read file bytes');
        return;
      }
      setState(() => _uploadingOfferBg = true);
      final fileName =
          'offers/${DateTime.now().millisecondsSinceEpoch}_${file.name.replaceAll(' ', '_')}';
      final contentType = file.extension != null
          ? 'image/${file.extension}'
          : 'application/octet-stream';
      final url = await StorageUpload.uploadBytes(file.bytes!, fileName,
          contentType: contentType);
      setState(() {
        _offerBackgroundUrl = url;
        _uploadingOfferBg = false;
      });
      toast('Background updated');
    } catch (e) {
      setState(() => _uploadingOfferBg = false);
      toast('Upload failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: sh_background_color,
      appBar: AppBar(
        title: Text('Admin Settings',
            style: GoogleFonts.workSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: sh_textColorPrimary)),
        backgroundColor: sh_white,
        iconTheme: const IconThemeData(color: sh_textColorPrimary),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.only(
                left: spacing_standard_new,
                right: spacing_standard_new,
                top: spacing_standard_new,
                bottom: spacing_standard_new +
                    MediaQuery.of(context).padding.bottom +
                    16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('App Name',
                      style: GoogleFonts.workSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: sh_textColorPrimary)),
                  8.height,
                  TextFormField(
                    controller: _appNameController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: sh_view_color)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: sh_view_color)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                    style: GoogleFonts.workSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: sh_textColorPrimary),
                  ),
                  16.height,
                  Text('Contact Number (WhatsApp)',
                      style: GoogleFonts.workSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: sh_textColorPrimary)),
                  8.height,
                  TextFormField(
                    controller: _contactNumberController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: sh_view_color)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: sh_view_color)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                    style: GoogleFonts.workSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: sh_textColorPrimary),
                  ),
                  16.height,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text('Enable VAT',
                            style: GoogleFonts.workSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: sh_textColorPrimary)),
                      ),
                      Switch(
                        value: _vatEnable,
                        activeColor: sh_colorPrimary,
                        onChanged: (v) {
                          setState(() {
                            _vatEnable = v;
                          });
                        },
                      ),
                    ],
                  ),
                  16.height,
                  Text('VAT Rate (%)',
                      style: GoogleFonts.workSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: sh_textColorPrimary)),
                  8.height,
                  TextFormField(
                    controller: _vatRateController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: sh_view_color)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: sh_view_color)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                    style: GoogleFonts.workSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: sh_textColorPrimary),
                  ),
                  24.height,
                  Text('Variant Values',
                      style: GoogleFonts.workSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: sh_textColorPrimary)),
                  16.height,
                  _buildVariantSection(
                    label: 'Size',
                    controller: _sizeController,
                    items: _sizes,
                    onAdd: () {
                      final text = _sizeController.text.trim();
                      if (text.isEmpty) return;
                      setState(() {
                        if (!_sizes.contains(text)) _sizes.add(text);
                        _sizeController.clear();
                      });
                    },
                    onRemove: (value) {
                      setState(() {
                        _sizes.remove(value);
                      });
                    },
                  ),
                  12.height,
                  _buildVariantSection(
                    label: 'Flavor',
                    controller: _flavorController,
                    items: _flavors,
                    onAdd: () {
                      final text = _flavorController.text.trim();
                      if (text.isEmpty) return;
                      setState(() {
                        if (!_flavors.contains(text)) _flavors.add(text);
                        _flavorController.clear();
                      });
                    },
                    onRemove: (value) {
                      setState(() {
                        _flavors.remove(value);
                      });
                    },
                  ),
                  12.height,
                  _buildVariantSection(
                    label: 'Packaging',
                    controller: _packagingController,
                    items: _packagings,
                    onAdd: () {
                      final text = _packagingController.text.trim();
                      if (text.isEmpty) return;
                      setState(() {
                        if (!_packagings.contains(text)) _packagings.add(text);
                        _packagingController.clear();
                      });
                    },
                    onRemove: (value) {
                      setState(() {
                        _packagings.remove(value);
                      });
                    },
                  ),
                  12.height,
                  _buildCountryVariantSection(),
                  12.height,
                  if (_countries.isNotEmpty)
                    Text('Default Country',
                        style: GoogleFonts.workSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: sh_textColorPrimary)),
                  8.height,
                  if (_countries.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value: _countries.contains(_defaultCountry)
                          ? _defaultCountry
                          : _countries.first,
                      items: _countries
                          .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setState(() {
                        _defaultCountry = v ?? _defaultCountry;
                      }),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide(color: sh_view_color)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide(color: sh_view_color)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        hintText: 'Default Country',
                      ),
                    ),
                  24.height,
                  Text('Offer Section',
                      style: GoogleFonts.workSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: sh_textColorPrimary)),
                  12.height,
                  // Background image picker and preview
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: sh_view_color),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Offer Background',
                            style: GoogleFonts.workSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: sh_textColorPrimary)),
                        8.height,
                        if (_offerBackgroundUrl.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _offerBackgroundUrl,
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 120,
                                color: sh_view_color,
                                alignment: Alignment.center,
                                child: Icon(Icons.broken_image),
                              ),
                            ),
                          ),
                        8.height,
                        AppButton(
                          text: _uploadingOfferBg
                              ? 'Uploading...'
                              : 'Change Background',
                          color: sh_colorPrimary,
                          textColor: white,
                          onTap:
                              _uploadingOfferBg ? null : _pickOfferBackground,
                        ),
                      ],
                    ),
                  ),
                  12.height,
                  _buildTextField('Slogan of App', _offerFirstNameCtrl),
                  12.height,
                  _buildTextField('Offer Title', _offerTitleCtrl, maxLines: 2),
                  12.height,
                  _buildTextField('Offer Subtitle', _offerSubtitleCtrl),
                  12.height,
                  _buildTextField('Offer Details', _offerDetailsCtrl,
                      maxLines: 3),
                  12.height,
                  _buildTextField('Button Text', _offerButtonCtrl),
                  12.height,
                  DropdownButtonFormField<String>(
                    value: _offerRoute,
                    items: const [
                      DropdownMenuItem(
                          value: 'products', child: Text('Products')),
                    ],
                    onChanged: (v) {
                      setState(() {
                        _offerRoute = v ?? 'products';
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Button Route',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: sh_view_color)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: sh_view_color)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                  ),
                  24.height,
                  24.height,
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: sh_colorPrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white)),
                            )
                          : Text('Save Settings',
                              style: GoogleFonts.workSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: sh_white)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildVariantSection({
    required String label,
    required TextEditingController controller,
    required List<String> items,
    required VoidCallback onAdd,
    required ValueChanged<String> onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.workSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: sh_textColorPrimary)),
        8.height,
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: sh_view_color)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: sh_view_color)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  hintText: 'Add $label',
                ),
                style: GoogleFonts.workSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: sh_textColorPrimary),
              ),
            ),
            8.width,
            IconButton(
              icon: const Icon(Icons.add_circle, color: sh_colorPrimary),
              onPressed: onAdd,
            ),
          ],
        ),
        8.height,
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items
              .map(
                (e) => Chip(
                  label: Text(e,
                      style: GoogleFonts.workSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: sh_textColorPrimary)),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => onRemove(e),
                  backgroundColor: sh_white,
                  shape: StadiumBorder(side: BorderSide(color: sh_view_color)),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildCountryVariantSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Country',
            style: GoogleFonts.workSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: sh_textColorPrimary)),
        8.height,
        Row(
          children: [
            Expanded(
              child: Autocomplete<csc.Country>(
                optionsBuilder: (value) {
                  final q = value.text.trim().toLowerCase();
                  if (q.isEmpty) return const Iterable<csc.Country>.empty();
                  final list = _allCountries;
                  return list.where((c) {
                    final n = c.name.toLowerCase();
                    final iso = c.isoCode.toLowerCase();
                    return n.contains(q) || iso.startsWith(q);
                  }).take(20);
                },
                displayStringForOption: (c) => '${c.name} (${c.isoCode})',
                onSelected: (c) {
                  _countryAutocompleteController?.text = c.name;
                },
                fieldViewBuilder:
                    (context, textEditingController, focusNode, onSubmit) {
                  _countryAutocompleteController = textEditingController;
                  return TextFormField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: sh_view_color)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: sh_view_color)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      hintText: 'Add Country',
                    ),
                    style: GoogleFonts.workSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: sh_textColorPrimary),
                  );
                },
              ),
            ),
            8.width,
            IconButton(
              icon: const Icon(Icons.add_circle, color: sh_colorPrimary),
              onPressed: () {
                final raw = (_countryAutocompleteController?.text ?? '').trim();
                if (raw.isEmpty) return;
                final match = _allCountries.firstWhere(
                  (c) =>
                      c.name.toLowerCase() == raw.toLowerCase() ||
                      c.isoCode.toLowerCase() == raw.toLowerCase(),
                  orElse: () => csc.Country(
                      name: '',
                      isoCode: '',
                      phoneCode: '',
                      flag: '',
                      currency: '',
                      latitude: '',
                      longitude: '',
                      timezones: const []),
                );
                if (match.name.isEmpty) {
                  toast('Select a valid country from suggestions');
                  return;
                }
                setState(() {
                  if (!_countries.contains(match.name))
                    _countries.add(match.name);
                  if (_defaultCountry.trim().isEmpty) {
                    _defaultCountry = match.name;
                  }
                  _countryAutocompleteController?.clear();
                });
              },
            ),
          ],
        ),
        8.height,
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _countries
              .map(
                (e) => Chip(
                  label: Text(e,
                      style: GoogleFonts.workSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: sh_textColorPrimary)),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    setState(() {
                      _countries.remove(e);
                      if (_defaultCountry == e) {
                        _defaultCountry =
                            _countries.isNotEmpty ? _countries.first : '';
                      }
                    });
                  },
                  backgroundColor: sh_white,
                  shape: StadiumBorder(side: BorderSide(color: sh_view_color)),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {int maxLines = 1, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.workSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: sh_textColorPrimary)),
        8.height,
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: sh_view_color)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: sh_view_color)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          style: GoogleFonts.workSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: sh_textColorPrimary),
        ),
      ],
    );
  }
}
