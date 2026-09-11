import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:american_sweets/models/AmCategory.dart';
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/utils/AmConstant.dart';
import 'package:american_sweets/utils/AmStrings.dart';
import 'package:american_sweets/screens/AddCategoryScreen.dart';
import 'package:american_sweets/utils/CategoryHelper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({Key? key}) : super(key: key);

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  List<CategoryNode> _categoryTree = [];
  final Map<String, bool> _expandedState = {};
  List<AmCategory> _cachedCategories = [];
  bool _isLoading = true;
  StreamSubscription<QuerySnapshot>? _categoriesSubscription;

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
  void dispose() {
    _categoriesSubscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _setupCategoriesListener();
  }

  void _setupCategoriesListener() {
    setState(() => _isLoading = true);
    _categoriesSubscription = FirebaseFirestore.instance
        .collection('Categories')
        .snapshots()
        .listen((snapshot) {
      final categories = snapshot.docs
          .map((doc) => AmCategory.fromQuerySnapshot(doc))
          .toList();
      
      if (mounted) {
        setState(() {
          _cachedCategories = categories;
          _categoryTree = CategoryHelper.organizeCategories(categories);
          _syncExpansionStates(_categoryTree);
          _isLoading = false;
        });
      }
    }, onError: (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        toast('Error loading categories: $e');
      }
    });
  }

  Future<void> _loadCategories() async {
    // Manual refresh - cancel and restart the subscription
    _categoriesSubscription?.cancel();
    _setupCategoriesListener();
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCategories,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildCategoryList(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: sh_colorPrimary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          const AddCategoryScreen().launch(context);
        },
      ),
    );
  }

  Widget _buildCategoryList() {
    // Flatten the tree for display (show all, but children only when parent is expanded)
    final flattenedList = CategoryHelper.flattenTree(_categoryTree, expandedOnly: true);

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: flattenedList.length,
      separatorBuilder: (_, __) => 8.height,
      itemBuilder: (_, i) {
        final node = flattenedList[i];
        final cat = node.category;
        final hasChildren = CategoryHelper.hasSubcategories(node);
        final isExpanded = _expandedState[cat.docId] ?? false;

        final isSubcategory = node.category.parent != null && node.category.parent != -999999 && node.category.parent != 0;
        
        return Container(
          margin: EdgeInsets.only(
            left: isSubcategory ? 32.0 : 0.0, // More prominent indentation for subcategories
          ),
          decoration: BoxDecoration(
              color: isSubcategory ? Colors.grey[50] : Colors.white, // Different background for subcategories
              borderRadius: BorderRadius.circular(16),
              border: isSubcategory 
                  ? Border.all(color: Colors.grey[300]!, width: 1) 
                  : null,
              boxShadow: !isSubcategory ? defaultBoxShadow(shadowColor: appShadowColor) : null),
          child: ListTile(
            contentPadding: EdgeInsets.only(
              left: 16.0,
              right: 8.0,
            ),
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasChildren)
                  Container(
                    decoration: BoxDecoration(
                      color: sh_colorPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: sh_colorPrimary,
                      ),
                      onPressed: () {
                        setState(() {
                          _expandedState[cat.docId!] = !isExpanded;
                          // Update all nodes in the tree
                          _updateExpansionState(_categoryTree, cat.docId!, !isExpanded);
                        });
                      },
                      tooltip: isExpanded ? 'Collapse subcategories' : 'Expand subcategories',
                    ),
                  ),
                if (!hasChildren && isSubcategory)
                  Container(
                    width: 40,
                    height: 40,
                    margin: EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.subdirectory_arrow_right, color: Colors.grey[600], size: 20),
                  ),
                _buildCategoryIcon(cat),
              ],
            ),
            title: Text(
              cat.name ?? 'No Name', 
              style: boldTextStyle(
                color: isSubcategory ? Colors.grey[700] : sh_textColorPrimary,
                size: isSubcategory ? 15 : 16,
              ),
            ),
            subtitle: isSubcategory 
                ? Text('Subcategory of ID: ${node.category.parent}', style: secondaryTextStyle(size: 12, color: Colors.grey[600]))
                : Text('ID: ${cat.id}${hasChildren ? ' • ${node.children.length} subcategories • Tap ↓ to expand' : ''}', style: secondaryTextStyle(size: 12)),
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
                      // Refresh the list after deletion
                      _loadCategories();
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _updateExpansionState(List<CategoryNode> tree, String docId, bool isExpanded) {
    for (var node in tree) {
      if (node.category.docId == docId) {
        node.isExpanded = isExpanded;
        return;
      }
      _updateExpansionState(node.children, docId, isExpanded);
    }
  }

  void _syncExpansionStates(List<CategoryNode> tree) {
    for (var node in tree) {
      if (node.category.docId != null) {
        node.isExpanded = _expandedState[node.category.docId!] ?? false;
      }
      _syncExpansionStates(node.children);
    }
  }
}
