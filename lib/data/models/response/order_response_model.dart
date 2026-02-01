import 'dart:convert';

class OrderResponseModel {
  final int id;
  final String transactionTime;
  final int kasirId;
  final String kasirName;
  final int totalPrice;
  final int totalItem;
  final String paymentMethod;
  final List<OrderItemResponseModel> orderItems;

  OrderResponseModel({
    required this.id,
    required this.transactionTime,
    required this.kasirId,
    required this.kasirName,
    required this.totalPrice,
    required this.totalItem,
    required this.paymentMethod,
    required this.orderItems,
  });

  factory OrderResponseModel.fromJson(String str) =>
      OrderResponseModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory OrderResponseModel.fromMap(
    Map<String, dynamic> json,
  ) => OrderResponseModel(
    id: json["id"] is String ? int.tryParse(json["id"]) ?? 0 : json["id"] ?? 0,
    transactionTime: json["transaction_time"] ?? '',
    kasirId: json["kasir_id"] is String
        ? int.tryParse(json["kasir_id"]) ?? 0
        : json["kasir_id"] ?? 0,
    kasirName: json["kasir_name"] ?? '',
    totalPrice: json["total_price"] is String
        ? int.tryParse(json["total_price"]) ?? 0
        : json["total_price"] ?? 0,
    totalItem: json["total_item"] is String
        ? int.tryParse(json["total_item"]) ?? 0
        : json["total_item"] ?? 0,
    paymentMethod: json["payment_method"] ?? 'cash',
    orderItems: json["order_items"] != null
        ? List<OrderItemResponseModel>.from(
            json["order_items"].map((x) => OrderItemResponseModel.fromMap(x)),
          )
        : [],
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "transaction_time": transactionTime,
    "kasir_id": kasirId,
    "kasir_name": kasirName,
    "total_price": totalPrice,
    "total_item": totalItem,
    "payment_method": paymentMethod,
    "order_items": List<dynamic>.from(orderItems.map((x) => x.toMap())),
  };
}

class OrderItemResponseModel {
  final int id;
  final int productId;
  final String productName;
  final int quantity;
  final int price;

  OrderItemResponseModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
  });

  factory OrderItemResponseModel.fromJson(String str) =>
      OrderItemResponseModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory OrderItemResponseModel.fromMap(Map<String, dynamic> json) =>
      OrderItemResponseModel(
        id: json["id"] is String
            ? int.tryParse(json["id"]) ?? 0
            : json["id"] ?? 0,
        productId: json["product_id"] is String
            ? int.tryParse(json["product_id"]) ?? 0
            : json["product_id"] ?? 0,
        productName: json["product_name"] ?? '',
        quantity: json["quantity"] is String
            ? int.tryParse(json["quantity"]) ?? 0
            : json["quantity"] ?? 0,
        price: json["price"] is String
            ? int.tryParse(json["price"]) ?? 0
            : json["price"] ?? 0,
      );

  Map<String, dynamic> toMap() => {
    "id": id,
    "product_id": productId,
    "product_name": productName,
    "quantity": quantity,
    "price": price,
  };
}
