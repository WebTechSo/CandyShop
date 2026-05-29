import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:american_sweets/models/AmAddress.dart';
import 'package:american_sweets/data/services/address_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/utils/AmConstant.dart';
import 'package:american_sweets/utils/AmStrings.dart';
import 'package:american_sweets/utils/AmWidget.dart';
import 'package:american_sweets/data/services/AdminCountryService.dart';
import 'package:country_state_city/country_state_city.dart' as csc;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../main.dart';

// ignore: must_be_immutable
class AmAddNewAddress extends StatefulWidget {
  static String tag = '/AddNewAddress';
  AmAddressModel? addressModel;

  AmAddNewAddress({this.addressModel});

  @override
  AmAddNewAddressState createState() => AmAddNewAddressState();
}

class AmAddNewAddressState extends State<AmAddNewAddress> {
  var primaryColor;
  var fullNameCont = TextEditingController();
  var zipCont = TextEditingController();
  var cityCont = TextEditingController();
  var stateCont = TextEditingController();
  var address1Cont = TextEditingController();
  var address2Cont = TextEditingController();
  var phoneNumberCont = TextEditingController();
  var countryCont = TextEditingController();
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  final ValueNotifier<String> _selectedCountry = ValueNotifier<String>('');
  final ValueNotifier<String> _selectedState = ValueNotifier<String>('');
  List<csc.Country> _variantCountries = [];
  List<csc.State> _statesByCountry = [];
  String _countryPhonePrefix = '';

  void onTextChanged(String value) {
    if (_autovalidateMode == AutovalidateMode.onUserInteraction) {
      _formKey.currentState!.validate();
    }
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  init() async {
    await _loadVariantCountries();
    if (widget.addressModel == null && _variantCountries.isNotEmpty) {
      final def = await AdminCountryService.instance.getDefaultCountry();
      if (def != null) {
        _selectedCountry.value = def.isoCode;
        countryCont.text = def.name;
        await _loadStatesForCountry(def.isoCode);
        _updatePhonePrefix(def.isoCode);
      }
    }
    if (widget.addressModel != null) {
      zipCont.text = widget.addressModel!.zip_code!;
      address1Cont.text = widget.addressModel!.address!;
      address2Cont.text = ''; // Combined in address
      cityCont.text = widget.addressModel!.city!;
      stateCont.text = widget.addressModel!.state!;
      countryCont.text = widget.addressModel!.country!;
      fullNameCont.text = widget.addressModel!.full_name!;
      phoneNumberCont.text = widget.addressModel!.phone!;
      _selectedState.value = stateCont.text;
    }
    final storedCountry = countryCont.text.trim();
    if (storedCountry.isNotEmpty) {
      for (final c in _variantCountries) {
        if (c.name.toLowerCase() == storedCountry.toLowerCase() ||
            c.isoCode.toLowerCase() == storedCountry.toLowerCase()) {
          _selectedCountry.value = c.isoCode;
          break;
        }
      }
    }

    if (_selectedCountry.value.isEmpty && _variantCountries.isNotEmpty) {
      final def = await AdminCountryService.instance.getDefaultCountry();
      final chosen =
          def != null && _variantCountries.any((c) => c.isoCode == def.isoCode)
              ? def
              : _variantCountries.first;
      _selectedCountry.value = chosen.isoCode;
      countryCont.text = chosen.name;
    } else if (_selectedCountry.value.isNotEmpty && storedCountry.isEmpty) {
      final c = _variantCountries
          .where((e) => e.isoCode == _selectedCountry.value)
          .toList();
      if (c.isNotEmpty) countryCont.text = c.first.name;
    }

    if (_selectedCountry.value.isNotEmpty) {
      await _loadStatesForCountry(_selectedCountry.value);
      _updatePhonePrefix(_selectedCountry.value);
    }
  }

  Future<void> _fetchAndFillCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          toasty(context, "Location permission denied");
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        toasty(context, "Location permission permanently denied");
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);

      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isEmpty) {
        toasty(context, "Unable to get address from location");
        return;
      }

      final place = placemarks.first;
      final addressLine = [
        place.street,
        place.subLocality,
      ].where((e) => e != null && e.trim().isNotEmpty).join(" ");

      setState(() {
        address1Cont.text =
            addressLine.isNotEmpty ? addressLine : address1Cont.text;
        cityCont.text =
            (place.locality ?? '').isNotEmpty ? place.locality! : cityCont.text;
        stateCont.text = (place.administrativeArea ?? '').isNotEmpty
            ? place.administrativeArea!
            : stateCont.text;
        countryCont.text = (place.country ?? '').isNotEmpty
            ? place.country!
            : countryCont.text;
        zipCont.text = (place.postalCode ?? '').isNotEmpty
            ? place.postalCode!
            : zipCont.text;
      });
    } catch (e) {
      toasty(context, "Failed to get current location");
    }
  }

  Future<void> _loadVariantCountries() async {
    try {
      final list = await AdminCountryService.instance.getAllowedCountries();
      if (!mounted) return;
      setState(() => _variantCountries = list);
    } catch (e) {
      print('Failed to load variant_countries: $e');
    }
  }

  Future<void> _loadStatesForCountry(String country) async {
    final iso = country.trim().toUpperCase();
    if (iso.isEmpty) {
      setState(() => _statesByCountry = []);
      return;
    }
    try {
      final states =
          await AdminCountryService.instance.getStatesForCountryIso(iso);
      if (!mounted) return;
      setState(() => _statesByCountry = states);
    } catch (e) {
      print('Failed to load states for $country: $e');
    }
  }

  void _updatePhonePrefix(String iso) {
    final match =
        _variantCountries.where((c) => c.isoCode.toUpperCase() == iso).toList();
    final phoneCode =
        match.isNotEmpty ? match.first.phoneCode.toString().trim() : '';
    setState(() {
      _countryPhonePrefix = phoneCode.isNotEmpty ? '+$phoneCode' : '';
    });
  }

  @override
  Widget build(BuildContext context) {
    void onSaveClicked() async {
      setState(() {
        isLoading = true;
      });

      AmAddressModel model = AmAddressModel();
      model.full_name = fullNameCont.text;

      String fullAddress = address1Cont.text;
      if (address2Cont.text.isNotEmpty) {
        fullAddress += " " + address2Cont.text;
      }
      model.address = fullAddress;

      model.city = cityCont.text;
      model.state = stateCont.text;
      model.country = countryCont.text;
      model.zip_code = zipCont.text;
      model.phone = phoneNumberCont.text;

      AddressService service = AddressService();

      try {
        if (widget.addressModel != null) {
          model.id = widget.addressModel!.id;
          model.user_id = widget.addressModel!.user_id ??
              FirebaseAuth.instance.currentUser?.uid;
          await service.updateAddress(model);
        } else {
          await service.addAddress(model);
        }
        Navigator.pop(context, true);
      } catch (e) {
        toasty(context, "Error saving address: $e");
        setState(() {
          isLoading = false;
        });
      }
    }
    // TODO Without NullSafety Geo coder
/*    getLocation() async {
      Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high).then((position) {
        var coordinates = Coordinates(position.latitude, position.longitude);
        Geocoder.local.findAddressesFromCoordinates(coordinates).then((addresses) {
          var first = addresses.first;
          print("${addresses} : ${first.addressLine}");
          setState(() {
            pinCodeCont.text = first.postalCode;
            addressCont.text = first.addressLine;
            cityCont.text = first.locality;
            stateCont.text = first.adminArea;
            countryCont.text = first.countryName;
          });
        }).catchError((error) {
          print(error);
        });
      }).catchError((error) {
        print(error);
      });
    }*/

    final useCurrentLocation = Container(
      alignment: Alignment.center,
      child: MaterialButton(
        color: appStore.isDarkModeOn ? cardDarkColor : sh_light_gray,
        elevation: 0,
        padding: EdgeInsets.only(top: spacing_middle, bottom: spacing_middle),
        onPressed: _fetchAndFillCurrentLocation,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.my_location, color: primaryColor, size: 16),
            8.width,
            Text('Use Current Location', style: primaryTextStyle()),
          ],
        ),
      ),
    );

    final fullName = TextFormField(
      autovalidateMode: _autovalidateMode,
      onChanged: onTextChanged,
      controller: fullNameCont,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.words,
      style: primaryTextStyle(),
      autofocus: false,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Full Name is required';
        }
        return null;
      },
      onFieldSubmitted: (term) {
        FocusScope.of(context).nextFocus();
      },
      decoration: formFieldDecoration("Full Name *"),
    );

    final zipCode = TextFormField(
      autovalidateMode: _autovalidateMode,
      onChanged: onTextChanged,
      controller: zipCont,
      keyboardType: TextInputType.text,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 \-]')),
      ],
      maxLength: 12,
      autofocus: false,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Zip Code is required';
        }
        return null;
      },
      onFieldSubmitted: (term) {
        FocusScope.of(context).nextFocus();
      },
      textInputAction: TextInputAction.next,
      style: primaryTextStyle(),
      decoration: formFieldDecoration("Zip Code *"),
    );

    final city = TextFormField(
      autovalidateMode: _autovalidateMode,
      onChanged: onTextChanged,
      controller: cityCont,
      keyboardType: TextInputType.text,
      textCapitalization: TextCapitalization.words,
      style: primaryTextStyle(),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'City is required';
        }
        return null;
      },
      onFieldSubmitted: (term) {
        FocusScope.of(context).nextFocus();
      },
      textInputAction: TextInputAction.next,
      autofocus: false,
      decoration: formFieldDecoration(sh_hint_city + " *"),
    );

    final state = ValueListenableBuilder<String>(
      valueListenable: _selectedState,
      builder: (_, val, __) {
        if (_statesByCountry.isEmpty) {
          return TextFormField(
            autovalidateMode: _autovalidateMode,
            onFieldSubmitted: (term) => FocusScope.of(context).nextFocus(),
            controller: stateCont,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.words,
            style: primaryTextStyle(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'State is required';
              }
              return null;
            },
            autofocus: false,
            textInputAction: TextInputAction.next,
            decoration: formFieldDecoration(sh_hint_state + " *"),
          );
        }
        return DropdownButtonFormField<String>(
          value: val.isNotEmpty &&
                  _statesByCountry
                      .any((s) => s.name.toLowerCase() == val.toLowerCase())
              ? val
              : null,
          items: _statesByCountry
              .map((s) => DropdownMenuItem(value: s.name, child: Text(s.name)))
              .toList(),
          onChanged: (v) {
            final s = v ?? '';
            _selectedState.value = s;
            stateCont.text = s;
          },
          validator: (v) {
            if ((v ?? '').trim().isEmpty) return 'State is required';
            return null;
          },
          decoration: formFieldDecoration(sh_hint_state + " *"),
        );
      },
    );

    final country = ValueListenableBuilder<String>(
      valueListenable: _selectedCountry,
      builder: (_, val, __) {
        return DropdownButtonFormField<String>(
          value:
              val.isNotEmpty && _variantCountries.any((c) => c.isoCode == val)
                  ? val
                  : null,
          items: _variantCountries
              .map((c) =>
                  DropdownMenuItem(value: c.isoCode, child: Text(c.name)))
              .toList(),
          onChanged: (v) async {
            final iso = (v ?? '').trim().toUpperCase();
            _selectedCountry.value = iso;
            final match = _variantCountries
                .where((c) => c.isoCode.toUpperCase() == iso)
                .toList();
            countryCont.text = match.isNotEmpty ? match.first.name : '';
            _selectedState.value = '';
            stateCont.text = '';
            await _loadStatesForCountry(iso);
            _updatePhonePrefix(iso);
          },
          validator: (v) {
            if ((v ?? '').trim().isEmpty) return 'Country is required';
            return null;
          },
          decoration: formFieldDecoration("Country *"),
        );
      },
    );

    final address1 = TextFormField(
      autovalidateMode: _autovalidateMode,
      controller: address1Cont,
      keyboardType: TextInputType.multiline,
      maxLines: 2,
      onFieldSubmitted: (term) {
        FocusScope.of(context).nextFocus();
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Address is required';
        }
        return null;
      },
      autofocus: false,
      style: primaryTextStyle(),
      decoration: formFieldDecoration("Address *"),
    );

    final phoneNumber = TextFormField(
      autovalidateMode: _autovalidateMode,
      onChanged: onTextChanged,
      controller: phoneNumberCont,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.done,
      maxLength: 10,
      autofocus: false,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Phone Number is required';
        }
        return null;
      },
      decoration: formFieldDecoration(sh_hint_contact + " *").copyWith(
        prefixText:
            _countryPhonePrefix.isNotEmpty ? '$_countryPhonePrefix ' : null,
      ),
    );

    final saveCancelRow = Row(
      children: [
        Expanded(
          child: MaterialButton(
            height: 50,
            shape: RoundedRectangleBorder(
                borderRadius: new BorderRadius.circular(40.0)),
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                onSaveClicked();
              }
            },
            color: sh_colorPrimary,
            child: text(sh_lbl_save_address,
                fontFamily: fontMedium,
                fontSize: textSizeLargeMedium,
                textColor: sh_white),
          ),
        ),
        SizedBox(width: spacing_standard_new),
        Expanded(
          child: MaterialButton(
            height: 50,
            shape: RoundedRectangleBorder(
                borderRadius: new BorderRadius.circular(40.0),
                side: BorderSide(color: sh_colorPrimary, width: 1)),
            onPressed: () {
              Navigator.pop(context);
            },
            color: context.cardColor,
            child: text('Cancel',
                fontFamily: fontMedium,
                fontSize: textSizeLargeMedium,
                textColor: sh_colorPrimary),
          ),
        ),
      ],
    );

    final body = Form(
      key: _formKey,
      child: Wrap(runSpacing: spacing_standard_new, children: <Widget>[
        useCurrentLocation,
        fullName,
        phoneNumber,
        address1,
        Row(children: <Widget>[
          Expanded(child: country),
          SizedBox(width: spacing_standard_new),
          Expanded(child: state),
        ]),
        Row(children: <Widget>[
          Expanded(child: city),
          SizedBox(width: spacing_standard_new),
          Expanded(child: zipCode),
        ]),
        Padding(
          padding: const EdgeInsets.only(top: 30.0, bottom: 30.0),
          child: saveCancelRow,
        ),
      ]),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.addressModel == null
                ? sh_lbl_add_new_address
                : sh_lbl_edit_address,
            style: boldTextStyle()),
        // iconTheme: IconThemeData(
        //     color: appStore.isDarkModeOn ? white : sh_textColorPrimary),
        // actionsIconTheme: IconThemeData(
        //     color: appStore.isDarkModeOn ? white : sh_colorPrimary),
        // actions: [
        //   cartIcon(context, 3),
        // ],
      ),
      body: Stack(
        children: [
          Container(
              width: double.infinity,
              child: SingleChildScrollView(child: body),
              margin: EdgeInsets.all(16)),
          if (isLoading) Loader().center().visible(isLoading),
        ],
      ),
    );
  }
}
