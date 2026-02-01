import 'package:project_ta/core/constants/variables.dart';
import 'package:project_ta/data/models/request/order_request_model.dart';
import 'package:http/http.dart' as http;
import 'package:project_ta/data/models/response/order_response_model.dart';
import 'dart:convert';

import 'auth_local_datasource.dart';

class OrderRemoteDatasource {
  Future<bool> sendOrder(OrderRequestModel requestModel) async {
    try {
      final url = Uri.parse('${Variables.baseUrl}/api/orders');
      final authData = await AuthLocalDatasource().getAuthData();
      if (authData == null) return false;
      final Map<String, String> headers = {
        'Authorization': 'Bearer ${authData.token}',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      final requestBody = requestModel.toJson();
      print('=== SYNC ORDER REQUEST ===');
      print('URL: $url');
      print('Request Body: $requestBody');

      final response = await http.post(
        url,
        headers: headers,
        body: requestBody,
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 201) {
        print('✅ Order synced successfully');
        return true;
      } else {
        print('❌ Order sync failed with status ${response.statusCode}');
        print('Error response: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      print('❌ Exception during order sync: $e');
      print('StackTrace: $stackTrace');
      return false;
    }
  }

  Future<List<OrderResponseModel>> getOrders() async {
    try {
      final url = Uri.parse('${Variables.baseUrl}/api/orders');
      final authData = await AuthLocalDatasource().getAuthData();
      if (authData == null) return [];
      final Map<String, String> headers = {
        'Authorization': 'Bearer ${authData.token}',
        'Accept': 'application/json',
      };

      print('=== FETCHING ORDERS FROM API ===');
      print('URL: $url');

      final response = await http.get(url, headers: headers);

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('Parsed data keys: ${data.keys.toList()}');

        final List<dynamic> ordersJson = data['data'] ?? [];
        print('Orders array length: ${ordersJson.length}');

        if (ordersJson.isNotEmpty) {
          print('First order sample: ${ordersJson[0]}');
        }

        final orders = ordersJson
            .map((json) => OrderResponseModel.fromMap(json))
            .toList();

        print('✅ Fetched ${orders.length} orders from API');
        return orders;
      } else {
        print('❌ Failed to fetch orders: ${response.statusCode}');
        print('Error response: ${response.body}');
        return [];
      }
    } catch (e, stackTrace) {
      print('❌ Exception during fetch orders: $e');
      print('StackTrace: $stackTrace');
      return [];
    }
  }
}
