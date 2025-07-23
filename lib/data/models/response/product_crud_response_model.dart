import 'dart:convert';
import 'product_response_model.dart';

class ProductCrudResponseModel {
  final bool success;
  final String message;
  final Product? data;

  ProductCrudResponseModel({
    required this.success,
    required this.message,
    this.data,
  });

  factory ProductCrudResponseModel.fromJson(String str) =>
      ProductCrudResponseModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ProductCrudResponseModel.fromMap(Map<String, dynamic> json) =>
      ProductCrudResponseModel(
        success: json["success"] ?? false,
        message: json["message"],
        data: json["data"] != null ? Product.fromMap(json["data"]) : null,
      );

  Map<String, dynamic> toMap() => {
    "success": success,
    "message": message,
    "data": data?.toMap(),
  };
}
