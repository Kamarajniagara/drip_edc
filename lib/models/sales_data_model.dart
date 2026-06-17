import 'dart:ui';

class SalesDataModel {
  Map<String, List<Category>>? graph;
  List<Category>? category;
  int? total;

  SalesDataModel({this.graph, this.category, this.total});

  factory SalesDataModel.fromJson(Map<String, dynamic> json) {
    Map<String, List<Category>>? graphMap;
    if (json['data'] != null && json['data']['graph'] != null) {
      graphMap = {};
      json['data']['graph'].forEach((key, value) {
        graphMap![key] = (value as List).asMap().entries
            .map((entry) => Category.fromJson(entry.value, entry.key))
            .toList();
      });
    }

    List<Category>? categoryList;
    if (json['data'] != null && json['data']['categories'] != null) {
      categoryList = (json['data']['categories'] as List).asMap().entries
          .map((entry) => Category.fromJson(entry.value, entry.key))
          .toList();
    }
    int totalList = json['data']['total'] ?? 0;

    return SalesDataModel(graph: graphMap, category: categoryList, total: totalList);
  }
}

class Category {
  int categoryId;
  String categoryName;
  int totalProduct;
  Color color;

  Category({
    required this.categoryId,
    required this.categoryName,
    required this.totalProduct,
    required this.color,
  });

  factory Category.fromJson(Map<String, dynamic> json, int index) {
    return Category(
      categoryId: json['categoryId'],
      categoryName: json['categoryName'],
      totalProduct: json['totalProduct'] ?? 0,
      color: _parseColor(json['colorCode']),
    );
  }

  static Color _parseColor(String hexString) {
    if (!hexString.startsWith("0x") && !hexString.startsWith("#")) {
      hexString = "FF$hexString";
    }
    final color = int.parse(hexString, radix: 16);
    return Color(color);
  }
}