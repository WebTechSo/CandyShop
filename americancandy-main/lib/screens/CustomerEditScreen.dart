import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/utils/AmConstant.dart';
import 'package:american_sweets/data/services/AdminCountryService.dart';
import 'package:country_state_city/country_state_city.dart' as csc;
import '../main.dart';

class CustomerEditScreen extends StatefulWidget {
  final String initialName;
  final String initialEmail;

  const CustomerEditScreen({
    super.key,
    required this.initialName,
    required this.initialEmail,
  });

  @override
  State<CustomerEditScreen> createState() => _CustomerEditScreenState();
}

class _CustomerEditScreenState extends State<CustomerEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameCtrl = TextEditingController();
  final _countryRegCtrl = ValueNotifier<String>('United Kingdom');
  final _regNumberCtrl = TextEditingController();
  final _vatNumberCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _billAddress1Ctrl = TextEditingController();
  final _billAddress2Ctrl = TextEditingController();
  final _billCityCtrl = TextEditingController();
  final _billStateCtrl = TextEditingController();
  final _billZipCtrl = TextEditingController();
  final _billCountryCtrl = ValueNotifier<String>('United Kingdom');
  final _delAddress1Ctrl = TextEditingController();
  final _delAddress2Ctrl = TextEditingController();
  final _delCityCtrl = TextEditingController();
  final _delStateCtrl = TextEditingController();
  final _delZipCtrl = TextEditingController();
  final _delCountryCtrl = ValueNotifier<String>('United Kingdom');

  List<csc.Country> _variantCountries = [];
  List<csc.State> _billStates = [];
  List<csc.State> _delStates = [];
  String _phonePrefix = '';
  bool _sameAsBilling = false;

  String _status = 'active';
  bool _saving = false;
  String? _userDocId;

  @override
  void initState() {
    super.initState();
    _fullNameCtrl.text = widget.initialName;
    _emailCtrl.text = widget.initialEmail;
    _billAddress1Ctrl.addListener(_updateDeliveryAddress);
    _billAddress2Ctrl.addListener(_updateDeliveryAddress);
    _billCityCtrl.addListener(_updateDeliveryAddress);
    _billStateCtrl.addListener(_updateDeliveryAddress);
    _billZipCtrl.addListener(_updateDeliveryAddress);
    _billCountryCtrl.addListener(_updateDeliveryAddress);
    _loadVariantCountries();
    _loadUserDoc();
  }

  @override
  void dispose() {
    _billAddress1Ctrl.removeListener(_updateDeliveryAddress);
    _billAddress2Ctrl.removeListener(_updateDeliveryAddress);
    _billCityCtrl.removeListener(_updateDeliveryAddress);
    _billStateCtrl.removeListener(_updateDeliveryAddress);
    _billZipCtrl.removeListener(_updateDeliveryAddress);
    _billCountryCtrl.removeListener(_updateDeliveryAddress);

    _businessNameCtrl.dispose();
    _countryRegCtrl.dispose();
    _regNumberCtrl.dispose();
    _vatNumberCtrl.dispose();
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _billAddress1Ctrl.dispose();
    _billAddress2Ctrl.dispose();
    _billCityCtrl.dispose();
    _billStateCtrl.dispose();
    _billZipCtrl.dispose();
    _billCountryCtrl.dispose();
    _delAddress1Ctrl.dispose();
    _delAddress2Ctrl.dispose();
    _delCityCtrl.dispose();
    _delStateCtrl.dispose();
    _delZipCtrl.dispose();
    _delCountryCtrl.dispose();
    super.dispose();
  }

  void _updateDeliveryAddress() {
    if (_sameAsBilling) {
      _delAddress1Ctrl.text = _billAddress1Ctrl.text;
      _delAddress2Ctrl.text = _billAddress2Ctrl.text;
      _delCityCtrl.text = _billCityCtrl.text;
      _delStateCtrl.text = _billStateCtrl.text;
      _delZipCtrl.text = _billZipCtrl.text;
      _delCountryCtrl.value = _billCountryCtrl.value;
    }
  }

  String _countryIsoFromName(String name) {
    final n = name.trim().toLowerCase();
    for (final c in _variantCountries) {
      if (c.name.toLowerCase() == n) return c.isoCode;
      if (c.isoCode.toLowerCase() == n) return c.isoCode;
    }
    return '';
  }

  void _updatePhonePrefix(String countryNameOrIso) {
    final iso = _countryIsoFromName(countryNameOrIso);
    for (final c in _variantCountries) {
      if (c.isoCode.toUpperCase() == iso.toUpperCase()) {
        final code = c.phoneCode.toString().trim();
        setState(() => _phonePrefix = code.isNotEmpty ? '+$code' : '');
        return;
      }
    }
    setState(() => _phonePrefix = '');
  }

  Future<void> _loadBillStates() async {
    final iso = _countryIsoFromName(_billCountryCtrl.value);
    if (iso.isEmpty) {
      if (mounted) setState(() => _billStates = []);
      return;
    }
    final states =
        await AdminCountryService.instance.getStatesForCountryIso(iso);
    if (!mounted) return;
    setState(() => _billStates = states);
  }

  Future<void> _loadDelStates() async {
    final iso = _countryIsoFromName(_delCountryCtrl.value);
    if (iso.isEmpty) {
      if (mounted) setState(() => _delStates = []);
      return;
    }
    final states =
        await AdminCountryService.instance.getStatesForCountryIso(iso);
    if (!mounted) return;
    setState(() => _delStates = states);
  }

  Future<void> _loadVariantCountries() async {
    try {
      final list = await AdminCountryService.instance.getAllowedCountries();
      if (!mounted) return;
      setState(() {
        _variantCountries = list;
        final names = _variantCountries.map((e) => e.name).toList();
        if (names.isNotEmpty) {
          if (!names.contains(_countryRegCtrl.value)) {
            _countryRegCtrl.value = names.first;
          }
          if (!names.contains(_billCountryCtrl.value)) {
            _billCountryCtrl.value = names.first;
          }
          if (!names.contains(_delCountryCtrl.value)) {
            _delCountryCtrl.value = names.first;
          }
        }
      });
      _updatePhonePrefix(_billCountryCtrl.value);
      await _loadBillStates();
      await _loadDelStates();
    } catch (e) {
      print('Failed to load variant_countries: $e');
    }
  }

  Future<void> _loadUserDoc() async {
    try {
      final qs = await FirebaseFirestore.instance
          .collection('Users')
          .where('email', isEqualTo: widget.initialEmail)
          .limit(1)
          .get();
      if (qs.docs.isEmpty) return;
      final doc = qs.docs.first;
      final data = doc.data();
      if (!mounted) return;
      final billing = data['billing_address'] is Map
          ? data['billing_address'] as Map<String, dynamic>
          : <String, dynamic>{};
      final delivery = data['delivery_address'] is Map
          ? data['delivery_address'] as Map<String, dynamic>
          : <String, dynamic>{};
      setState(() {
        _userDocId = doc.id;
        _businessNameCtrl.text = (data['business_name'] ?? '').toString();
        _countryRegCtrl.value =
            (data['registration_country'] ?? _countryRegCtrl.value).toString();
        _regNumberCtrl.text = (data['registration_number'] ?? '').toString();
        _vatNumberCtrl.text = (data['vat_number'] ?? '').toString();

        _fullNameCtrl.text = (data['full_name'] ??
                data['fullName'] ??
                data['name'] ??
                widget.initialName)
            .toString();
        _emailCtrl.text = (data['email'] ?? widget.initialEmail).toString();
        _phoneCtrl.text = (data['phone'] ?? '').toString();

        _billAddress1Ctrl.text = (billing['address1'] ?? '').toString();
        _billAddress2Ctrl.text = (billing['address2'] ?? '').toString();
        _billCityCtrl.text = (billing['city'] ?? '').toString();
        _billStateCtrl.text = (billing['state'] ?? '').toString();
        _billZipCtrl.text = (billing['zip'] ?? '').toString();
        _billCountryCtrl.value =
            (billing['country'] ?? _billCountryCtrl.value).toString();

        _delAddress1Ctrl.text = (delivery['address1'] ?? '').toString();
        _delAddress2Ctrl.text = (delivery['address2'] ?? '').toString();
        _delCityCtrl.text = (delivery['city'] ?? '').toString();
        _delStateCtrl.text = (delivery['state'] ?? '').toString();
        _delZipCtrl.text = (delivery['zip'] ?? '').toString();
        _delCountryCtrl.value =
            (delivery['country'] ?? _delCountryCtrl.value).toString();

        _status = (data['status'] ?? 'active').toString();
      });
    } catch (e) {
      if (!mounted) return;
      toast(e.toString());
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_saving) return;
    if (_userDocId == null) {
      toast('Customer record not found');
      return;
    }
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('Users').doc(_userDocId).set({
        'business_name': _businessNameCtrl.text.trim(),
        'registration_country': _countryRegCtrl.value,
        'registration_number': _regNumberCtrl.text.trim(),
        'vat_number': _vatNumberCtrl.text.trim(),
        'full_name': _fullNameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'billing_address': {
          'address1': _billAddress1Ctrl.text.trim(),
          'address2': _billAddress2Ctrl.text.trim(),
          'city': _billCityCtrl.text.trim(),
          'state': _billStateCtrl.text.trim(),
          'zip': _billZipCtrl.text.trim(),
          'country': _billCountryCtrl.value,
        },
        'delivery_address': {
          'address1': _delAddress1Ctrl.text.trim(),
          'address2': _delAddress2Ctrl.text.trim(),
          'city': _delCityCtrl.text.trim(),
          'state': _delStateCtrl.text.trim(),
          'zip': _delZipCtrl.text.trim(),
          'country': _delCountryCtrl.value,
        },
        'status': _status,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      finish(context, {
        'name': _fullNameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'status': _status,
      });
    } catch (e) {
      if (mounted) toast(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: sh_background_color,
      appBar: AppBar(
        title: Text('Edit Customer',
            style: GoogleFonts.workSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: sh_textColorPrimary)),
        iconTheme: IconThemeData(
            color: appStore.isDarkModeOn ? white : sh_textColorPrimary),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('Save',
                    style: GoogleFonts.workSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: sh_colorPrimary)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(spacing_standard_new),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('BUSINESS DETAILS',
                  style: GoogleFonts.workSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: sh_textColorSecondary)),
              8.height,
              _CRInputField(
                  controller: _businessNameCtrl, hint: 'Business Name *'),
              10.height,
              _CRDropdownField(
                label: 'Country of Registration *',
                valueListenable: _countryRegCtrl,
                items: _variantCountries.isNotEmpty
                    ? _variantCountries.map((e) => e.name).toList()
                    : const [
                        'United Kingdom',
                        'United States',
                        'Canada',
                        'Germany',
                        'France'
                      ],
              ),
              10.height,
              _CRInputField(
                  controller: _regNumberCtrl, hint: 'Registration Number'),
              10.height,
              _CRInputField(controller: _vatNumberCtrl, hint: 'VAT Number'),
              16.height,
              Text('CONTACT DETAILS',
                  style: GoogleFonts.workSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: sh_textColorSecondary)),
              8.height,
              _CRInputField(controller: _fullNameCtrl, hint: 'Full Name *'),
              10.height,
              _CRInputField(controller: _emailCtrl, hint: 'Email *'),
              10.height,
              _CRInputField(
                  controller: _phoneCtrl,
                  hint: 'Contact Telephone Number *',
                  prefixText:
                      _phonePrefix.isNotEmpty ? '$_phonePrefix ' : null),
              16.height,
              Text('BILLING ADDRESS',
                  style: GoogleFonts.workSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: sh_textColorSecondary)),
              8.height,
              _CRInputField(controller: _billAddress1Ctrl, hint: 'Address 1 *'),
              10.height,
              _CRInputField(controller: _billAddress2Ctrl, hint: 'Address 2'),
              10.height,
              _CRInputField(controller: _billCityCtrl, hint: 'City *'),
              10.height,
              if (_billStates.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _billStateCtrl.text.trim().isNotEmpty &&
                          _billStates.any((s) =>
                              s.name.toLowerCase() ==
                              _billStateCtrl.text.trim().toLowerCase())
                      ? _billStateCtrl.text.trim()
                      : null,
                  items: _billStates
                      .map((s) => DropdownMenuItem<String>(
                          value: s.name,
                          child: Text(s.name,
                              style: GoogleFonts.workSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: sh_textColorPrimary))))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _billStateCtrl.text = v ?? '';
                    });
                    _updateDeliveryAddress();
                  },
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'State *',
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
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                )
              else
                _CRInputField(controller: _billStateCtrl, hint: 'State *'),
              10.height,
              _CRInputField(controller: _billZipCtrl, hint: 'Zip Code *'),
              10.height,
              DropdownButtonFormField<String>(
                value: _billCountryCtrl.value,
                items: (_variantCountries.isNotEmpty
                        ? _variantCountries.map((e) => e.name).toList()
                        : const [
                            'United Kingdom',
                            'United States',
                            'Canada',
                            'Germany',
                            'France'
                          ])
                    .map((e) => DropdownMenuItem<String>(
                        value: e,
                        child: Text(e,
                            style: GoogleFonts.workSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: sh_textColorPrimary))))
                    .toList(),
                onChanged: (v) async {
                  final next = v ?? _billCountryCtrl.value;
                  setState(() => _billCountryCtrl.value = next);
                  _updatePhonePrefix(next);
                  await _loadBillStates();
                  if (_sameAsBilling) {
                    setState(() => _delCountryCtrl.value = next);
                    await _loadDelStates();
                  }
                },
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  return null;
                },
                decoration: InputDecoration(
                  hintText: 'Country *',
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
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
              16.height,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('DELIVERY ADDRESS',
                      style: GoogleFonts.workSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: sh_textColorSecondary)),
                  Row(
                    children: [
                      Checkbox(
                        value: _sameAsBilling,
                        activeColor: sh_colorPrimary,
                        onChanged: (val) {
                          setState(() {
                            _sameAsBilling = val ?? false;
                            _updateDeliveryAddress();
                          });
                        },
                      ),
                      Text("Same as Billing",
                          style: primaryTextStyle(size: 14)),
                    ],
                  ),
                ],
              ),
              8.height,
              _CRInputField(controller: _delAddress1Ctrl, hint: 'Address 1 *'),
              10.height,
              _CRInputField(controller: _delAddress2Ctrl, hint: 'Address 2'),
              10.height,
              _CRInputField(controller: _delCityCtrl, hint: 'City *'),
              10.height,
              if (_delStates.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _delStateCtrl.text.trim().isNotEmpty &&
                          _delStates.any((s) =>
                              s.name.toLowerCase() ==
                              _delStateCtrl.text.trim().toLowerCase())
                      ? _delStateCtrl.text.trim()
                      : null,
                  items: _delStates
                      .map((s) => DropdownMenuItem<String>(
                          value: s.name,
                          child: Text(s.name,
                              style: GoogleFonts.workSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: sh_textColorPrimary))))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _delStateCtrl.text = v ?? '';
                    });
                  },
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'State *',
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
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                )
              else
                _CRInputField(controller: _delStateCtrl, hint: 'State *'),
              10.height,
              _CRInputField(controller: _delZipCtrl, hint: 'Zip Code *'),
              10.height,
              DropdownButtonFormField<String>(
                value: _delCountryCtrl.value,
                items: (_variantCountries.isNotEmpty
                        ? _variantCountries.map((e) => e.name).toList()
                        : const [
                            'United Kingdom',
                            'United States',
                            'Canada',
                            'Germany',
                            'France'
                          ])
                    .map((e) => DropdownMenuItem<String>(
                        value: e,
                        child: Text(e,
                            style: GoogleFonts.workSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: sh_textColorPrimary))))
                    .toList(),
                onChanged: (v) async {
                  final next = v ?? _delCountryCtrl.value;
                  setState(() => _delCountryCtrl.value = next);
                  await _loadDelStates();
                },
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  return null;
                },
                decoration: InputDecoration(
                  hintText: 'Country *',
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
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
              16.height,
              Text('ADMIN SETTINGS',
                  style: GoogleFonts.workSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: sh_textColorSecondary)),
              8.height,
              DropdownButtonFormField<String>(
                key: ValueKey('status_$_status'),
                initialValue: _status,
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                  DropdownMenuItem(value: 'hold', child: Text('Hold')),
                ],
                onChanged: (v) => setState(() => _status = v ?? 'active'),
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
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
              20.height,
              if (_userDocId == null)
                Text(
                  'Customer record was not found by email. Only customers that exist in Users can be edited.',
                  style: GoogleFonts.workSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: sh_textColorSecondary),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(text,
        style: GoogleFonts.workSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: sh_textColorSecondary));
  }
}

class _CRInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? prefixText;
  const _CRInputField(
      {required this.controller, required this.hint, this.prefixText});
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
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
        prefixText: prefixText,
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
      validator: (v) {
        final required = hint.contains('*');
        if (!required) return null;
        if (v == null || v.trim().isEmpty) return 'Required';
        if (hint.toLowerCase().contains('email')) {
          final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
          if (!ok) return 'Invalid email';
        }
        return null;
      },
    );
  }
}

class _CRDropdownField extends StatelessWidget {
  final String label;
  final ValueNotifier<String> valueListenable;
  final List<String> items;
  const _CRDropdownField(
      {required this.label,
      required this.valueListenable,
      required this.items});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: valueListenable,
      builder: (_, value, __) {
        final safeItems = items.isNotEmpty ? items : [value];
        final hasValue = safeItems.contains(value);
        return DropdownButtonFormField<String>(
          initialValue: hasValue ? value : safeItems.first,
          items: safeItems
              .map((e) => DropdownMenuItem<String>(
                    value: e,
                    child: Text(e,
                        style: GoogleFonts.workSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: sh_textColorPrimary)),
                  ))
              .toList(),
          onChanged: (v) => valueListenable.value = v ?? value,
          validator: (v) {
            final required = label.contains('*');
            if (!required) return null;
            if (v == null || v.trim().isEmpty) return 'Required';
            return null;
          },
          decoration: InputDecoration(
            hintText: label,
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
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
        );
      },
    );
  }
}
