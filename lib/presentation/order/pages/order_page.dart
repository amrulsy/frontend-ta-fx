import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_ta/core/constants/colors.dart';
import 'package:project_ta/core/extensions/build_context_ext.dart';
import 'package:project_ta/core/extensions/string_ext.dart';
import 'package:project_ta/data/datasources/auth_local_datasource.dart';
import 'package:project_ta/presentation/home/bloc/checkout/checkout_bloc.dart';
import 'package:project_ta/presentation/home/models/order_item.dart';
import 'package:project_ta/presentation/home/pages/dashboard_page.dart';

import '../../../core/assets/assets.gen.dart';
import '../../../core/components/buttons.dart';
import '../../../core/components/menu_button.dart';
import '../../../core/components/spaces.dart';
import '../../../data/dataoutputs/cwb_print.dart';
import '../bloc/order/order_bloc.dart';
import '../widgets/order_card.dart';
import '../widgets/payment_cash_dialog.dart';
import '../widgets/process_button.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final indexValue = ValueNotifier(0);
  final TextEditingController orderNameController = TextEditingController();
  final TextEditingController tableNumberController = TextEditingController();

  List<OrderItem> orders = [];

  int totalPrice = 0;
  int calculateTotalPrice(List<OrderItem> orders) {
    return orders.fold(
        0,
        (previousValue, element) =>
            previousValue + element.product.price * element.quantity);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    const paddingHorizontal = EdgeInsets.symmetric(horizontal: 16.0);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            context.push(const DashboardPage());
          },
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
          ),
        ),
        title: const Text(
          'Order Detail',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              //show dialog save order
              showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Open Bill'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          //nomor meja
                          TextFormField(
                            decoration: const InputDecoration(
                              hintText: 'Table Number',
                            ),
                            //number
                            keyboardType: TextInputType.number,
                            controller: tableNumberController,
                          ),
                          TextFormField(
                            decoration: const InputDecoration(
                              hintText: 'Order Name',
                            ),
                            controller: orderNameController,
                            textCapitalization: TextCapitalization.words,
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Cancel'),
                        ),
                        BlocBuilder<CheckoutBloc, CheckoutState>(
                          builder: (context, state) {
                            return state.maybeWhen(
                              orElse: () {
                                return const SizedBox.shrink();
                              },
                              success: (data, qty, total, draftName) {
                                return Button.outlined(
                                  onPressed: () async {
                                    final authData = await AuthLocalDatasource()
                                        .getAuthData();
                                    context.read<CheckoutBloc>().add(
                                          CheckoutEvent.saveDraftOrder(
                                              tableNumberController
                                                  .text.toIntegerFromText,
                                              orderNameController.text),
                                        );

                                    final printInt =
                                        await CwbPrint.instance.printChecker(
                                      data,
                                      tableNumberController.text.toInt,
                                      orderNameController.text,
                                      authData.user.name,
                                    );

                                    //print for customer
                                    CwbPrint.instance.printReceipt(printInt);
                                    // //print for kitchen
                                    // CwbPrint.instance.printReceipt(printInt);
                                    //clear checkout
                                    context.read<CheckoutBloc>().add(
                                          const CheckoutEvent.started(),
                                        );
                                    //open bill success snack bar
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Save Draft Order Success'),
                                        backgroundColor: AppColors.primary,
                                      ),
                                    );

                                    context
                                        .pushReplacement(const DashboardPage());
                                  },
                                  label: 'Save & Print',
                                  fontSize: 14,
                                  height: 40,
                                  width: 140,
                                );
                              },
                            );
                          },
                        ),
                      ],
                    );
                  });
            },
            icon: const Icon(
              Icons.save_as_outlined,
              color: Colors.white,
            ),
          ),
          const SpaceWidth(8),
        ],
      ),
      body: BlocBuilder<CheckoutBloc, CheckoutState>(
        builder: (context, state) {
          return state.maybeWhen(orElse: () {
            return const Center(
              child: Text('No Data'),
            );
          }, success: (data, qty, total, draftName) {
            if (data.isEmpty) {
              return const Center(
                child: Text('No Data'),
              );
            }

            totalPrice = total;
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              itemCount: data.length,
              separatorBuilder: (context, index) => const SpaceHeight(20.0),
              itemBuilder: (context, index) => OrderCard(
                padding: paddingHorizontal,
                data: data[index],
                onDeleteTap: () {
                  context.read<CheckoutBloc>().add(
                        CheckoutEvent.removeProduct(data[index].product),
                      );
                },
              ),
            );
          });
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BlocBuilder<CheckoutBloc, CheckoutState>(
              builder: (context, state) {
                return state.maybeWhen(
                  orElse: () {
                    return const SizedBox.shrink();
                  },
                  success: (data, qty, total, draftName) {
                    return ValueListenableBuilder(
                      valueListenable: indexValue,
                      builder: (context, value, _) => Row(
                        children: [
                          Flexible(
                            child: MenuButton(
                              iconPath: Assets.icons.cash.path,
                              label: 'CASH',
                              isActive: value == 1,
                              onPressed: () {
                                indexValue.value = 1;
                                context.read<OrderBloc>().add(
                                    OrderEvent.addPaymentMethod(
                                        'Tunai', data, draftName));
                              },
                            ),
                          ),
                          const SpaceWidth(16.0),
                          Flexible(
                            child: MenuButton(
                              iconPath: Assets.icons.debit.path,
                              label: 'TRANSFER',
                              isActive: value == 3,
                              onPressed: () {
                                indexValue.value = 3;
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            const SpaceHeight(20.0),
            ProcessButton(
              price: 0,
              onPressed: () async {
                if (indexValue.value == 0) {
                } else if (indexValue.value == 1) {
                  showDialog(
                    context: context,
                    builder: (context) => PaymentCashDialog(
                      price: totalPrice,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
