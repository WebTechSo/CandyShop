import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:american_sweets/models/AmBrand.dart';
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/screens/AddBrandScreen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BrandManagementScreen extends StatefulWidget {
  const BrandManagementScreen({Key? key}) : super(key: key);

  @override
  State<BrandManagementScreen> createState() => _BrandManagementScreenState();
}

class _BrandManagementScreenState extends State<BrandManagementScreen> {
  Widget _buildBrandIcon(AmBrand brand) {
    String? url = brand.image;

    // Explicit cleaning to ensure URL is valid
    if (url != null) {
      print("Original URL: '$url'");
      // Super aggressive cleaning
      url = url
          .replaceAll('`', '')
          .replaceAll('"', '')
          .replaceAll("'", '')
          .trim();

      // If comma exists, take substring, don't just rely on split
      int commaIndex = url.indexOf(',');
      if (commaIndex != -1) {
        url = url.substring(0, commaIndex).trim();
      }
      print("Cleaned URL: '$url'");
    }

    if (url == null || url.isEmpty) {
      return _buildAssetFallback(brand.name);
    }

    if (url.startsWith('gs://')) {
      return FutureBuilder<String>(
        future: FirebaseStorage.instance.refFromURL(url).getDownloadURL(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return CachedNetworkImage(
              imageUrl: snapshot.data!,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  const CircularProgressIndicator(strokeWidth: 2),
              errorWidget: (context, url, error) =>
                  _buildAssetFallback(brand.name),
            );
          }
          if (snapshot.hasError) return _buildAssetFallback(brand.name);
          return const SizedBox(
            width: 40,
            height: 40,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        },
      );
    }

    if (url.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        httpHeaders: const {
          'Accept': 'image/*',
        },
        cacheKey: url, // Ensure cache key matches cleaned URL
        placeholder: (context, url) =>
            const CircularProgressIndicator(strokeWidth: 2),
        errorWidget: (context, url, error) {
          debugPrint("Image error: $error");
          return const Icon(Icons.broken_image, color: Colors.red);
        },
      );
    }

    return Image.asset(
      url,
      width: 40,
      height: 40,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          _buildAssetFallback(brand.name),
    );
  }

  Widget _buildAssetFallback(String? brandName) {
    String cleanName =
        (brandName ?? '').trim().toLowerCase().replaceAll(' ', '_');
    if (cleanName.isEmpty) return const Icon(Icons.branding_watermark);

    return Image.asset(
      "images/sweets/$cleanName.png",
      width: 40,
      height: 40,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          "images/sweets/$cleanName.jpg",
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.branding_watermark),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: sh_background_color,
      appBar: AppBar(
        title: Text('Brand Management',
            style: GoogleFonts.workSans(
                color: sh_textColorPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: sh_white,
        iconTheme: const IconThemeData(color: sh_textColorPrimary),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('Brands').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());

          final brands = snapshot.data!.docs
              .map((doc) => AmBrand.fromQuerySnapshot(doc))
              .toList();

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: brands.length,
            separatorBuilder: (_, __) => 12.height,
            itemBuilder: (_, i) {
              final brand = brands[i];
              return Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: defaultBoxShadow(shadowColor: appShadowColor)),
                child: ListTile(
                  leading: _buildBrandIcon(brand),
                  title: Text(brand.name ?? 'No Name', style: boldTextStyle()),
                  subtitle: Text('ID: ${brand.id}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: sh_colorPrimary),
                        onPressed: () {
                          AddBrandScreen(brand: brand).launch(context);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          bool? confirm = await showConfirmDialog(
                              context, 'Delete ${brand.name}?');
                          if (confirm == true && brand.docId != null) {
                            await FirebaseFirestore.instance
                                .collection('Brands')
                                .doc(brand.docId)
                                .delete();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: sh_colorPrimary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          const AddBrandScreen().launch(context);
        },
      ),
    );
  }
}
