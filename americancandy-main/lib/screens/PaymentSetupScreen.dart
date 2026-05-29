import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:american_sweets/models/AmPaymentMethod.dart';
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/utils/AmConstant.dart';
import 'package:american_sweets/utils/AmWidget.dart';

class PaymentSetupScreen extends StatefulWidget {
  const PaymentSetupScreen({Key? key}) : super(key: key);

  @override
  State<PaymentSetupScreen> createState() => _PaymentSetupScreenState();
}

class _PaymentSetupScreenState extends State<PaymentSetupScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _showAddEditDialog({required String type, AmPaymentMethod? method}) {
    final _formKey = GlobalKey<FormState>();
    // Fixed type (stripe | cod | bank)
    final String _type = type;
    final _nameController =
        TextEditingController(text: method?.name ?? 'Stripe');
    String _paymentMode = method?.paymentMode ?? 'Test';
    bool _enabled = method?.enabled ?? true;
    // Stripe keys
    final _testSecretController =
        TextEditingController(text: method?.testSecretKey ?? '');
    final _testPublishableController =
        TextEditingController(text: method?.testPublishableKey ?? '');
    final _liveSecretController =
        TextEditingController(text: method?.liveSecretKey ?? '');
    final _livePublishableController =
        TextEditingController(text: method?.livePublishableKey ?? '');
    // Bank transfer fields
    final _bankNameCtrl = TextEditingController(text: method?.bankName ?? '');
    final _accountHolderCtrl =
        TextEditingController(text: method?.accountHolderName ?? '');
    final _ibanCtrl = TextEditingController(text: method?.iban ?? '');
    final _bicCtrl = TextEditingController(text: method?.bicSwift ?? '');
    final _payRefCtrl =
        TextEditingController(text: method?.paymentReference ?? '');
    final _bankAddressCtrl =
        TextEditingController(text: method?.bankAddress ?? '');
    final _countryCtrl = TextEditingController(text: method?.country ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                  method == null ? 'Add Payment Method' : 'Edit Payment Method',
                  style: GoogleFonts.workSans(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Type is fixed by caller, show a small header
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _type == 'stripe'
                              ? 'Stripe'
                              : _type == 'cod'
                                  ? 'Cash on Delivery'
                                  : 'Bank Transfer',
                          style:
                              GoogleFonts.workSans(fontWeight: FontWeight.bold),
                        ),
                      ),
                      12.height,
                      if (_type == 'stripe') ...[
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                              labelText: 'Name (e.g. Stripe)'),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        16.height,
                        DropdownButtonFormField<String>(
                          value: _paymentMode,
                          items: ['Test', 'Live']
                              .map((e) =>
                                  DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (v) => setState(() => _paymentMode = v!),
                          decoration:
                              const InputDecoration(labelText: 'Payment Mode'),
                        ),
                        16.height,
                        Text('Test Keys',
                            style: GoogleFonts.workSans(
                                fontWeight: FontWeight.bold)),
                        TextFormField(
                          controller: _testSecretController,
                          decoration: const InputDecoration(
                              labelText: 'Test Secret Key'),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        TextFormField(
                          controller: _testPublishableController,
                          decoration: const InputDecoration(
                              labelText: 'Test Publishable Key'),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        16.height,
                        Text('Live Keys',
                            style: GoogleFonts.workSans(
                                fontWeight: FontWeight.bold)),
                        TextFormField(
                          controller: _liveSecretController,
                          decoration: const InputDecoration(
                              labelText: 'Live Secret Key'),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        TextFormField(
                          controller: _livePublishableController,
                          decoration: const InputDecoration(
                              labelText: 'Live Publishable Key'),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ] else if (_type == 'cod') ...[
                        SwitchListTile(
                          value: _enabled,
                          onChanged: (v) => setState(() => _enabled = v),
                          title: const Text('Enable Cash on Delivery'),
                          activeColor: sh_colorPrimary,
                        ),
                      ] else if (_type == 'bank') ...[
                        TextFormField(
                          controller: _bankNameCtrl,
                          decoration:
                              const InputDecoration(labelText: 'Bank Name'),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        TextFormField(
                          controller: _accountHolderCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Account Holder Name'),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        TextFormField(
                          controller: _ibanCtrl,
                          decoration: const InputDecoration(labelText: 'IBAN'),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        TextFormField(
                          controller: _bicCtrl,
                          decoration:
                              const InputDecoration(labelText: 'BIC / SWIFT'),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        TextFormField(
                          controller: _payRefCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Payment Reference Instruction'),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        12.height,
                        // Optional fields
                        TextFormField(
                          controller: _bankAddressCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Bank Address (optional)'),
                        ),
                        TextFormField(
                          controller: _countryCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Country (optional)'),
                        ),
                        12.height,
                        SwitchListTile(
                          value: _enabled,
                          onChanged: (v) => setState(() => _enabled = v),
                          title: const Text('Enable Bank Transfer'),
                          activeColor: sh_colorPrimary,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => finish(context),
                  child: Text('Cancel',
                      style: TextStyle(color: sh_textColorSecondary)),
                ),
                TextButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final id = method?.id ??
                          _firestore.collection('payment_methods').doc().id;
                      final newMethod = AmPaymentMethod(
                        id: id,
                        type: _type,
                        name: _type == 'stripe'
                            ? _nameController.text.trim()
                            : (_type == 'cod'
                                ? 'Cash on Delivery'
                                : 'Bank Transfer'),
                        paymentMode: _type == 'stripe' ? _paymentMode : null,
                        testSecretKey: _type == 'stripe'
                            ? _testSecretController.text.trim()
                            : null,
                        testPublishableKey: _type == 'stripe'
                            ? _testPublishableController.text.trim()
                            : null,
                        liveSecretKey: _type == 'stripe'
                            ? _liveSecretController.text.trim()
                            : null,
                        livePublishableKey: _type == 'stripe'
                            ? _livePublishableController.text.trim()
                            : null,
                        enabled: _type == 'stripe' ? true : _enabled,
                        bankName:
                            _type == 'bank' ? _bankNameCtrl.text.trim() : null,
                        accountHolderName: _type == 'bank'
                            ? _accountHolderCtrl.text.trim()
                            : null,
                        iban: _type == 'bank' ? _ibanCtrl.text.trim() : null,
                        bicSwift: _type == 'bank' ? _bicCtrl.text.trim() : null,
                        paymentReference:
                            _type == 'bank' ? _payRefCtrl.text.trim() : null,
                        bankAddress: _type == 'bank'
                            ? _bankAddressCtrl.text.trim()
                            : null,
                        country:
                            _type == 'bank' ? _countryCtrl.text.trim() : null,
                      );

                      await _firestore
                          .collection('payment_methods')
                          .doc(id)
                          .set(newMethod.toJson());

                      finish(context);
                      toast('Saved successfully');
                    }
                  },
                  child: Text('Save', style: TextStyle(color: sh_colorPrimary)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment Setup', style: boldTextStyle(size: 18)),
        backgroundColor: sh_white,
        iconTheme: IconThemeData(color: sh_textColorPrimary),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('payment_methods').snapshots(),
        builder: (context, snapshot) {
          final methods = snapshot.hasData
              ? snapshot.data!.docs
                  .map((e) => AmPaymentMethod.fromJson(
                      e.data() as Map<String, dynamic>))
                  .toList()
              : <AmPaymentMethod>[];
          AmPaymentMethod? findByType(String t) {
            for (final m in methods) {
              if (m.type == t) return m;
            }
            return null;
          }

          AmPaymentMethod? stripe = findByType('stripe');
          AmPaymentMethod? cod = findByType('cod');
          AmPaymentMethod? bank = findByType('bank');

          Widget card({
            required String title,
            required String subtitle,
            required VoidCallback onConfigure,
            bool enabled = true,
          }) {
            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: sh_view_color),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                title: Text(title, style: boldTextStyle()),
                subtitle: Text(subtitle),
                trailing: AppButton(
                  text: 'Configure',
                  color: sh_colorPrimary,
                  textColor: white,
                  onTap: onConfigure,
                ),
              ),
            );
          }

          return ListView(
            padding: EdgeInsets.all(16),
            children: [
              card(
                title: 'Stripe',
                subtitle: stripe != null
                    ? 'Mode: ${stripe.paymentMode ?? 'Unknown'}'
                    : 'Not configured',
                onConfigure: () =>
                    _showAddEditDialog(type: 'stripe', method: stripe),
              ),
              16.height,
              card(
                title: 'Cash on Delivery',
                subtitle: cod != null
                    ? (cod.enabled == true ? 'Enabled' : 'Disabled')
                    : 'Not configured',
                onConfigure: () => _showAddEditDialog(type: 'cod', method: cod),
              ),
              16.height,
              card(
                title: 'Bank Transfer',
                subtitle: bank != null
                    ? '${bank.bankName ?? 'Configured'} • ${bank.enabled == true ? 'Enabled' : 'Disabled'}'
                    : 'Not configured',
                onConfigure: () =>
                    _showAddEditDialog(type: 'bank', method: bank),
              ),
            ],
          );
        },
      ),
    );
  }
}
