import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

part 'category_model.g.dart';

@collection
class CategoryModel {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  final String id;
  final String name;
  final int colorValue;

  CategoryModel({
    required this.id,
    required this.name,
    required this.colorValue,
  });

  @ignore
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
