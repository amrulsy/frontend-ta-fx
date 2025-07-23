class UserUpdateRequestModel {
  final String? name;
  final String? email;
  final String? password;
  final String? phone;
  final String? roles;

  UserUpdateRequestModel({
    this.name,
    this.email,
    this.password,
    this.phone,
    this.roles,
  });

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {};
    if (name != null) map['name'] = name;
    if (email != null) map['email'] = email;
    if (password != null && password!.isNotEmpty) map['password'] = password;
    if (phone != null) map['phone'] = phone;
    if (roles != null) map['roles'] = roles;
    return map;
  }

  String toJson() {
    final map = toMap();
    String json = '{';
    final entries = map.entries.toList();
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      json += '"${entry.key}":"${entry.value}"';
      if (i < entries.length - 1) json += ',';
    }
    json += '}';
    return json;
  }
}