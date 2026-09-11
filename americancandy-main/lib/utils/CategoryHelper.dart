import 'package:american_sweets/models/AmCategory.dart';

class CategoryNode {
  final AmCategory category;
  final List<CategoryNode> children;
  bool isExpanded;
  final int level;

  CategoryNode({
    required this.category,
    this.children = const [],
    this.isExpanded = false,
    this.level = 0,
  });
}

class CategoryHelper {
  static const int rootParentId = -999999;

  /// Organizes categories into a hierarchical tree structure
  static List<CategoryNode> organizeCategories(List<AmCategory> categories) {
    // Separate root categories and create a map for quick lookup
    final Map<int, AmCategory> categoryMap = {};
    final List<AmCategory> rootCategories = [];

    for (var cat in categories) {
      if (cat.id != null) {
        categoryMap[cat.id!] = cat;
      }
      // Root categories have parent as null, 0, or -999999
      if (cat.parent == null || cat.parent == 0 || cat.parent == rootParentId) {
        rootCategories.add(cat);
      }
    }

    // Build the tree structure
    final List<CategoryNode> tree = [];
    for (var rootCat in rootCategories) {
      final node = _buildCategoryNode(rootCat, categoryMap, 0);
      tree.add(node);
    }

    // Sort by menu_order
    tree.sort((a, b) {
      final aOrder = a.category.menuOrder ?? 0;
      final bOrder = b.category.menuOrder ?? 0;
      return aOrder.compareTo(bOrder);
    });

    return tree;
  }

  static CategoryNode _buildCategoryNode(
      AmCategory category, Map<int, AmCategory> categoryMap, int level) {
    final List<CategoryNode> children = [];

    // Find all categories that have this category as parent
    if (category.id != null) {
      for (var cat in categoryMap.values) {
        if (cat.parent == category.id) {
          children.add(_buildCategoryNode(cat, categoryMap, level + 1));
        }
      }
    }

    // Sort children by menu_order
    children.sort((a, b) {
      final aOrder = a.category.menuOrder ?? 0;
      final bOrder = b.category.menuOrder ?? 0;
      return aOrder.compareTo(bOrder);
    });

    return CategoryNode(
      category: category,
      children: children,
      level: level,
    );
  }

  /// Flattens the tree into a list for sequential display
  static List<CategoryNode> flattenTree(List<CategoryNode> tree, {bool expandedOnly = false}) {
    final List<CategoryNode> result = [];
    
    void traverse(CategoryNode node) {
      result.add(node);
      // Only add children if:
      // 1. expandedOnly is false (show everything), OR
      // 2. The current node is expanded (show its children)
      if (!expandedOnly || node.isExpanded) {
        for (var child in node.children) {
          traverse(child);
        }
      }
    }
    
    for (var node in tree) {
      traverse(node);
    }
    
    return result;
  }

  /// Counts total categories including subcategories
  static int countCategories(List<CategoryNode> tree) {
    int count = 0;
    
    void traverse(CategoryNode node) {
      count++;
      for (var child in node.children) {
        traverse(child);
      }
    }
    
    for (var node in tree) {
      traverse(node);
    }
    
    return count;
  }

  /// Checks if a category has subcategories
  static bool hasSubcategories(CategoryNode node) {
    return node.children.isNotEmpty;
  }
}
