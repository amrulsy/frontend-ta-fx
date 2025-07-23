import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import 'package:project_ta/core/constants/variables.dart';
import 'package:project_ta/data/datasources/auth_local_datasource.dart';
import 'package:project_ta/data/models/request/user_request_model.dart';
import 'package:project_ta/data/models/request/user_update_request_model.dart';
import 'package:project_ta/data/models/response/user_response_model.dart';

class UserRemoteDatasource {
  Future<Either<String, UserResponseModel>> getUsers() async {
    final authData = await AuthLocalDatasource().getAuthData();
    final Map<String, String> headers = {
      'Authorization': 'Bearer ${authData.token}',
      'Content-Type': 'application/json',
    };

    final response = await http.get(
      Uri.parse('${Variables.baseUrl}/api/users'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return right(UserResponseModel.fromJson(response.body));
    } else {
      return left(response.body);
    }
  }

  Future<Either<String, UserCrudResponseModel>> getUser(int id) async {
    final authData = await AuthLocalDatasource().getAuthData();
    final Map<String, String> headers = {
      'Authorization': 'Bearer ${authData.token}',
      'Content-Type': 'application/json',
    };

    final response = await http.get(
      Uri.parse('${Variables.baseUrl}/api/users/$id'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return right(UserCrudResponseModel.fromJson(response.body));
    } else {
      return left(response.body);
    }
  }

  Future<Either<String, UserCrudResponseModel>> createUser(
    UserRequestModel userRequestModel,
  ) async {
    final authData = await AuthLocalDatasource().getAuthData();
    final Map<String, String> headers = {
      'Authorization': 'Bearer ${authData.token}',
      'Content-Type': 'application/json',
    };

    final response = await http.post(
      Uri.parse('${Variables.baseUrl}/api/users'),
      headers: headers,
      body: userRequestModel.toJson(),
    );

    if (response.statusCode == 201) {
      return right(UserCrudResponseModel.fromJson(response.body));
    } else {
      return left(response.body);
    }
  }

  Future<Either<String, UserCrudResponseModel>> updateUser(
    int id,
    UserUpdateRequestModel userUpdateRequestModel,
  ) async {
    final authData = await AuthLocalDatasource().getAuthData();
    final Map<String, String> headers = {
      'Authorization': 'Bearer ${authData.token}',
      'Content-Type': 'application/json',
    };

    final response = await http.put(
      Uri.parse('${Variables.baseUrl}/api/users/$id'),
      headers: headers,
      body: userUpdateRequestModel.toJson(),
    );

    if (response.statusCode == 200) {
      return right(UserCrudResponseModel.fromJson(response.body));
    } else {
      return left(response.body);
    }
  }

  Future<Either<String, UserCrudResponseModel>> deleteUser(int id) async {
    final authData = await AuthLocalDatasource().getAuthData();
    final Map<String, String> headers = {
      'Authorization': 'Bearer ${authData.token}',
      'Content-Type': 'application/json',
    };

    final response = await http.delete(
      Uri.parse('${Variables.baseUrl}/api/users/$id'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return right(UserCrudResponseModel.fromJson(response.body));
    } else {
      return left(response.body);
    }
  }
}