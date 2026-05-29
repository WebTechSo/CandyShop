import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/utils/AmConstant.dart';
import 'package:american_sweets/utils/AmStrings.dart';
import 'package:american_sweets/screens/CustomerB2BScreen.dart';
import 'package:american_sweets/screens/CustomerGuestScreen.dart';
import 'package:american_sweets/screens/CustomerDetailScreen.dart';
import 'package:american_sweets/screens/CustomerRegisterScreen.dart';
import 'package:american_sweets/screens/AmHomeScreen.dart';
import 'package:american_sweets/screens/AdminDashboardScreen.dart';
import 'package:american_sweets/screens/OrderManagementScreen.dart';
import 'package:american_sweets/screens/ProductManagementScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:american_sweets/utils/AmNotificationBell.dart';

class CustomerManagementScreen extends StatefulWidget {
  const CustomerManagementScreen({Key? key}) : super(key: key);
  @override
  State<CustomerManagementScreen> createState() =>
      _CustomerManagementScreenState();
}

class _CustomerManagementScreenState extends State<CustomerManagementScreen> {
  int _currentTab = 4;
  final TextEditingController _searchCtrl = TextEditingController();

  List<_Customer> _customers = [];
  bool isLoading = true;

  // Filter & Sort State
  String _filterCity = '';
  String _filterState = '';
  String _filterCountry = '';
  String _sortOption = 'date_desc'; // Default to Latest Registered

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('Users').get();

      final futures = snapshot.docs.map((doc) async {
        final data = doc.data();
        final role = data['role']?.toString().toLowerCase() ?? '';
        if (role == 'admin') return null;

        final name = data['full_name'] ?? data['name'] ?? 'Unknown';
        final email = data['email'] ?? '';
        final businessName = data['business_name'];
        final isB2B =
            businessName != null && businessName.toString().isNotEmpty;

        final billing = data['billing_address'] is Map
            ? data['billing_address'] as Map<String, dynamic>
            : <String, dynamic>{};
        final city = billing['city']?.toString() ?? '';
        final state = billing['state']?.toString() ?? '';
        final country = billing['country']?.toString() ?? '';

        final createdAtRaw = data['created_at'];
        final createdAt =
            createdAtRaw is Timestamp ? createdAtRaw.toDate() : DateTime.now();

        // Fetch total orders count
        int totalOrders = 0;
        try {
          final orderSnap = await FirebaseFirestore.instance
              .collection('Orders')
              .where('user_id', isEqualTo: doc.id)
              .get();
          totalOrders = orderSnap.size;
        } catch (e) {
          print('Error fetching order count for ${doc.id}: $e');
        }

        return _Customer(
          name: name,
          email: email,
          type: isB2B ? _CustType.b2b : _CustType.guest,
          totalOrders: totalOrders,
          city: city,
          state: state,
          country: country,
          createdAt: createdAt,
        );
      });

      final results = await Future.wait(futures);
      final list = results.whereType<_Customer>().toList();

      if (mounted) {
        setState(() {
          _customers = list;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching customers: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _openFilterDrawer() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Filter',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) {
        return StatefulBuilder(builder: (context, setInnerState) {
          return Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 320,
                margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                decoration: BoxDecoration(
                    color: sh_background_color,
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        bottomLeft: Radius.circular(24)),
                    boxShadow: defaultBoxShadow(shadowColor: appShadowColor)),
                child: _CustomerFilterDrawer(
                  city: _filterCity,
                  state: _filterState,
                  country: _filterCountry,
                  sortOption: _sortOption,
                  onCityChanged: (v) {
                    setInnerState(() => _filterCity = v);
                    this.setState(() => _filterCity = v);
                  },
                  onStateChanged: (v) {
                    setInnerState(() => _filterState = v);
                    this.setState(() => _filterState = v);
                  },
                  onCountryChanged: (v) {
                    setInnerState(() => _filterCountry = v);
                    this.setState(() => _filterCountry = v);
                  },
                  onSortChanged: (v) {
                    setInnerState(() => _sortOption = v);
                    this.setState(() => _sortOption = v);
                  },
                  onApply: () => Navigator.of(context).maybePop(),
                  onClear: () {
                    this.setState(() {
                      _filterCity = '';
                      _filterState = '';
                      _filterCountry = '';
                      _sortOption = 'date_desc';
                    });
                    Navigator.of(context).maybePop();
                  },
                ),
              ),
            ),
          );
        });
      },
      transitionBuilder: (_, anim, __, child) {
        return SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(anim),
            child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<_Customer> list = _customers.where((c) {
      // Search Filter
      final q = _searchCtrl.text.trim().toLowerCase();
      if (q.isNotEmpty) {
        if (!c.name.toLowerCase().contains(q) &&
            !c.email.toLowerCase().contains(q)) return false;
      }

      // Address Filter
      if (_filterCity.isNotEmpty &&
          !c.city.toLowerCase().contains(_filterCity.toLowerCase())) {
        return false;
      }
      if (_filterState.isNotEmpty &&
          !c.state.toLowerCase().contains(_filterState.toLowerCase())) {
        return false;
      }
      if (_filterCountry.isNotEmpty &&
          !c.country.toLowerCase().contains(_filterCountry.toLowerCase())) {
        return false;
      }

      return true;
    }).toList();

    // Sort Logic
    list.sort((a, b) {
      switch (_sortOption) {
        case 'name_asc':
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case 'name_desc':
          return b.name.toLowerCase().compareTo(a.name.toLowerCase());
        case 'orders_desc':
          return b.totalOrders.compareTo(a.totalOrders);
        case 'date_asc':
          return a.createdAt.compareTo(b.createdAt);
        case 'date_desc':
        default:
          return b.createdAt.compareTo(a.createdAt);
      }
    });

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
                  Text('Customer',
                      style: GoogleFonts.workSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: sh_colorPrimary)),
                  AmNotificationBell(iconColor: sh_colorPrimary),
                ]),
          ),
          12.height,
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: spacing_standard_new),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    style: GoogleFonts.workSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: sh_textColorPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search customers...',
                      hintStyle: GoogleFonts.workSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: sh_textColorSecondary),
                      prefixIcon: const Icon(Icons.search,
                          color: sh_textColorSecondary),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28.0),
                          borderSide: BorderSide(color: sh_view_color)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28.0),
                          borderSide: BorderSide(color: sh_view_color)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
                12.width,
                InkWell(
                  onTap: _openFilterDrawer,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: sh_view_color)),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_alt_outlined,
                            color: sh_textColorSecondary),
                      ],
                    ),
                  ),
                ),
                10.width,
                InkWell(
                  onTap: () => const CustomerRegisterScreen().launch(context),
                  child: Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [sh_gradient_1st, sh_gradient_2nd]),
                        borderRadius: BorderRadius.circular(23),
                        boxShadow:
                            defaultBoxShadow(shadowColor: appShadowColor)),
                    child: const Icon(Icons.add, color: sh_white),
                  ),
                ),
              ],
            ),
          ),
          12.height,
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: spacing_standard_new),
                    itemCount: list.length + 1,
                    separatorBuilder: (_, __) => 12.height,
                    itemBuilder: (_, i) {
                      if (i == list.length) {
                        return _AddButton(
                            label: '+ Add Customer',
                            onTap: () {
                              const CustomerRegisterScreen().launch(context);
                            });
                      }
                      final c = list[i];
                      return InkWell(
                        onTap: () {
                          CustomerDetailScreen(
                            name: c.name,
                            email: c.email,
                            typeLabel:
                                c.type == _CustType.guest ? 'Guest' : 'B2B',
                            totalOrders: c.totalOrders,
                            orders: const [], // You might want to fetch these too if needed
                          ).launch(context);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: defaultBoxShadow(
                                  shadowColor: appShadowColor)),
                          child: Padding(
                            padding: const EdgeInsets.all(spacing_standard_new),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(c.name,
                                            style: GoogleFonts.workSans(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                                color: sh_textColorPrimary)),
                                      ),
                                      if (c.city.isNotEmpty)
                                        Text(c.city,
                                            style: GoogleFonts.workSans(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: sh_textColorSecondary)),
                                    ],
                                  ),
                                  6.height,
                                  Text(c.email,
                                      style: GoogleFonts.workSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: sh_textColorSecondary)),
                                  10.height,
                                  Row(children: [
                                    _Badge(
                                        label: c.type == _CustType.guest
                                            ? 'Guest'
                                            : 'B2B',
                                        gradient: c.type == _CustType.b2b
                                            ? const LinearGradient(colors: [
                                                sh_gradient_1st,
                                                sh_gradient_2nd
                                              ])
                                            : null,
                                        bgColor: c.type == _CustType.guest
                                            ? const Color(0x332F8F46)
                                            : null,
                                        textColor: c.type == _CustType.guest
                                            ? const Color(0xFF2F8F46)
                                            : sh_white),
                                    const Spacer(),
                                    Text('Total Orders: ${c.totalOrders}',
                                        style: GoogleFonts.workSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: sh_textColorPrimary))
                                  ])
                                ]),
                          ),
                        ),
                      );
                    },
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

enum _CustType { b2b, guest }

class _Customer {
  final String name;
  final String email;
  final _CustType type;
  final int totalOrders;
  final String city;
  final String state;
  final String country;
  final DateTime createdAt;

  _Customer({
    required this.name,
    required this.email,
    required this.type,
    required this.totalOrders,
    this.city = '',
    this.state = '',
    this.country = '',
    required this.createdAt,
  });
}

class _CustomerFilterDrawer extends StatefulWidget {
  final String city;
  final String state;
  final String country;
  final String sortOption;
  final Function(String) onCityChanged;
  final Function(String) onStateChanged;
  final Function(String) onCountryChanged;
  final Function(String) onSortChanged;
  final VoidCallback onApply;
  final VoidCallback onClear;

  const _CustomerFilterDrawer({
    Key? key,
    required this.city,
    required this.state,
    required this.country,
    required this.sortOption,
    required this.onCityChanged,
    required this.onStateChanged,
    required this.onCountryChanged,
    required this.onSortChanged,
    required this.onApply,
    required this.onClear,
  }) : super(key: key);

  @override
  State<_CustomerFilterDrawer> createState() => _CustomerFilterDrawerState();
}

class _CustomerFilterDrawerState extends State<_CustomerFilterDrawer> {
  late TextEditingController _cityCtrl;
  late TextEditingController _stateCtrl;
  late TextEditingController _countryCtrl;

  @override
  void initState() {
    super.initState();
    _cityCtrl = TextEditingController(text: widget.city);
    _stateCtrl = TextEditingController(text: widget.state);
    _countryCtrl = TextEditingController(text: widget.country);
  }

  @override
  void dispose() {
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  Widget _buildSortOption(String label, String value) {
    final isSelected = widget.sortOption == value;
    return InkWell(
      onTap: () => widget.onSortChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? sh_colorPrimary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isSelected ? sh_colorPrimary : Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? sh_colorPrimary : Colors.grey,
              size: 20,
            ),
            8.width,
            Text(label,
                style: GoogleFonts.workSans(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: sh_textColorPrimary)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filter & Sort',
                  style: GoogleFonts.workSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: sh_textColorPrimary)),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: sh_textColorSecondary))
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Address Filter',
                    style: GoogleFonts.workSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: sh_textColorPrimary)),
                12.height,
                TextField(
                  controller: _cityCtrl,
                  onChanged: widget.onCityChanged,
                  decoration: InputDecoration(
                    labelText: 'City',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                ),
                12.height,
                TextField(
                  controller: _stateCtrl,
                  onChanged: widget.onStateChanged,
                  decoration: InputDecoration(
                    labelText: 'State',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                ),
                12.height,
                TextField(
                  controller: _countryCtrl,
                  onChanged: widget.onCountryChanged,
                  decoration: InputDecoration(
                    labelText: 'Country',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                ),
                24.height,
                Text('Sort By',
                    style: GoogleFonts.workSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: sh_textColorPrimary)),
                12.height,
                _buildSortOption('Name (A-Z)', 'name_asc'),
                _buildSortOption('Name (Z-A)', 'name_desc'),
                _buildSortOption('Total Orders (Highest First)', 'orders_desc'),
                _buildSortOption('Register Date (Latest First)', 'date_desc'),
                _buildSortOption('Register Date (Oldest First)', 'date_asc'),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onClear,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                  ),
                  child: Text('Clear',
                      style: GoogleFonts.workSans(
                          fontWeight: FontWeight.w600,
                          color: sh_textColorPrimary)),
                ),
              ),
              16.width,
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.onApply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: sh_colorPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                  ),
                  child: Text('Apply',
                      style: GoogleFonts.workSans(
                          fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color? bgColor;
  final LinearGradient? gradient;
  final Color textColor;
  const _Badge(
      {Key? key,
      required this.label,
      this.bgColor,
      this.gradient,
      required this.textColor})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: bgColor,
          gradient: gradient,
          borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: GoogleFonts.workSans(
              fontSize: 12, fontWeight: FontWeight.w700, color: textColor)),
    );
  }
}

class _AddButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AddButton({Key? key, required this.label, required this.onTap})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [sh_gradient_1st, sh_gradient_2nd]),
            borderRadius: BorderRadius.circular(32),
            boxShadow: defaultBoxShadow(shadowColor: appShadowColor)),
        child: Text(label,
            style: GoogleFonts.workSans(
                fontSize: 16, fontWeight: FontWeight.w700, color: sh_white)),
      ),
    );
  }
}
