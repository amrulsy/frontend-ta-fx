import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_ta/core/extensions/build_context_ext.dart';
import 'package:intl/intl.dart';

import '../../../core/components/spaces.dart';
import '../../../core/constants/colors.dart';

import '../../home/pages/dashboard_page.dart';
import '../bloc/history/history_bloc.dart';

import '../widgets/history_transaction_card.dart';
import '../../order/models/order_model.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  void initState() {
    super.initState();
    context.read<HistoryBloc>().add(const HistoryEvent.fetch());
  }

  // Group orders by date
  Map<String, List<OrderModel>> _groupOrdersByDate(List<OrderModel> orders) {
    Map<String, List<OrderModel>> grouped = {};

    for (var order in orders) {
      // Parse transaction_time
      DateTime dateTime = DateTime.parse(order.transactionTime);
      // Format as date only (yyyy-MM-dd)
      String dateKey = DateFormat('yyyy-MM-dd').format(dateTime);

      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(order);
    }

    return grouped;
  }

  // Format date for display (e.g., "Hari Ini", "Senin, 1 Januari 2024")
  String _formatDateHeader(String dateKey) {
    DateTime date = DateTime.parse(dateKey);
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime yesterday = today.subtract(const Duration(days: 1));
    DateTime dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Hari Ini';
    } else if (dateOnly == yesterday) {
      return 'Kemarin';
    } else {
      // Format: "1 Januari 2024" (without day name to avoid locale issues)
      return DateFormat('d MMMM yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    const paddingHorizontal = EdgeInsets.symmetric(horizontal: 16.0);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            context.push(const DashboardPage());
          },
        ),
        title: const Text(
          'History',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: BlocBuilder<HistoryBloc, HistoryState>(
        builder: (context, state) {
          return state.maybeWhen(
            orElse: () {
              return const Center(child: Text('No data'));
            },
            loading: () {
              return const Center(child: CircularProgressIndicator());
            },
            success: (data) {
              if (data.isEmpty) {
                return const Center(child: Text('No data'));
              }

              // Group orders by date
              Map<String, List<OrderModel>> groupedOrders = _groupOrdersByDate(
                data,
              );
              List<String> dateKeys = groupedOrders.keys.toList();

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                itemCount: dateKeys.length,
                itemBuilder: (context, dateIndex) {
                  String dateKey = dateKeys[dateIndex];
                  List<OrderModel> ordersForDate = groupedOrders[dateKey]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          16.0,
                          16.0,
                          16.0,
                          12.0,
                        ),
                        child: Text(
                          _formatDateHeader(dateKey),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      // Orders for this date
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: ordersForDate.length,
                        separatorBuilder: (context, index) =>
                            const SpaceHeight(8.0),
                        itemBuilder: (context, index) => HistoryTransactionCard(
                          padding: paddingHorizontal,
                          data: ordersForDate[index],
                        ),
                      ),
                      const SpaceHeight(8.0),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
