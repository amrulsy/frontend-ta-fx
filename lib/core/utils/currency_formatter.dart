import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String formatToIDR(int amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }
}