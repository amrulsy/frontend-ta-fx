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

      // Track transaction times of uploaded orders to avoid re-downloading them
      Set<String> uploadedTransactionTimes = {};

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
          uploadedTransactionTimes.add(order.transactionTime);
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
      int skippedCount = 0;

      for (final apiOrder in apiOrders) {
        // Normalize transaction_time format for comparison
        // Frontend saves: "2026-02-01T14:38:35" (ISO format with T)
        // Backend returns: "2026-02-01 14:38:35" (format with space)
        // Convert backend format to frontend format for comparison
        final normalizedApiTime = apiOrder.transactionTime.replaceAll(' ', 'T');

        // Skip orders that were just uploaded in this sync session
        if (uploadedTransactionTimes.contains(normalizedApiTime)) {
          skippedCount++;
          print(
            '⏭️ Skipping order (just uploaded): ${apiOrder.transactionTime}',
          );
          continue;
        }

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
      print('Skipped (just uploaded): $skippedCount');
      print('Saved to local: $downloadSuccessCount');

      // STEP 3: Cleanup - Delete local orders that don't exist in API anymore
      print('\n=== STEP 3: CLEANUP ORPHANED ORDERS ===');

      // Get all API transaction times (normalized)
      final apiTransactionTimes = apiOrders
          .map((order) => order.transactionTime.replaceAll(' ', 'T'))
          .toSet();

      // Get all synced local orders
      final allLocalOrders = await ProductLocalDatasource.instance
          .getAllOrder();

      int deletedCount = 0;
      for (final localOrder in allLocalOrders) {
        // Only check synced orders (is_sync = 1)
        // Unsynced orders (is_sync = 0) are pending upload, don't delete
        if (localOrder.isSync) {
          if (!apiTransactionTimes.contains(localOrder.transactionTime)) {
            // Order exists locally but not in API - delete it
            await ProductLocalDatasource.instance.deleteOrderByTransactionTime(
              localOrder.transactionTime,
            );
            deletedCount++;
            print('🗑️ Deleted orphaned order: ${localOrder.transactionTime}');
          }
        }
      }

      print('Orphaned orders deleted: $deletedCount');

      print('\n=== OVERALL SYNC SUMMARY ===');
      print('Uploaded: $uploadSuccessCount');
      print('Upload Failed: $uploadFailedCount');
      print('Downloaded: $downloadSuccessCount');
      print('Deleted orphaned: $deletedCount');

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
