import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:american_sweets/models/AmCategory.dart';
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/utils/AmConstant.dart';
import 'package:american_sweets/utils/AmStrings.dart';
import 'package:american_sweets/screens/AddCategoryScreen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({Key? key}) : super(key: key);

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  Widget _buildCategoryIcon(AmCategory cat) {
    String? url = cat.image;
    if (url == null || url.isEmpty) {
      return _buildAssetFallback(cat.name);
    }

    if (url.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url,
        width: 40,
        height: 40,
        memCacheWidth: 90,
        memCacheHeight: 90,
        fit: BoxFit.cover,
        placeholder: (context, url) =>
            const CircularProgressIndicator(strokeWidth: 2),
        errorWidget: (context, url, error) => _buildAssetFallback(cat.name),
      );
    }

    return Image.asset(
      url,
      width: 40,
      height: 40,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          _buildAssetFallback(cat.name),
    );
  }

  Widget _buildAssetFallback(String? categoryName) {
    String cleanName =
        (categoryName ?? '').trim().toLowerCase().replaceAll(' ', '_');
    if (cleanName.isEmpty) return const Icon(Icons.category);

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
              const Icon(Icons.category),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: sh_background_color,
      appBar: AppBar(
        title: Text('Category Management',
            style: GoogleFonts.workSans(
                color: sh_textColorPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: sh_white,
        iconTheme: const IconThemeData(color: sh_textColorPrimary),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('Categories').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());

          final categories = snapshot.data!.docs
              .map((doc) => AmCategory.fromQuerySnapshot(doc))
              .toList();

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            separatorBuilder: (_, __) => 12.height,
            itemBuilder: (_, i) {
              final cat = categories[i];
              return Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: defaultBoxShadow(shadowColor: appShadowColor)),
                child: ListTile(
                  leading: _buildCategoryIcon(cat),
                  title: Text(cat.name ?? 'No Name', style: boldTextStyle()),
                  subtitle: Text('ID: ${cat.id}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: sh_colorPrimary),
                        onPressed: () {
                          AddCategoryScreen(category: cat).launch(context);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          bool? confirm = await showConfirmDialog(
                              context, 'Delete ${cat.name}?');
                          if (confirm == true && cat.docId != null) {
                            await FirebaseFirestore.instance
                                .collection('Categories')
                                .doc(cat.docId)
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
          const AddCategoryScreen().launch(context);
        },
      ),
    );
  }
}
