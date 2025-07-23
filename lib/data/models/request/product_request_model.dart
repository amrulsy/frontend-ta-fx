
import 'package:image_picker/image_picker.dart';

class ProductRequestModel {
  final String name;
  final int price;
  final int stock;
  final int categoryId;
  final int isBestSeller;
  final XFile image;
  final String? description;
  ProductRequestModel({
    required this.name,
    required this.price,
    required this.stock,
    required this.categoryId,
    required this.isBestSeller,
    required this.image,
    this.description,
  });

  Map<String, String> toMap() {
    final map = {
      'name': name,
      'price': price.toString(),
      'stock': stock.toString(),
      'category_id': categoryId.toString(),
      'is_best_seller': isBestSeller.toString(),
    };
    if (description != null) {
      map['description'] = description!;
    }
    return map;
  }
}
