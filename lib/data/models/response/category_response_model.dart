import 'dart:convert';

class CategoryResponseModel {
  final bool status;
  final String message;
  final List<Category> data;

  CategoryResponseModel({
    required this.status,
    required this.message,
    required this.data,
  });

  factory CategoryResponseModel.fromJson(String str) =>
      CategoryResponseModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory CategoryResponseModel.fromMap(Map<String, dynamic> json) =>
      CategoryResponseModel(
        status: json["status"] ?? json["success"] ?? false,
        message: json["message"] ?? "No message",
        data: json["data"] != null
            ? List<Category>.from(json["data"].map((x) => Category.fromMap(x)))
            : [],
      );

  Map<String, dynamic> toMap() => {
    "status": status,
    "message": message,
    "data": List<dynamic>.from(data.map((x) => x.toMap())),
  };
}

class Category {
  final int id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromJson(String str) => Category.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory Category.fromMap(Map<String, dynamic> json) => Category(
    id: json["id"] is String ? int.tryParse(json["id"]) ?? 0 : json["id"] ?? 0,
    name: json["name"] ?? "",
  );

  factory Category.fromLocal(Map<String, dynamic> json) =>
      Category(id: json["category_id"] ?? 0, name: json["name"] ?? "");

  Map<String, dynamic> toMap() => {"category_id": id, "name": name};

  @override
  String toString() => name;
}
