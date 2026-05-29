import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/utils/AmConstant.dart';
import 'package:american_sweets/utils/AmStrings.dart';
import 'package:american_sweets/screens/AmHomeScreen.dart';
import 'package:american_sweets/screens/AdminDashboardScreen.dart';
import 'package:american_sweets/screens/OrderManagementScreen.dart';
import 'package:american_sweets/screens/ProductManagementScreen.dart';
import 'package:american_sweets/screens/CustomerManagementScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:american_sweets/firebase_options.dart';
import 'package:american_sweets/models/AmAddress.dart';
import 'package:american_sweets/data/services/notification_service.dart';
import 'package:american_sweets/data/services/AdminCountryService.dart';
import 'package:country_state_city/country_state_city.dart' as csc;

class CustomerRegisterScreen extends StatefulWidget {
  const CustomerRegisterScreen({Key? key}) : super(key: key);
  @override
  State<CustomerRegisterScreen> createState() => _CustomerRegisterScreenState();
}

class _CustomerRegisterScreenState extends State<CustomerRegisterScreen> {
  int _currentTab = 4;
  final _formKey = GlobalKey<FormState>();
  final _businessNameCtrl = TextEditingController();
  final _countryRegCtrl = ValueNotifier<String>('United Kingdom');
  final _regNumberCtrl = TextEditingController();
  final _vatNumberCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController(); // Added Password Field
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
  bool _agree = false;
  bool _sameAsBilling = false; // Added Same as Billing Checkbox State
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadVariantCountries();
    _billCountryCtrl.addListener(_handleBillingCountryChanged);
    _delCountryCtrl.addListener(_handleDeliveryCountryChanged);
    // Listeners to auto-fill delivery address when sameAsBilling is true
    _billAddress1Ctrl.addListener(_updateDeliveryAddress);
    _billAddress2Ctrl.addListener(_updateDeliveryAddress);
    _billCityCtrl.addListener(_updateDeliveryAddress);
    _billStateCtrl.addListener(_updateDeliveryAddress);
    _billZipCtrl.addListener(_updateDeliveryAddress);
    _billCountryCtrl.addListener(_updateDeliveryAddress);
  }

  void _handleBillingCountryChanged() {
    _updatePhonePrefix(_billCountryCtrl.value);
    _loadBillStates();
    if (_sameAsBilling) {
      _delCountryCtrl.value = _billCountryCtrl.value;
    }
  }

  void _handleDeliveryCountryChanged() {
    _loadDelStates();
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

  @override
  void dispose() {
    _billAddress1Ctrl.removeListener(_updateDeliveryAddress);
    _billAddress2Ctrl.removeListener(_updateDeliveryAddress);
    _billCityCtrl.removeListener(_updateDeliveryAddress);
    _billStateCtrl.removeListener(_updateDeliveryAddress);
    _billZipCtrl.removeListener(_updateDeliveryAddress);
    _billCountryCtrl.removeListener(_updateDeliveryAddress);
    _billCountryCtrl.removeListener(_handleBillingCountryChanged);
    _delCountryCtrl.removeListener(_handleDeliveryCountryChanged);
    super.dispose();
  }

  void _registerUser() async {
    if (!_agree) {
      toast('Please agree to the Terms and Conditions');
      return;
    }

    if (!_formKey.currentState!.validate()) {
      toast('Please fill all required fields');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    FirebaseApp? secondaryApp;
    FirebaseAuth? secondaryAuth;

    try {
      secondaryApp = await Firebase.initializeApp(
        name: 'customer_register_${DateTime.now().millisecondsSinceEpoch}',
        options: DefaultFirebaseOptions.currentPlatform,
      );
      secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      UserCredential userCredential =
          await secondaryAuth.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );

      final ActionCodeSettings verifySettings = ActionCodeSettings(
        url:
            'https://amaricancandy-c87c3.firebaseapp.com/verify-email?app=${Uri.encodeComponent(sh_app_name)}',
        handleCodeInApp: true,
        iOSBundleId: 'com.example.shopHopProkit',
        androidPackageName: 'com.sweetstop.app',
        androidInstallApp: true,
        androidMinimumVersion: '1',
      );

      // 2. Prepare user data
      Map<String, dynamic> userData = {
        'uid': userCredential.user!.uid,
        'email': _emailCtrl.text.trim(),
        'full_name': _fullNameCtrl.text.trim(),
        'business_name': _businessNameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'registration_country': _countryRegCtrl.value,
        'registration_number': _regNumberCtrl.text.trim(),
        'vat_number': _vatNumberCtrl.text.trim(),
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
        'role': 'customer',
        'user_type': 'business',
        'status': 'active',
        'terms_accepted': true,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'last_login': FieldValue.serverTimestamp(),
      };

      // 3. Save user data to Firestore
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(userCredential.user!.uid)
          .set(userData);

      // 4. Save delivery address to Addresses collection
      try {
        final newId = DateTime.now().millisecondsSinceEpoch;
        final addressModel = AmAddressModel(
          id: newId,
          full_name: _fullNameCtrl.text.trim(),
          address:
              "${_delAddress1Ctrl.text.trim()} ${_delAddress2Ctrl.text.trim()}"
                  .trim(),
          city: _delCityCtrl.text.trim(),
          state: _delStateCtrl.text.trim(),
          zip_code: _delZipCtrl.text.trim(),
          country: _delCountryCtrl.value,
          phone: _phoneCtrl.text.trim(),
          address_type: "Delivery",
          user_id: userCredential.user!.uid,
          default_address: true,
        );
        await FirebaseFirestore.instance
            .collection('Addresses')
            .doc(newId.toString())
            .set(addressModel.toJson());
      } catch (e) {
        print("⚠️ Failed to save delivery address to Addresses collection: $e");
      }

      await NotificationService().createNotification(
        userId: userCredential.user!.uid,
        title: 'Welcome',
        description: 'Your account has been created successfully.',
        type: 'welcome',
        isRead: false,
        priority: 'normal',
      );

      try {
        final u = userCredential.user;
        if (u != null) {
          try {
            await (u as dynamic).sendEmailVerification(verifySettings);
          } catch (_) {
            try {
              await (u as dynamic)
                  .sendEmailVerification(actionCodeSettings: verifySettings);
            } catch (_) {
              await u.sendEmailVerification();
            }
          }
        }
      } catch (_) {}

      toast('Registration Successful');
      finish(context);
    } on FirebaseAuthException catch (e) {
      toast(e.message ?? 'Registration Failed');
    } catch (e) {
      toast('Something went wrong: $e');
    } finally {
      try {
        await secondaryAuth?.signOut();
      } catch (_) {}
      try {
        await secondaryApp?.delete();
      } catch (_) {}
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: sh_background_color,
      body: SafeArea(
        child: Column(children: [
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
                      color: Colors.white))),
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
                  Text('Customer Register',
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
                ]),
          ),
          12.height,
          Expanded(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: spacing_standard_new),
              child: Form(
                key: _formKey,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                          child: Container(
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  color: const Color(0xFF0A2F1B),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: defaultBoxShadow(
                                      shadowColor: appShadowColor)),
                              child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24),
                                  child: Text('B2B',
                                      style: GoogleFonts.workSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: sh_white))))),
                      16.height,
                      Text('BUSINESS DETAILS',
                          style: GoogleFonts.workSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: sh_textColorSecondary)),
                      8.height,
                      _InputField(
                          controller: _businessNameCtrl,
                          hint: 'Business Name *'),
                      10.height,
                      DropdownButtonFormField<String>(
                        value: _countryRegCtrl.value,
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
                        onChanged: (v) => setState(() =>
                            _countryRegCtrl.value = v ?? _countryRegCtrl.value),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: 'Country of Registration *',
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
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                        ),
                      ),
                      10.height,
                      _InputField(
                          controller: _regNumberCtrl,
                          hint: 'Registration Number'),
                      10.height,
                      _InputField(
                          controller: _vatNumberCtrl, hint: 'VAT Number'),
                      16.height,
                      Text('CONTACT DETAILS',
                          style: GoogleFonts.workSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: sh_textColorSecondary)),
                      8.height,
                      _InputField(
                          controller: _fullNameCtrl, hint: 'Full Name *'),
                      10.height,
                      _InputField(controller: _emailCtrl, hint: 'Email *'),
                      10.height,
                      _InputField(
                          controller: _phoneCtrl,
                          hint: 'Contact Telephone Number *',
                          prefixText: _phonePrefix.isNotEmpty
                              ? '$_phonePrefix '
                              : null),
                      10.height,
                      _InputField(
                          controller: _passwordCtrl, hint: 'Password *'),
                      16.height,
                      Text('BILLING ADDRESS',
                          style: GoogleFonts.workSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: sh_textColorSecondary)),
                      8.height,
                      _InputField(
                          controller: _billAddress1Ctrl, hint: 'Address 1 *'),
                      10.height,
                      _InputField(
                          controller: _billAddress2Ctrl, hint: 'Address 2'),
                      10.height,
                      _InputField(controller: _billCityCtrl, hint: 'City *'),
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
                            if (v == null || v.trim().isEmpty)
                              return 'Required';
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
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                          ),
                        )
                      else
                        _InputField(
                            controller: _billStateCtrl, hint: 'State *'),
                      10.height,
                      _InputField(controller: _billZipCtrl, hint: 'Zip Code *'),
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
                        onChanged: (v) => setState(() => _billCountryCtrl
                            .value = v ?? _billCountryCtrl.value),
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
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
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
                      _InputField(
                          controller: _delAddress1Ctrl, hint: 'Address 1 *'),
                      10.height,
                      _InputField(
                          controller: _delAddress2Ctrl, hint: 'Address 2'),
                      10.height,
                      _InputField(controller: _delCityCtrl, hint: 'City *'),
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
                            if (v == null || v.trim().isEmpty)
                              return 'Required';
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
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                          ),
                        )
                      else
                        _InputField(controller: _delStateCtrl, hint: 'State *'),
                      10.height,
                      _InputField(controller: _delZipCtrl, hint: 'Zip Code *'),
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
                        onChanged: (v) => setState(() =>
                            _delCountryCtrl.value = v ?? _delCountryCtrl.value),
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
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                        ),
                      ),
                      16.height,
                      Row(children: [
                        Checkbox(
                            value: _agree,
                            onChanged: (v) =>
                                setState(() => _agree = v ?? false),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4))),
                        Expanded(
                            child: RichText(
                                text: TextSpan(children: [
                          TextSpan(
                              text: 'I agree to the ',
                              style: GoogleFonts.workSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: sh_textColorSecondary)),
                          TextSpan(
                              text: 'Terms and Conditions',
                              style: GoogleFonts.workSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: sh_colorPrimary))
                        ])))
                      ]),
                      16.height,
                      GestureDetector(
                        onTap: _isLoading ? null : _registerUser,
                        child: Container(
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                color: const Color(0xFF0A2F1B),
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: defaultBoxShadow(
                                    shadowColor: appShadowColor)),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : Text('Create B2B Account',
                                    style: GoogleFonts.workSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: sh_white))),
                      ),
                      12.height,
                    ]),
              ),
            ),
          ),
        ]),
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

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? prefixText;
  const _InputField(
      {Key? key, required this.controller, required this.hint, this.prefixText})
      : super(key: key);
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
          final ok =
              RegExp(r'^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$').hasMatch(v.trim());
          if (!ok) return 'Invalid email';
        }
        return null;
      },
    );
  }
}

class _CRDropdownField extends StatelessWidget {
  final String label;
  final ValueNotifier<String>? valueNotifier;
  final ValueNotifier<String>? valueListenable;
  final List<String> items;
  const _CRDropdownField(
      {Key? key,
      required this.label,
      this.valueNotifier,
      this.valueListenable,
      required this.items})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    final vn = valueNotifier ?? valueListenable!;
    return ValueListenableBuilder<String>(
      valueListenable: vn,
      builder: (_, value, __) {
        return DropdownButtonFormField<String>(
          initialValue: value,
          items: items
              .map((e) => DropdownMenuItem<String>(
                  value: e,
                  child: Text(e,
                      style: GoogleFonts.workSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: sh_textColorPrimary))))
              .toList(),
          onChanged: (v) => vn.value = v ?? value,
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
