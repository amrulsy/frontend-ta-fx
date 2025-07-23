import 'dart:convert';

class UserResponseModel {
  final bool success;
  final String message;
  final List<UserData> data;

  UserResponseModel({
    required this.success,
    required this.message,
    required this.data,
  });

  factory UserResponseModel.fromJson(String str) =>
      UserResponseModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UserResponseModel.fromMap(Map<String, dynamic> json) =>
      UserResponseModel(
        success: json["success"],
        message: json["message"],
        data: List<UserData>.from(json["data"].map((x) => UserData.fromMap(x))),
      );

  Map<String, dynamic> toMap() => {
        "success": success,
        "message": message,
        "data": List<dynamic>.from(data.map((x) => x.toMap())),
      };
}

class UserCrudResponseModel {
  final bool success;
  final String message;
  final UserData? data;

  UserCrudResponseModel({
    required this.success,
    required this.message,
    this.data,
  });

  factory UserCrudResponseModel.fromJson(String str) =>
      UserCrudResponseModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UserCrudResponseModel.fromMap(Map<String, dynamic> json) =>
      UserCrudResponseModel(
        success: json["success"],
        message: json["message"],
        data: json["data"] != null ? UserData.fromMap(json["data"]) : null,
      );

  Map<String, dynamic> toMap() => {
        "success": success,
        "message": message,
        "data": data?.toMap(),
      };
}

class UserData {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String roles;
  final DateTime? emailVerifiedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserData({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.roles,
    this.emailVerifiedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory UserData.fromJson(String str) => UserData.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UserData.fromMap(Map<String, dynamic> json) => UserData(
        id: json["id"],
        name: json["name"],
        email: json["email"],
        phone: json["phone"],
        roles: json["roles"],
        emailVerifiedAt: json["email_verified_at"] != null
            ? DateTime.parse(json["email_verified_at"])
            : null,
        createdAt: json["created_at"] != null
            ? DateTime.parse(json["created_at"])
            : null,
        updatedAt: json["updated_at"] != null
            ? DateTime.parse(json["updated_at"])
            : null,
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "name": name,
        "email": email,
        "phone": phone,
        "roles": roles,
        "email_verified_at": emailVerifiedAt?.toIso8601String(),
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
      };

  UserData copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? roles,
    DateTime? emailVerifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserData(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      roles: roles ?? this.roles,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}