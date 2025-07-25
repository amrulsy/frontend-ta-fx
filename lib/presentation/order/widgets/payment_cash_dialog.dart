import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_ta/core/extensions/build_context_ext.dart';
import 'package:project_ta/core/extensions/int_ext.dart';
import 'package:project_ta/core/extensions/string_ext.dart';
import 'package:project_ta/data/datasources/order_remote_datasource.dart';
import 'package:project_ta/data/datasources/product_local_datasource.dart';
import 'package:project_ta/data/models/request/order_request_model.dart';
import 'package:project_ta/presentation/order/bloc/order/order_bloc.dart';
import 'package:project_ta/presentation/order/models/order_model.dart';
import 'package:project_ta/presentation/order/widgets/payment_success_dialog.dart';
import 'package:intl/intl.dart';

import '../../../core/components/buttons.dart';
import '../../../core/components/custom_text_field.dart';
import '../../../core/components/spaces.dart';
import '../../../core/constants/colors.dart';

class PaymentCashDialog extends StatefulWidget {
  final int price;
  const PaymentCashDialog({super.key, required this.price});

  @override
  State<PaymentCashDialog> createState() => _PaymentCashDialogState();
}

class _PaymentCashDialogState extends State<PaymentCashDialog> {
  TextEditingController?
      priceController; // = TextEditingController(text: widget.price.currencyFormatRp);

  @override
  void initState() {
    priceController =
        TextEditingController(text: widget.price.currencyFormatRp);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Stack(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.highlight_off),
            color: AppColors.primary,
          ),
          const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 12.0),
              child: Text(
                'Payment - Cash',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SpaceHeight(16.0),
          CustomTextField(
            controller: priceController!,
            label: '',
            showLabel: false,
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final int priceValue = value.toIntegerFromText;
              priceController!.text = priceValue.currencyFormatRp;
              priceController!.selection = TextSelection.fromPosition(
                  TextPosition(offset: priceController!.text.length));
            },
          ),
          const SpaceHeight(16.0),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //   children: [
          //     Button.filled(
          //       onPressed: () {},
          //       label: 'Uang Pas',
          //       disabled: true,
          //       textColor: AppColors.primary,
          //       fontSize: 13.0,
          //       width: 112.0,
          //       height: 50.0,
          //     ),
          //     const SpaceWidth(4.0),
          //     Flexible(
          //       child: Button.filled(
          //         onPressed: () {},
          //         label: widget.price.currencyFormatRp,
          //         disabled: true,
          //         textColor: AppColors.primary,
          //         fontSize: 13.0,
          //         height: 50.0,
          //       ),
          //     ),
          //   ],
          // ),
          const SpaceHeight(30.0),
          BlocConsumer<OrderBloc, OrderState>(
            listener: (context, state) {
              state.maybeWhen(
                orElse: () {},
                success: (data, qty, total, payment, nominal, idKasir,
                    namaKasir, _) {
                  final orderModel = OrderModel(
                      paymentMethod: payment,
                      nominalBayar: nominal,
                      orders: data,
                      totalQuantity: qty,
                      totalPrice: total,
                      idKasir: idKasir,
                      namaKasir: namaKasir,
                      //tranction time format 2024-01-03T22:12:22
                      transactionTime: DateFormat('yyyy-MM-ddTHH:mm:ss')
                          .format(DateTime.now()),
                      isSync: true);
                  ProductLocalDatasource.instance.saveOrder(orderModel);
                  final OrderRequestModel orderRequestModel = OrderRequestModel(
                    transactionTime: DateFormat('yyyy-MM-ddTHH:mm:ss')
                        .format(DateTime.now()),
                    kasirId: idKasir,
                    totalPrice: total,
                    totalItem: qty,
                    paymentMethod: payment,
                    orderItems: data
                        .map((e) => OrderItemModel(
                            productId: e.product.productId!,
                            quantity: e.quantity,
                            totalPrice: e.product.price * e.quantity))
                        .toList(),
                  );
                  OrderRemoteDatasource().sendOrder(orderRequestModel);
                  context.pop();
                  showDialog(
                    context: context,
                    builder: (context) => const PaymentSuccessDialog(),
                  );
                },
              );
            },
            builder: (context, state) {
              return state.maybeWhen(orElse: () {
                return const SizedBox();
              }, success:
                  (data, qty, total, payment, _, idKasir, mameKasir, __) {
                return Button.filled(
                  onPressed: () {
                    //check if price is empty
                    if (priceController!.text.isEmpty) {
                      //show dialog error
                      showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Error'),
                              content: const Text('Please input the price'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text('OK'),
                                ),
                              ],
                            );
                          });
                      return;
                    }

                    //if price less than total price
                    if (priceController!.text.toIntegerFromText < total) {
                      //show dialog error
                      showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Error'),
                              content: const Text(
                                  'The nominal is less than the total price'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text('OK'),
                                ),
                              ],
                            );
                          });
                      return;
                    }
                    context.read<OrderBloc>().add(OrderEvent.addNominalBayar(
                          priceController!.text.toIntegerFromText,
                        ));
                  },
                  label: 'Pay',
                );
              }, error: (message) {
                return const SizedBox();
              });
            },
          ),
        ],
      ),
    );
  }
}
