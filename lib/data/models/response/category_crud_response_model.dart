import 'dart:convert';
import 'category_response_model.dart';

class CategoryCrudResponseModel {
  final bool success;
  final String message;
  final Category? data;

  CategoryCrudResponseModel({
    required this.success,
    required this.message,
    this.data,
  });

  factory CategoryCrudResponseModel.fromJson(String str) =>
      CategoryCrudResponseModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory CategoryCrudResponseModel.fromMap(Map<String, dynamic> json) =>
      CategoryCrudResponseModel(
        success: json["success"] ?? json["status"] ?? false,
        message: json["message"] ?? "No message",
        data: json["data"] != null ? Category.fromMap(json["data"]) : null,
      );

  Map<String, dynamic> toMap() => {
    "success": success,
    "message": message,
    "data": data?.toMap(),
  };
}
