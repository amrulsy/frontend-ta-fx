class UserRequestModel {
  final String name;
  final String email;
  final String password;
  final String? phone;
  final String roles;

  UserRequestModel({
    required this.name,
    required this.email,
    required this.password,
    this.phone,
    required this.roles,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'roles': roles,
    };
  }

  String toJson() {
    return '''{"name":"$name","email":"$email","password":"$password","phone":"$phone","roles":"$roles"}''';
  }
}