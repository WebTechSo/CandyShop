import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:american_sweets/models/AmOrder.dart';
import 'package:american_sweets/screens/AmOrderDetailScreen.dart';
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/utils/AmConstant.dart';
import '../main.dart';

class CustomerOrderHistoryScreen extends StatefulWidget {
  final String customerName;
  final String customerEmail;
  final bool autoDownload;

  const CustomerOrderHistoryScreen({
    super.key,
    required this.customerName,
    required this.customerEmail,
    this.autoDownload = false,
  });

  @override
  State<CustomerOrderHistoryScreen> createState() =>
      _CustomerOrderHistoryScreenState();
}

class _CustomerOrderHistoryScreenState
    extends State<CustomerOrderHistoryScreen> {
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoDownload) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _downloadPdf();
      });
    }
  }

  Stream<List<AmOrder>> _ordersStream() {
    return FirebaseFirestore.instance
        .collection('Orders')
        .where('contact_email', isEqualTo: widget.customerEmail)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => AmOrder.fromSnapshot(d)).toList();
      list.sort((a, b) {
        final aT = a.orderDate?.toDate();
        final bT = b.orderDate?.toDate();
        if (aT == null && bT == null) return 0;
        if (aT == null) return 1;
        if (bT == null) return -1;
        return bT.compareTo(aT);
      });
      return list;
    });
  }

  Future<void> _downloadPdf() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      final orders = await FirebaseFirestore.instance
          .collection('Orders')
          .where('contact_email', isEqualTo: widget.customerEmail)
          .get();
      final parsed = orders.docs.map((d) => AmOrder.fromSnapshot(d)).toList();
      parsed.sort((a, b) {
        final aT = a.orderDate?.toDate();
        final bT = b.orderDate?.toDate();
        if (aT == null && bT == null) return 0;
        if (aT == null) return 1;
        if (bT == null) return -1;
        return bT.compareTo(aT);
      });

      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (ctx) {
            return [
              pw.Text('All Orders of ${widget.customerName}',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Text(widget.customerEmail,
                  style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 12),
              pw.TableHelper.fromTextArray(
                headers: const ['Order', 'Date', 'Status', 'Total'],
                data: parsed.map((o) {
                  final code = o.orderCode ?? o.id ?? '';
                  final date = o.orderDate?.toDate();
                  final dateStr = date != null
                      ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
                      : '';
                  final status = o.deliveryStatus ?? '';
                  final total = o.grandTotal ?? 0;
                  return [
                    code,
                    dateStr,
                    status,
                    '£${total.toStringAsFixed(2)}',
                  ];
                }).toList(),
                headerStyle:
                    pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                cellStyle: const pw.TextStyle(fontSize: 10),
                cellAlignment: pw.Alignment.centerLeft,
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEFEFEF)),
              ),
            ];
          },
        ),
      );

      final bytes = await doc.save();
      final safeName =
          widget.customerName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'orders_$safeName.pdf',
      );
    } catch (e) {
      toast(e.toString());
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: sh_background_color,
      appBar: AppBar(
        title: Text('All Orders of ${widget.customerName}',
            style: GoogleFonts.workSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: sh_textColorPrimary)),
        iconTheme: IconThemeData(
            color: appStore.isDarkModeOn ? white : sh_textColorPrimary),
        actions: [
          IconButton(
            icon: _downloading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download),
            onPressed: _downloading ? null : _downloadPdf,
            tooltip: 'Download PDF',
          ),
        ],
      ),
      body: StreamBuilder<List<AmOrder>>(
        stream: _ordersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return Center(
              child: Text('No orders found', style: primaryTextStyle()),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(spacing_standard_new),
            itemCount: list.length,
            separatorBuilder: (_, __) => 12.height,
            itemBuilder: (context, i) {
              final o = list[i];
              final code = o.orderCode ?? o.id ?? '';
              final date = o.orderDate?.toDate();
              final dateStr = date != null
                  ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
                  : '';
              final status = (o.deliveryStatus ?? '').toUpperCase();
              final total = o.grandTotal ?? 0;
              return InkWell(
                onTap: () {
                  AmOrderDetailScreen(order: o).launch(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                      color: white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: defaultBoxShadow(shadowColor: appShadowColor)),
                  padding: const EdgeInsets.all(spacing_standard_new),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Order $code',
                                style: GoogleFonts.workSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: sh_textColorPrimary)),
                            4.height,
                            Text(dateStr,
                                style: GoogleFonts.workSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: sh_textColorSecondary)),
                            8.height,
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                  color: sh_view_color,
                                  borderRadius: BorderRadius.circular(8)),
                              child: Text(status.isEmpty ? 'PENDING' : status,
                                  style: GoogleFonts.workSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: sh_textColorPrimary)),
                            ),
                          ],
                        ),
                      ),
                      Text('£${total.toStringAsFixed(2)}',
                          style: GoogleFonts.workSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: sh_colorPrimary)),
                      8.width,
                      Icon(Icons.arrow_forward_ios,
                          size: 16, color: sh_textColorSecondary),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
