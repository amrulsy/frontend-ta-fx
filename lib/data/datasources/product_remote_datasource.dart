import 'package:dartz/dartz.dart';
import 'package:project_ta/core/constants/variables.dart';
import 'package:project_ta/data/models/request/product_request_model.dart';
import 'package:project_ta/data/models/request/product_update_request_model.dart';
import 'package:project_ta/data/models/response/add_product_response_model.dart';
import 'package:project_ta/data/models/response/product_crud_response_model.dart';
import 'package:http/http.dart' as http;
import 'package:project_ta/data/models/response/product_response_model.dart';

import '../models/response/category_response_model.dart';
import 'auth_local_datasource.dart';

class ProductRemoteDatasource {
  Future<Either<String, ProductResponseModel>> getProducts() async {
    final authData = await AuthLocalDatasource().getAuthData();
    if (authData == null) return left('User belum login');
    final response = await http.get(
      Uri.parse('${Variables.baseUrl}/api/products'),
      headers: {'Authorization': 'Bearer ${authData.token}'},
    );

    if (response.statusCode == 200) {
      return right(ProductResponseModel.fromJson(response.body));
    } else {
      return left(response.body);
    }
  }

  Future<Either<String, AddProductResponseModel>> addProduct(
    ProductRequestModel productRequestModel,
  ) async {
    final authData = await AuthLocalDatasource().getAuthData();
    if (authData == null) return left('User belum login');
    final Map<String, String> headers = {
      'Authorization': 'Bearer ${authData.token}',
    };
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${Variables.baseUrl}/api/products'),
    );
    request.fields.addAll(productRequestModel.toMap());
    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        productRequestModel.image.path,
      ),
    );
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    final String body = await response.stream.bytesToString();

    if (response.statusCode == 201) {
      return right(AddProductResponseModel.fromJson(body));
    } else {
      return left(body);
    }
  }

  //get categories
  Future<Either<String, CategoryResponseModel>> getCategories() async {
    final authData = await AuthLocalDatasource().getAuthData();
    if (authData == null) return left('User belum login');
    final response = await http.get(
      Uri.parse('${Variables.baseUrl}/api/categories'),
      headers: {
        'Authorization': 'Bearer ${authData.token}',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return right(CategoryResponseModel.fromJson(response.body));
    } else {
      return left(response.body);
    }
  }

  // Get single product
  Future<Either<String, ProductCrudResponseModel>> getProduct(int id) async {
    final authData = await AuthLocalDatasource().getAuthData();
    if (authData == null) return left('User belum login');
    final response = await http.get(
      Uri.parse('${Variables.baseUrl}/api/products/$id'),
      headers: {
        'Authorization': 'Bearer ${authData.token}',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return right(ProductCrudResponseModel.fromJson(response.body));
    } else {
      return left(response.body);
    }
  }

  // Update product
  Future<Either<String, ProductCrudResponseModel>> updateProduct(
    int id,
    ProductUpdateRequestModel productRequestModel,
  ) async {
    final authData = await AuthLocalDatasource().getAuthData();
    if (authData == null) return left('User belum login');
    final Map<String, String> headers = {
      'Authorization': 'Bearer ${authData.token}',
    };

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${Variables.baseUrl}/api/products/$id'),
    );

    // Add _method field for Laravel to treat it as PUT
    request.fields['_method'] = 'PUT';
    request.fields.addAll(productRequestModel.toMap());

    if (productRequestModel.image != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          productRequestModel.image!.path,
        ),
      );
    }

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();
    final String body = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return right(ProductCrudResponseModel.fromJson(body));
    } else {
      return left(body);
    }
  }

  // Delete product
  Future<Either<String, ProductCrudResponseModel>> deleteProduct(int id) async {
    final authData = await AuthLocalDatasource().getAuthData();
    if (authData == null) return left('User belum login');
    final response = await http.delete(
      Uri.parse('${Variables.baseUrl}/api/products/$id'),
      headers: {
        'Authorization': 'Bearer ${authData.token}',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return right(ProductCrudResponseModel.fromJson(response.body));
    } else {
      return left(response.body);
    }
  }

  // Update product stock only
  Future<Either<String, ProductCrudResponseModel>> updateProductStock(
    Product product,
    int newStock,
  ) async {
    final requestModel = ProductUpdateRequestModel(
      name: product.name,
      price: product.price,
      stock: newStock,
      categoryId: product.categoryId,
      isBestSeller: product.isBestSeller ? 1 : 0,
      description: product.description,
      // image is optional, if null backend should keep existing image
      image: null,
    );

    // Use productId (server ID) if available (from local DB), otherwise use id (from API)
    final idToUpdate = product.productId ?? product.id!;
    return updateProduct(idToUpdate, requestModel);
  }
}
