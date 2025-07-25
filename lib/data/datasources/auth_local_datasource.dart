import 'package:project_ta/data/models/response/auth_response_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthLocalDatasource {
  Future<void> saveAuthData(AuthResponseModel authResponseModel) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_data', authResponseModel.toJson());
  }

  Future<void> removeAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_data');
  }

  Future<AuthResponseModel> getAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    final authData = prefs.getString('auth_data');

    return AuthResponseModel.fromJson(authData!);
  }

  Future<bool> isAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final authData = prefs.getString('auth_data');

    return authData != null;
  }

  Future<void> saveMidtransServerKey(String serverKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_key', serverKey);
  }

  //get midtrans server key
  Future<String> getMitransServerKey() async {
    final prefs = await SharedPreferences.getInstance();
    final serverKey = prefs.getString('server_key');
    return serverKey ?? '';
  }

  Future<void> savePrinter(String printer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('printer', printer);
  }

  Future<void> saveSizePrinter(String size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('size', size);
  }

  Future<String> getSizePrinter() async {
    final prefs = await SharedPreferences.getInstance();
    final size = prefs.getString('size');
    return size ?? '58mm';
  }

  Future<String> getPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    final printer = prefs.getString('printer');
    return printer ?? '';
  }
}
