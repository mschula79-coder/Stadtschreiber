import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/category.dart';

class CategoryService {
  Future<List<CategoryNode>> loadCategories() async {
    final jsonString = await rootBundle.loadString(
      'assets/data/categories.json',
    );
    final List<dynamic> jsonList = jsonDecode(jsonString);

    return jsonList.map((e) => CategoryNode.fromJson(e)).toList();
  }
}
