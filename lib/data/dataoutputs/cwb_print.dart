import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/services.dart';
import 'package:project_ta/core/extensions/int_ext.dart';
import 'package:project_ta/core/extensions/string_ext.dart';
import 'package:project_ta/data/datasources/auth_local_datasource.dart';
import 'package:intl/intl.dart';
import 'package:image/image.dart' as img;
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import '../../presentation/home/models/order_item.dart';

class CwbPrint {
  CwbPrint._init();

  static final CwbPrint instance = CwbPrint._init();

  Future<void> printReceipt(List<int> printValue) async {
    try {
      await PrintBluetoothThermal.writeBytes(printValue);
    } on PlatformException catch (e) {
      print('Error: $e');
    }
  }

  Future<List<int>> printOrder(
    List<OrderItem> products,
    int totalQuantity,
    int totalPrice,
    String paymentMethod,
    int nominalBayar,
    String namaKasir,
  ) async {
    List<int> bytes = [];

    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);

    final ByteData data = await rootBundle.load('assets/logo/mylogo.png');
    final Uint8List bytesData = data.buffer.asUint8List();
    final img.Image? orginalImage = img.decodeImage(bytesData);
    bytes += generator.reset();

    if (orginalImage != null) {
      final img.Image grayscalledImage = img.grayscale(orginalImage);
      final img.Image resizedImage =
          img.copyResize(grayscalledImage, width: 240);
      bytes += generator.imageRaster(resizedImage, align: PosAlign.center);
      bytes += generator.feed(2);
    }

    bytes += generator.text('Bengkel MMT Racing',
        styles: const PosStyles(
          bold: true,
          align: PosAlign.center,
          height: PosTextSize.size1,
          width: PosTextSize.size1,
        ));

    bytes += generator.text('Cilacap 2025',
        styles: const PosStyles(bold: false, align: PosAlign.center));
    bytes += generator.text(
        'Date : ${DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now())}',
        styles: const PosStyles(bold: false, align: PosAlign.center));

    bytes += generator.feed(1);
    bytes += generator.text('Order Items:',
        styles: const PosStyles(bold: false, align: PosAlign.center));

    for (final product in products) {
      bytes += generator.text(product.product.name,
          styles: const PosStyles(align: PosAlign.left));

      bytes += generator.row([
        PosColumn(
          text: '${product.product.price} x ${product.quantity}',
          width: 8,
          styles: const PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          text: '${product.product.price * product.quantity}'.currencyFormatRp,
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    bytes += generator.feed(1);

    bytes += generator.row([
      PosColumn(
        text: 'Total',
        width: 6,
        styles: const PosStyles(align: PosAlign.left),
      ),
      PosColumn(
        text: totalPrice.currencyFormatRp,
        width: 6,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    bytes += generator.row([
      PosColumn(
        text: 'Pay',
        width: 6,
        styles: const PosStyles(align: PosAlign.left),
      ),
      PosColumn(
        text: nominalBayar.currencyFormatRp,
        width: 6,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    bytes += generator.row([
      PosColumn(
        text: 'Payment Method',
        width: 8,
        styles: const PosStyles(align: PosAlign.left),
      ),
      PosColumn(
        text: paymentMethod == 'QRIS' ? 'QRIS' : 'Cash',
        width: 4,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    bytes += generator.feed(1);
    bytes += generator.text('Thank you for coming',
        styles: const PosStyles(bold: false, align: PosAlign.center));
    bytes += generator.feed(3);

    return bytes;
  }

  Future<List<int>> printChecker(
    List<OrderItem> products,
    int tableNumber,
    String draftName,
    String cashierName,
  ) async {
    List<int> bytes = [];
    final sizePrinter = await AuthLocalDatasource().getSizePrinter();
    final profile = await CapabilityProfile.load();

    final generator = Generator(
        sizePrinter == '58mm' ? PaperSize.mm58 : PaperSize.mm80, profile);

    bytes += generator.reset();

    bytes += generator.text('Table Checker',
        styles: const PosStyles(
          bold: true,
          align: PosAlign.center,
          height: PosTextSize.size1,
          width: PosTextSize.size1,
        ));
    bytes += generator.feed(1);
    bytes += generator.text(tableNumber.toString(),
        styles: const PosStyles(
          bold: true,
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ));
    bytes += generator.feed(1);

    bytes += generator.row([
      PosColumn(
        text: 'Date',
        width: 4,
        styles: const PosStyles(align: PosAlign.left),
      ),
      PosColumn(
        text: ': ${DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now())}',
        width: 8,
        styles: const PosStyles(align: PosAlign.left),
      ),
    ]);

    bytes += generator.row([
      PosColumn(
        text: 'Receipt',
        width: 4,
        styles: const PosStyles(align: PosAlign.left),
      ),
      PosColumn(
        text: ': JF-${DateFormat('yyyyMMddhhmm').format(DateTime.now())}',
        width: 8,
        styles: const PosStyles(align: PosAlign.left),
      ),
    ]);
//cashier name
    bytes += generator.row([
      PosColumn(
        text: 'Cashier',
        width: 4,
        styles: const PosStyles(align: PosAlign.left),
      ),
      PosColumn(
        text: ': $cashierName',
        width: 8,
        styles: const PosStyles(align: PosAlign.left),
      ),
    ]);

    bytes += generator.row([
      PosColumn(
        text: 'Customer',
        width: 4,
        styles: const PosStyles(align: PosAlign.left),
      ),
      PosColumn(
        text: ': $draftName',
        width: 8,
        styles: const PosStyles(align: PosAlign.left),
      ),
    ]);
    bytes += generator.text('DINE IN',
        styles: const PosStyles(bold: true, align: PosAlign.right));

    //----
    if (sizePrinter == '58mm') {
      bytes += generator.text('--------------------------------',
          styles: const PosStyles(bold: false, align: PosAlign.center));
    } else {
      bytes += generator.text(
          '------------------------------------------------',
          styles: const PosStyles(bold: false, align: PosAlign.center));
    }

    for (final product in products) {
      bytes += generator.text('${product.quantity} x  ${product.product.name}',
          styles: const PosStyles(
            align: PosAlign.left,
            bold: false,
            height: PosTextSize.size2,
            width: PosTextSize.size1,
          ));
    }

    bytes += generator.feed(1);
    if (sizePrinter == '58mm') {
      bytes += generator.text('--------------------------------',
          styles: const PosStyles(bold: false, align: PosAlign.center));
    } else {
      bytes += generator.text(
          '------------------------------------------------',
          styles: const PosStyles(bold: false, align: PosAlign.center));
    }
    // bytes += generator.text('-----ORDER CHECKER-----',
    //     styles: const PosStyles(bold: false, align: PosAlign.center));
    bytes += generator.feed(3);
    if (sizePrinter == '80mm') {
      //cut
      bytes += generator.cut();
    }

    return bytes;
  }

  Future<List<int>> printOrderV2(
    List<OrderItem> products,
    int totalQuantity,
    int totalPrice,
    String paymentMethod,
    int nominalBayar,
    String namaKasir,
    String customerName,
  ) async {
    List<int> bytes = [];
    final sizePrinter = await AuthLocalDatasource().getSizePrinter();
    final profile = await CapabilityProfile.load();
    final generator = Generator(
        sizePrinter == '58mm' ? PaperSize.mm58 : PaperSize.mm80, profile);

    final ByteData data = await rootBundle.load('assets/logo/mylogo.png');
    final Uint8List bytesData = data.buffer.asUint8List();
    final img.Image? orginalImage = img.decodeImage(bytesData);
    bytes += generator.reset();

    if (orginalImage != null) {
      final img.Image grayscalledImage = img.grayscale(orginalImage);
      final img.Image resizedImage =
          img.copyResize(grayscalledImage, width: 240);
      bytes += generator.imageRaster(resizedImage, align: PosAlign.center);
      bytes += generator.feed(3);
    }

    bytes += generator.text('Bengkel MMT Racing Cilacap',
        styles: const PosStyles(
          bold: true,
          align: PosAlign.center,
          height: PosTextSize.size1,
          width: PosTextSize.size1,
        ));

    bytes += generator.text('Widarapayung Wetan, Binangun',
        styles: const PosStyles(bold: false, align: PosAlign.center));
    bytes += generator.text('Kab. Cilacap, Jawa Tengah',
        styles: const PosStyles(bold: false, align: PosAlign.center));
    bytes += generator.text('bengkelmmtracing.com',
        styles: const PosStyles(bold: false, align: PosAlign.center));
    bytes += generator.text('085777727416',
        styles: const PosStyles(bold: false, align: PosAlign.center));

    bytes += generator.feed(1);

    if (sizePrinter == '58mm') {
      bytes += generator.text('================================',
          styles: const PosStyles(bold: false, align: PosAlign.center));
    } else {
      bytes += generator.text(
          '------------------------------------------------',
          styles: const PosStyles(bold: false, align: PosAlign.center));
    }

    bytes += generator.row([
      PosColumn(
        text: 'No Nota',
        width: 5,
        styles: const PosStyles(align: PosAlign.left),
      ),
      PosColumn(
        text: ':',
        width: 1,
        styles: const PosStyles(align: PosAlign.left),
      ),
      PosColumn(
        text: 'JF-${DateFormat('yyyyMMddhhmm').format(DateTime.now())}',
        width: 6,
        styles: const PosStyles(align: PosAlign.left),
      ),
    ]);
    bytes += generator.row([
      PosColumn(
        text: 'Waktu',
        width: 5,
        styles: const PosStyles(align: PosAlign.left),
      ),
      PosColumn(
        text: ':',
        width: 1,
        styles: const PosStyles(align: PosAlign.left),
      ),
      PosColumn(
        text: DateFormat('dd MMM yy HH:mm').format(DateTime.now()),
        width: 6,
        styles: const PosStyles(align: PosAlign.left),
      ),
    ]);
    bytes += generator.row([
      PosColumn(
        text: 'Order By',
        width: 5,
        styles: const PosStyles(align: PosAlign.left),
      ),
      PosColumn(
        text: ':',
        width: 1,
        styles: const PosStyles(align: PosAlign.left),
      ),
      PosColumn(
        text: customerName,
        width: 6,
        styles: const PosStyles(align: PosAlign.left),
      ),
    ]);
    bytes += generator.row([
      PosColumn(
        text: 'Kasir',
        width: 5,
        styles: const PosStyles(align: PosAlign.left),
      ),
      PosColumn(
        text: ':',
        width: 1,
        styles: const PosStyles(align: PosAlign.left),
      ),
      PosColumn(
        text: namaKasir,
        width: 6,
        styles: const PosStyles(align: PosAlign.left),
      ),
    ]);
    if (sizePrinter == '58mm') {
      bytes += generator.text('--------------------------------',
          styles: const PosStyles(bold: false, align: PosAlign.center));
    } else {
      bytes += generator.text(
          '------------------------------------------------',
          styles: const PosStyles(bold: false, align: PosAlign.center));
    }

    for (final product in products) {
      bytes += generator.row([
        PosColumn(
          text: '${product.quantity} ${product.product.name}',
          width: 8,
          styles: const PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          text:
              '${product.product.price * product.quantity}'.currencyFormatRpV2,
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }
    if (sizePrinter == '58mm') {
      bytes += generator.text('--------------------------------',
          styles: const PosStyles(bold: false, align: PosAlign.center));
    } else {
      bytes += generator.text(
          '------------------------------------------------',
          styles: const PosStyles(bold: false, align: PosAlign.center));
    }

    bytes += generator.row([
      PosColumn(
        text: 'Subtotal $totalQuantity Produk',
        width: 8,
        styles: const PosStyles(align: PosAlign.left),
      ),
      PosColumn(
        text: totalPrice.currencyFormatRpV2,
        width: 4,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    bytes += generator.row([
      PosColumn(
        text: 'Total Tagihan',
        width: 8,
        styles: const PosStyles(align: PosAlign.left),
      ),
      PosColumn(
        text: totalPrice.currencyFormatRpV2,
        width: 4,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    if (sizePrinter == '58mm') {
      bytes += generator.text('--------------------------------',
          styles: const PosStyles(bold: false, align: PosAlign.center));
    } else {
      bytes += generator.text(
          '------------------------------------------------',
          styles: const PosStyles(bold: false, align: PosAlign.center));
    }
    bytes += generator.row([
      PosColumn(
        text: 'Metode Pembayaran',
        width: 8,
        styles: const PosStyles(align: PosAlign.left),
      ),
      PosColumn(
        text: paymentMethod == 'QRIS' ? 'QRIS' : 'Cash',
        width: 4,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    bytes += generator.row([
      PosColumn(
        text: 'Total Bayar',
        width: 8,
        styles: const PosStyles(align: PosAlign.left),
      ),
      PosColumn(
        text: nominalBayar.currencyFormatRpV2,
        width: 4,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);
    if (sizePrinter == '58mm') {
      bytes += generator.text('--------------------------------',
          styles: const PosStyles(bold: false, align: PosAlign.center));
    } else {
      bytes += generator.text(
          '------------------------------------------------',
          styles: const PosStyles(bold: false, align: PosAlign.center));
    }
    bytes += generator.text('instagram: @bengkelmmtracing',
        styles: const PosStyles(bold: false, align: PosAlign.center));
    bytes += generator.feed(1);
    bytes += generator.text(
        'Terbayar: ${DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now())}',
        styles: const PosStyles(bold: false, align: PosAlign.center));
    bytes += generator.text('dicetak oleh: $namaKasir',
        styles: const PosStyles(bold: false, align: PosAlign.center));
    bytes += generator.feed(3);
    if (sizePrinter == '80mm') {
      //cut
      bytes += generator.cut();
    }

    return bytes;
  }

  Future<List<int>> printQRIS(
    int totalPrice,
    Uint8List imageQris,
  ) async {
    List<int> bytes = [];

    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);

    final img.Image? orginalImage = img.decodeImage(imageQris);
    bytes += generator.reset();

    bytes += generator.text('Scan QRIS Below for Payment',
        styles: const PosStyles(bold: false, align: PosAlign.center));
    bytes += generator.feed(2);
    if (orginalImage != null) {
      final img.Image grayscalledImage = img.grayscale(orginalImage);
      final img.Image resizedImage =
          img.copyResize(grayscalledImage, width: 330);
      bytes += generator.imageRaster(resizedImage, align: PosAlign.center);
      bytes += generator.feed(4);
    }
    bytes += generator.text('Price : ${totalPrice.currencyFormatRp}',
        styles: const PosStyles(bold: false, align: PosAlign.center));

    bytes += generator.feed(3);

    return bytes;
  }
}
