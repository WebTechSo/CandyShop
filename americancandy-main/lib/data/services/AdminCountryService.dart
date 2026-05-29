import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_state_city/country_state_city.dart';

class AdminCountryService {
  static final AdminCountryService instance = AdminCountryService._();
  AdminCountryService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Country>? _allCountries;
  List<Country>? _allowedCountries;
  DateTime? _allowedLoadedAt;

  Future<List<Country>> _getAllCountries() async {
    _allCountries ??= await getAllCountries();
    return _allCountries!;
  }

  Future<Map<String, dynamic>?> _getAdminSettings() async {
    try {
      final doc = await _firestore
          .collection('admin_setting')
          .doc('vw0U6xyVtJRKsL2b7F57')
          .get();
      if (doc.exists) {
        return doc.data();
      }
    } catch (_) {}
    final snap = await _firestore.collection('admin_setting').limit(1).get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.data();
  }

  String _normalizeKey(String v) {
    return v.trim().toUpperCase().replaceAll(RegExp(r'[\s\.\-_\(\)]'), '');
  }

  String _normalizeCountryToIso2(String raw) {
    final key = _normalizeKey(raw);
    if (key.isEmpty) return '';

    const aliases = <String, String>{
      'UK': 'GB',
      'UKEY': 'GB',
      'UNITEDKINGDOM': 'GB',
      'GREATBRITAIN': 'GB',
      'BRITAIN': 'GB',
      'ENGLAND': 'GB',
      'USA': 'US',
      'US': 'US',
      'UNITEDSTATES': 'US',
      'UNITEDSTATESOFAMERICA': 'US',
      'UAE': 'AE',
    };
    final hit = aliases[key];
    if (hit != null) return hit;

    if (key.length == 2) return key;
    if (key.length == 3) {
      const iso3ToIso2 = <String, String>{
        'USA': 'US',
        'GBR': 'GB',
        'CAN': 'CA',
        'AUS': 'AU',
        'DEU': 'DE',
        'FRA': 'FR',
      };
      return iso3ToIso2[key] ?? '';
    }
    return '';
  }

  Future<List<Country>> getAllowedCountries({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _allowedCountries != null &&
        _allowedLoadedAt != null &&
        DateTime.now().difference(_allowedLoadedAt!).inMinutes < 10) {
      return _allowedCountries!;
    }

    final data = await _getAdminSettings();
    final raw = data?['variant_countries'];

    final all = await _getAllCountries();
    final byIso = <String, Country>{
      for (final c in all) c.isoCode.toUpperCase(): c,
    };
    final byName = <String, Country>{
      for (final c in all) c.name.toLowerCase(): c,
    };

    final out = <Country>[];
    void addCountry(Country? c) {
      if (c == null) return;
      if (out.any((e) => e.isoCode == c.isoCode)) return;
      out.add(c);
    }

    Country? resolveFromAny(String input) {
      final iso2 = _normalizeCountryToIso2(input);
      if (iso2.isNotEmpty) return byIso[iso2];
      final nameKey = input.trim().toLowerCase();
      if (nameKey.isEmpty) return null;
      final exact = byName[nameKey];
      if (exact != null) return exact;

      final k = _normalizeKey(input);
      if (k == 'UK') return byIso['GB'];
      if (k == 'USA') return byIso['US'];

      final lower = input.trim().toLowerCase();
      if (lower == 'us' || lower == 'u.s.' || lower == 'u.s.a') {
        return byIso['US'];
      }
      if (lower == 'uk' || lower == 'u.k.') return byIso['GB'];
      return null;
    }

    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          final iso = (e['iso2'] ?? e['isoCode'] ?? e['code'] ?? '')
              .toString()
              .trim()
              .toUpperCase();
          final name = (e['name'] ?? '').toString().trim();
          if (iso.isNotEmpty) {
            addCountry(resolveFromAny(iso));
          } else if (name.isNotEmpty) {
            addCountry(resolveFromAny(name));
          }
        } else {
          final s = e.toString().trim();
          if (s.isEmpty) continue;
          addCountry(resolveFromAny(s));
        }
      }
    } else if (raw is Map) {
      for (final e in raw.values) {
        final s = e.toString().trim();
        if (s.isEmpty) continue;
        addCountry(resolveFromAny(s));
      }
    }

    if (out.isEmpty) {
      _allowedCountries = all;
    } else {
      _allowedCountries = out;
    }
    _allowedLoadedAt = DateTime.now();
    return _allowedCountries!;
  }

  Future<Country?> getDefaultCountry({bool forceRefresh = false}) async {
    final settings = await _getAdminSettings();
    final raw = (settings?['default_country'] ?? '').toString().trim();
    final allowed = await getAllowedCountries(forceRefresh: forceRefresh);
    if (allowed.isEmpty) return null;

    if (raw.isEmpty) return allowed.first;

    final all = await _getAllCountries();
    final byIso = <String, Country>{
      for (final c in all) c.isoCode.toUpperCase(): c,
    };
    final byName = <String, Country>{
      for (final c in all) c.name.toLowerCase(): c,
    };

    Country? resolveFromAny(String input) {
      final iso2 = _normalizeCountryToIso2(input);
      if (iso2.isNotEmpty) return byIso[iso2];
      final nameKey = input.trim().toLowerCase();
      if (nameKey.isEmpty) return null;
      final exact = byName[nameKey];
      if (exact != null) return exact;
      final k = _normalizeKey(input);
      if (k == 'UK') return byIso['GB'];
      if (k == 'USA') return byIso['US'];
      return null;
    }

    final resolved = resolveFromAny(raw);
    if (resolved == null) return allowed.first;

    final inAllowed =
        allowed.where((c) => c.isoCode == resolved.isoCode).toList();
    if (inAllowed.isNotEmpty) return inAllowed.first;
    return allowed.first;
  }

  Future<List<State>> getStatesForCountryIso(String countryIso2) async {
    final iso = countryIso2.trim().toUpperCase();
    if (iso.isEmpty) return [];
    return await getStatesOfCountry(iso);
  }

  Country? findCountryFromStored(String storedCountryOrIso) {
    final v = storedCountryOrIso.trim();
    if (v.isEmpty) return null;
    final all = _allCountries;
    if (all == null) return null;
    final iso = v.toUpperCase();
    final byIso = <String, Country>{
      for (final c in all) c.isoCode.toUpperCase(): c,
    };
    if (byIso.containsKey(iso)) return byIso[iso];
    final byName = <String, Country>{
      for (final c in all) c.name.toLowerCase(): c,
    };
    return byName[v.toLowerCase()];
  }
}
