import 'dart:convert';

class ProductSalesResponseModel {
  final String status;
  final List<ProductSales> data;

  ProductSalesResponseModel({required this.status, required this.data});

  factory ProductSalesResponseModel.fromMap(Map<String, dynamic> map) {
    return ProductSalesResponseModel(
      status: map['status'] as String,
      data: List<ProductSales>.from(
        map["data"].map((x) => ProductSales.fromMap(x)),
      ),
    );
  }

  factory ProductSalesResponseModel.fromJson(String source) =>
      ProductSalesResponseModel.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );
}

class ProductSales {
  final int productId;
  final String productName;
  final int productPrice;
  final String totalQuantity;
  final String totalPrice;

  ProductSales({
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.totalQuantity,
    required this.totalPrice,
  });

  factory ProductSales.fromMap(Map<String, dynamic> map) {
    return ProductSales(
      productId: map['product_id'] is String
          ? int.tryParse(map['product_id']) ?? 0
          : map['product_id'] ?? 0,
      productName: map['product_name'] ?? '',
      productPrice: map['product_price'] is String
          ? int.tryParse(map['product_price']) ?? 0
          : map['product_price'] ?? 0,
      totalQuantity: map['total_quantity']?.toString() ?? '0',
      totalPrice: map['total_price']?.toString() ?? '0',
    );
  }

  factory ProductSales.fromJson(String source) =>
      ProductSales.fromMap(json.decode(source) as Map<String, dynamic>);
}
