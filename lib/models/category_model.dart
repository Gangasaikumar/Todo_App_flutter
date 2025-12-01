import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final int colorValue;

  CategoryModel({
    required this.id,
    required this.name,
    required this.colorValue,
  });

  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'colorValue': colorValue};
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      colorValue: json['colorValue'],
    );
  }
}
