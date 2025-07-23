class CategoryRequestModel {
  final String name;

  CategoryRequestModel({required this.name});

  Map<String, String> toMap() {
    return {'name': name};
  }
}
