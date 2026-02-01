import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import 'package:project_ta/core/constants/variables.dart';
import 'package:project_ta/data/models/request/category_request_model.dart';
import 'package:project_ta/data/models/response/category_response_model.dart';
import 'package:project_ta/data/models/response/category_crud_response_model.dart';
import 'auth_local_datasource.dart';

class CategoryRemoteDatasource {
  // Get all categories
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

  // Create category
  Future<Either<String, CategoryCrudResponseModel>> createCategory(
    CategoryRequestModel categoryRequestModel,
  ) async {
    final authData = await AuthLocalDatasource().getAuthData();
    if (authData == null) return left('User belum login');
    final response = await http.post(
      Uri.parse('${Variables.baseUrl}/api/categories'),
      headers: {
        'Authorization': 'Bearer ${authData.token}',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode(categoryRequestModel.toMap()),
    );

    if (response.statusCode == 201) {
      return right(CategoryCrudResponseModel.fromJson(response.body));
    } else {
      return left(response.body);
    }
  }

  // Update category
  Future<Either<String, CategoryCrudResponseModel>> updateCategory(
    int id,
    CategoryRequestModel categoryRequestModel,
  ) async {
    final authData = await AuthLocalDatasource().getAuthData();
    if (authData == null) return left('User belum login');
    final response = await http.put(
      Uri.parse('${Variables.baseUrl}/api/categories/$id'),
      headers: {
        'Authorization': 'Bearer ${authData.token}',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode(categoryRequestModel.toMap()),
    );

    if (response.statusCode == 200) {
      return right(CategoryCrudResponseModel.fromJson(response.body));
    } else {
      return left(response.body);
    }
  }

  // Delete category
  Future<Either<String, CategoryCrudResponseModel>> deleteCategory(
    int id,
  ) async {
    final authData = await AuthLocalDatasource().getAuthData();
    if (authData == null) return left('User belum login');
    final response = await http.delete(
      Uri.parse('${Variables.baseUrl}/api/categories/$id'),
      headers: {
        'Authorization': 'Bearer ${authData.token}',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return right(CategoryCrudResponseModel.fromJson(response.body));
    } else {
      return left(response.body);
    }
  }
}
