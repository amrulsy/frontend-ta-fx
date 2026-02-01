import 'package:bloc/bloc.dart';
import 'package:project_ta/data/datasources/product_local_datasource.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:project_ta/data/datasources/order_remote_datasource.dart';
import 'package:project_ta/data/datasources/product_remote_datasource.dart';
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

          // Sync Server Stock Reduction (Offline Handling)
          print('🔄 Syncing stock reduction for Order ${order.id}...');
          for (final item in orderItems) {
            try {
              // item is OrderItemModel (productId, quantity, etc)
              // Get full product details from local DB to perform update
              final product = await ProductLocalDatasource.instance
                  .getProductById(item.productId);

              if (product != null) {
                // Use current LOCAL stock as the source of truth for server
                // Because local stock was already reduced when order was created
                final currentLocalStock = product.stock;

                print(
                  '   Syncing stock for ${product.name} (ID: ${product.productId}) -> Server becomes: $currentLocalStock',
                );

                final result = await ProductRemoteDatasource()
                    .updateProductStock(product, currentLocalStock);

                result.fold(
                  (l) =>
                      print('❌ Failed to update stock for ${product.name}: $l'),
                  (r) => print('✅ Updated stock for ${product.name} on server'),
                );
              } else {
                print(
                  '⚠️ Product ID ${item.productId} not found locally, skipping stock sync',
                );
              }
            } catch (e) {
              print(
                '❌ Exception updating stock sync for Item ${item.productId}: $e',
              );
            }
          }
        } else {
          uploadFailedCount++;
          print('❌ Order ${order.id} failed to upload');
        }
      }

      print('\n=== UPLOAD SUMMARY ===');
      print('Success: $uploadSuccessCount');
      print('Failed: $uploadFailedCount');

      // STEP 1.5: OPTIMIZED FORCE SYNC ALL STOCKS
      // Strategy: Compare first, then update only differences in parallel batches.
      print('\n=== STEP 1.5: OPTIMIZED FORCE SYNC ALL STOCKS ===');
      try {
        final allLocalProducts = await ProductLocalDatasource.instance
            .getAllProduct();

        // 1. Fetch Server Products to compare (Save time by only updating dirty items)
        final serverProductsResult = await ProductRemoteDatasource()
            .getProducts();
        Map<int, int> serverStockMap = {};

        serverProductsResult.fold(
          (l) => print('⚠️ Could not fetch server products for comparison: $l'),
          (r) {
            for (var p in r.data) {
              // Assuming 'id' in remove response is the Server ID
              if (p.id != null) serverStockMap[p.id!] = p.stock;
            }
          },
        );

        // 2. Identify mismatching products
        List<dynamic> productsToUpdate = []; // Dynamic to allow Product type
        for (final product in allLocalProducts) {
          final serverId = product.productId ?? product.id;
          if (serverId != null) {
            // Update IF server stock is unknown (newly synced?) OR different
            if (!serverStockMap.containsKey(serverId) ||
                serverStockMap[serverId] != product.stock) {
              productsToUpdate.add(product);
            }
          }
        }

        print(
          'Total products to update: ${productsToUpdate.length} out of ${allLocalProducts.length} local items',
        );

        // 3. Parallel Processing with Batches (Avoid server overload)
        int batchSize = 5;
        int successCount = 0;

        for (var i = 0; i < productsToUpdate.length; i += batchSize) {
          var end = (i + batchSize < productsToUpdate.length)
              ? i + batchSize
              : productsToUpdate.length;
          var batch = productsToUpdate.sublist(i, end);

          await Future.wait(
            batch.map((product) async {
              final result = await ProductRemoteDatasource().updateProductStock(
                product,
                product.stock,
              );
              result.fold(
                (l) => print('   ❌ Failed sync stock for ${product.name}: $l'),
                (r) => successCount++,
              );
            }),
          );
          // print('   Batch $i-$end processed');
        }
        print('✅ Batch Stock Sync Completed. Updated: $successCount');
      } catch (e) {
        print('❌ Exception during Force Stock Sync: $e');
      }

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
