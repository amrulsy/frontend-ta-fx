import 'package:dartz/dartz.dart';
import 'package:project_ta/data/datasources/order_remote_datasource.dart';
import 'package:project_ta/data/datasources/product_local_datasource.dart';
import 'package:project_ta/data/datasources/product_remote_datasource.dart';
import 'package:project_ta/data/models/request/order_request_model.dart';
import 'package:project_ta/data/models/response/order_response_model.dart';

class OrderRepository {
  final OrderRemoteDatasource _orderRemoteDatasource;
  final ProductRemoteDatasource _productRemoteDatasource;
  final ProductLocalDatasource _productLocalDatasource;

  OrderRepository({
    OrderRemoteDatasource? orderRemoteDatasource,
    ProductRemoteDatasource? productRemoteDatasource,
    ProductLocalDatasource? productLocalDatasource,
  }) : _orderRemoteDatasource =
           orderRemoteDatasource ?? OrderRemoteDatasource(),
       _productRemoteDatasource =
           productRemoteDatasource ?? ProductRemoteDatasource(),
       _productLocalDatasource =
           productLocalDatasource ?? ProductLocalDatasource.instance;

  // Sync Process: Upload Local -> Sync Stocks -> Download Remote -> Cleanup
  Future<Either<String, String>> syncOrders() async {
    try {
      int uploadSuccessCount = 0;
      // ignore: unused_local_variable
      int uploadFailedCount = 0;
      int downloadSuccessCount = 0;

      // 1. Upload Local Orders
      final ordersToSync = await _productLocalDatasource.getOrderByIsSync();
      Set<String> uploadedTransactionTimes = {};

      for (final order in ordersToSync) {
        final orderItems = await _productLocalDatasource
            .getOrderItemByOrderIdLocal(order.id!);

        final orderRequest = OrderRequestModel(
          transactionTime: order.transactionTime,
          totalItem: order.totalQuantity,
          totalPrice: order.totalPrice,
          kasirId: order.idKasir,
          paymentMethod: order.paymentMethod,
          orderItems: orderItems,
        );

        final success = await _orderRemoteDatasource.sendOrder(orderRequest);

        if (success) {
          await _productLocalDatasource.updateIsSyncOrderById(order.id!);
          uploadSuccessCount++;
          uploadedTransactionTimes.add(order.transactionTime);

          // Update Server Stock (Logic Refactored)
          await _syncStockForOrder(orderItems);
        } else {
          uploadFailedCount++;
        }
      }

      // 1.5 Force Sync All Stocks (Batched)
      await _forceSyncAllStocks();

      // 2. Download Orders
      final apiOrders = await _orderRemoteDatasource.getOrders();
      for (final apiOrder in apiOrders) {
        final normalizedApiTime = apiOrder.transactionTime.replaceAll(' ', 'T');
        if (uploadedTransactionTimes.contains(normalizedApiTime)) continue;

        await _productLocalDatasource.saveOrderFromApi(
          kasirId: apiOrder.kasirId,
          kasirName: apiOrder.kasirName,
          transactionTime: apiOrder.transactionTime,
          totalPrice: apiOrder.totalPrice,
          totalItem: apiOrder.totalItem,
          paymentMethod: apiOrder.paymentMethod,
          orderItems: apiOrder.orderItems
              .map(
                (e) => {
                  'product_id': e.productId,
                  'quantity': e.quantity,
                  'price': e.price,
                },
              )
              .toList(),
        );
        downloadSuccessCount++;
      }

      // 3. Cleanup Orphaned Orders
      await _cleanupOrphanedOrders(apiOrders);

      return Right(
        'Sync Completed. Upload: $uploadSuccessCount, Download: $downloadSuccessCount',
      );
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<void> _syncStockForOrder(List<dynamic> orderItems) async {
    for (final item in orderItems) {
      try {
        final product = await _productLocalDatasource.getProductById(
          item.productId,
        );
        if (product != null) {
          // Sync server stock with local source of truth
          await _productRemoteDatasource.updateProductStock(
            product,
            product.stock,
          );
        }
      } catch (e) {
        print('Error syncing stock for item ${item.productId}: $e');
      }
    }
  }

  Future<void> _forceSyncAllStocks() async {
    try {
      final allLocalProducts = await _productLocalDatasource.getAllProduct();
      final serverProductsResult = await _productRemoteDatasource.getProducts();

      // If we can't fetch server products, we can't compare, so skip optimization
      Map<int, int> serverStockMap = {};
      serverProductsResult.fold((l) => print('Skipping Optimization: $l'), (r) {
        for (var p in r.data) {
          if (p.id != null) serverStockMap[p.id!] = p.stock;
        }
      });

      List<dynamic> productsToUpdate = [];
      for (final product in allLocalProducts) {
        final serverId = product.productId ?? product.id;
        if (serverId != null) {
          // Update if server map is empty (fetch failed) or mismatch
          if (serverStockMap.isEmpty ||
              !serverStockMap.containsKey(serverId) ||
              serverStockMap[serverId] != product.stock) {
            productsToUpdate.add(product);
          }
        }
      }

      // Batch Process
      int batchSize = 5;
      for (var i = 0; i < productsToUpdate.length; i += batchSize) {
        var end = (i + batchSize < productsToUpdate.length)
            ? i + batchSize
            : productsToUpdate.length;
        var batch = productsToUpdate.sublist(i, end);
        await Future.wait(
          batch.map((product) async {
            await _productRemoteDatasource.updateProductStock(
              product,
              product.stock,
            );
          }),
        );
      }
    } catch (e) {
      print('Force Sync Exception: $e');
    }
  }

  Future<void> _cleanupOrphanedOrders(
    List<OrderResponseModel> apiOrders,
  ) async {
    final apiTransactionTimes = apiOrders
        .map((order) => order.transactionTime.replaceAll(' ', 'T'))
        .toSet();

    final allLocalOrders = await _productLocalDatasource.getAllOrder();

    for (final localOrder in allLocalOrders) {
      if (localOrder.isSync) {
        if (!apiTransactionTimes.contains(localOrder.transactionTime)) {
          await _productLocalDatasource.deleteOrderByTransactionTime(
            localOrder.transactionTime,
          );
        }
      }
    }
  }
}
