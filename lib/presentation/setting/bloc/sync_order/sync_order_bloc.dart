import 'package:bloc/bloc.dart';
import 'package:project_ta/data/datasources/product_local_datasource.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:project_ta/data/datasources/order_remote_datasource.dart';
import 'package:project_ta/data/models/request/order_request_model.dart';

part 'sync_order_bloc.freezed.dart';
part 'sync_order_event.dart';
part 'sync_order_state.dart';

class SyncOrderBloc extends Bloc<SyncOrderEvent, SyncOrderState> {
  final OrderRemoteDatasource orderRemoteDatasource;
  SyncOrderBloc(this.orderRemoteDatasource) : super(const _Initial()) {
    on<_SendOrder>((event, emit) async {
      emit(const SyncOrderState.loading());

      // STEP 1: Upload local orders to API
      print('=== STEP 1: UPLOADING LOCAL ORDERS TO API ===');
      final ordersIsSyncZero = await ProductLocalDatasource.instance
          .getOrderByIsSync();

      print('Total orders to sync: ${ordersIsSyncZero.length}');

      if (ordersIsSyncZero.isEmpty) {
        print('⚠️ No local orders to upload');
      }

      int uploadSuccessCount = 0;
      int uploadFailedCount = 0;

      for (final order in ordersIsSyncZero) {
        print('\n--- Uploading order ID: ${order.id} ---');

        final orderItems = await ProductLocalDatasource.instance
            .getOrderItemByOrderIdLocal(order.id!);

        print('Order items count: ${orderItems.length}');

        final orderRequest = OrderRequestModel(
          transactionTime: order.transactionTime,
          totalItem: order.totalQuantity,
          totalPrice: order.totalPrice,
          kasirId: order.idKasir,
          paymentMethod: order.paymentMethod,
          orderItems: orderItems,
        );

        final response = await orderRemoteDatasource.sendOrder(orderRequest);

        if (response) {
          await ProductLocalDatasource.instance.updateIsSyncOrderById(
            order.id!,
          );
          uploadSuccessCount++;
          print('✅ Order ${order.id} uploaded successfully');
        } else {
          uploadFailedCount++;
          print('❌ Order ${order.id} failed to upload');
        }
      }

      print('\n=== UPLOAD SUMMARY ===');
      print('Success: $uploadSuccessCount');
      print('Failed: $uploadFailedCount');

      // STEP 2: Download orders from API to local
      print('\n=== STEP 2: DOWNLOADING ORDERS FROM API ===');
      final apiOrders = await orderRemoteDatasource.getOrders();

      int downloadSuccessCount = 0;
      for (final apiOrder in apiOrders) {
        try {
          await ProductLocalDatasource.instance.saveOrderFromApi(
            kasirId: apiOrder.kasirId,
            kasirName: apiOrder.kasirName,
            transactionTime: apiOrder.transactionTime,
            totalPrice: apiOrder.totalPrice,
            totalItem: apiOrder.totalItem,
            paymentMethod: apiOrder.paymentMethod,
            orderItems: apiOrder.orderItems
                .map(
                  (item) => {
                    'product_id': item.productId,
                    'quantity': item.quantity,
                    'price': item.price,
                  },
                )
                .toList(),
          );
          downloadSuccessCount++;
        } catch (e) {
          print('❌ Failed to save order from API: $e');
        }
      }

      print('\n=== DOWNLOAD SUMMARY ===');
      print('Total from API: ${apiOrders.length}');
      print('Saved to local: $downloadSuccessCount');

      print('\n=== OVERALL SYNC SUMMARY ===');
      print('Uploaded: $uploadSuccessCount');
      print('Upload Failed: $uploadFailedCount');
      print('Downloaded: $downloadSuccessCount');

      if (uploadSuccessCount > 0 || downloadSuccessCount > 0) {
        emit(const SyncOrderState.success());
      } else if (ordersIsSyncZero.isEmpty && apiOrders.isEmpty) {
        emit(const SyncOrderState.error('Tidak ada order untuk disinkronkan'));
      } else {
        emit(
          const SyncOrderState.error(
            'Gagal sinkronisasi. Periksa koneksi dan log.',
          ),
        );
      }
    });
  }
}
