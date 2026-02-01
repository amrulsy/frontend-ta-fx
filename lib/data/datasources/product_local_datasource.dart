import 'package:project_ta/data/models/response/product_response_model.dart';
import 'package:project_ta/presentation/order/models/order_model.dart';
import 'package:sqflite/sqflite.dart';

import '../../presentation/home/models/draft_order_item.dart';
import '../../presentation/home/models/order_item.dart';
import '../../presentation/order/models/draft_order_model.dart';
import '../models/request/order_request_model.dart';
import '../models/response/category_response_model.dart';

class ProductLocalDatasource {
  ProductLocalDatasource._init();

  static final ProductLocalDatasource instance = ProductLocalDatasource._init();

  final String tableProducts = 'products';

  static Database? _database;

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = dbPath + filePath;

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableProducts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER,
        name TEXT,
        price INTEGER,
        stock INTEGER,
        image TEXT,
        category TEXT,
        category_id INTEGER,
        is_best_seller INTEGER,
        is_sync INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nominal INTEGER,
        payment_method TEXT,
        total_item INTEGER,
        id_kasir INTEGER,
        nama_kasir TEXT,
        transaction_time TEXT,
        is_sync INTEGER DEFAULT 0
      )
    ''');

    //categories
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER,
        name TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_order INTEGER,
        id_product INTEGER,
        quantity INTEGER,
        price INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE draft_orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        total_item INTEGER,
        nominal INTEGER,
        transaction_time TEXT,
        table_number INTEGER,
        draft_name TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE draft_order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_draft_order INTEGER,
        id_product INTEGER,
        quantity INTEGER,
        price INTEGER
      )
    ''');
  }

  //insert all categories
  Future<void> insertAllCategories(List<Category> categories) async {
    final db = await instance.database;
    for (var category in categories) {
      await db.insert('categories', category.toMap());
    }
  }

  //delete all categories
  Future<void> removeAllCategories() async {
    final db = await instance.database;
    await db.delete('categories');
  }

  //get all categories
  Future<List<Category>> getAllCategories() async {
    final db = await instance.database;
    final result = await db.query('categories');

    return result.map((e) => Category.fromLocal(e)).toList();
  }

  //save order
  Future<int> saveOrder(OrderModel order) async {
    final db = await instance.database;

    return await db.transaction((txn) async {
      int id = await txn.insert('orders', order.toMapForLocal());

      for (var orderItem in order.orders) {
        await txn.insert('order_items', orderItem.toMapForLocal(id));

        // Reduce stock atomically inside the transaction
        final productId = orderItem.product.productId;
        if (productId != null) {
          final List<Map<String, dynamic>> result = await txn.query(
            tableProducts,
            where: 'product_id = ?',
            whereArgs: [productId],
          );

          if (result.isNotEmpty) {
            final currentStock = result.first['stock'] as int;
            final newStock = (currentStock - orderItem.quantity).clamp(
              0,
              currentStock,
            );
            await txn.update(
              tableProducts,
              {'stock': newStock},
              where: 'product_id = ?',
              whereArgs: [productId],
            );
            print(
              '📦 Atomic stock reduction for product $productId: $currentStock -> $newStock',
            );
          }
        }
      }
      return id;
    });
  }

  //save draft order
  Future<int> saveDraftOrder(DraftOrderModel order) async {
    final db = await instance.database;
    int id = await db.insert('draft_orders', order.toMapForLocal());
    for (var orderItem in order.orders) {
      await db.insert('draft_order_items', orderItem.toMapForLocal(id));
    }
    return id;
  }

  //get all draft order
  Future<List<DraftOrderModel>> getAllDraftOrder() async {
    final db = await instance.database;
    final result = await db.query('draft_orders', orderBy: 'id ASC');

    List<DraftOrderModel> results = await Future.wait(
      result.map((item) async {
        // Your asynchronous operation here
        final draftOrderItem = await getDraftOrderItemByOrderId(
          item['id'] as int,
        );
        return DraftOrderModel.newFromLocalMap(item, draftOrderItem);
      }),
    );
    return results;
  }

  //get draft order item by id order
  Future<List<DraftOrderItem>> getDraftOrderItemByOrderId(int idOrder) async {
    final db = await instance.database;
    final result = await db.query(
      'draft_order_items',
      where: 'id_draft_order = $idOrder',
    );

    List<DraftOrderItem> results = await Future.wait(
      result.map((item) async {
        // Your asynchronous operation here
        final product = await getProductById(item['id_product'] as int);
        return DraftOrderItem(
          product: product!,
          quantity: item['quantity'] as int,
        );
      }),
    );
    return results;
  }

  //remove draft order by id
  Future<void> removeDraftOrderById(int id) async {
    final db = await instance.database;
    await db.delete('draft_orders', where: 'id = ?', whereArgs: [id]);
    await db.delete(
      'draft_order_items',
      where: 'id_draft_order = ?',
      whereArgs: [id],
    );
  }

  //get order by isSync = 0
  Future<List<OrderModel>> getOrderByIsSync() async {
    final db = await instance.database;
    final result = await db.query('orders', where: 'is_sync = 0');

    return result.map((e) => OrderModel.fromLocalMap(e)).toList();
  }

  //get order item by id order
  Future<List<OrderItemModel>> getOrderItemByOrderIdLocal(int idOrder) async {
    final db = await instance.database;
    final result = await db.query('order_items', where: 'id_order = $idOrder');

    return result.map((e) => OrderItem.fromMapLocal(e)).toList();
  }

  //update isSync order by id
  Future<int> updateIsSyncOrderById(int id) async {
    final db = await instance.database;
    return await db.update(
      'orders',
      {'is_sync': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete order by transaction_time (checks for normalized format)
  Future<void> deleteOrderByTransactionTime(String transactionTime) async {
    final db = await instance.database;
    final normalizedTime = transactionTime.replaceAll(' ', 'T');

    // Get order ID first to delete items
    final orders = await db.query(
      'orders',
      columns: ['id'],
      where: 'transaction_time = ?',
      whereArgs: [normalizedTime],
    );

    if (orders.isNotEmpty) {
      final id = orders.first['id'] as int;
      await db.delete('order_items', where: 'id_order = ?', whereArgs: [id]);
      await db.delete('orders', where: 'id = ?', whereArgs: [id]);
    }
  }

  //get all orders
  Future<List<OrderModel>> getAllOrder() async {
    final db = await instance.database;
    final result = await db.query('orders', orderBy: 'transaction_time DESC');

    List<OrderModel> results = await Future.wait(
      result.map((item) async {
        // Your asynchronous operation here
        final orderItem = await getOrderItemByOrderId(item['id'] as int);
        return OrderModel.newFromLocalMap(item, orderItem);
      }),
    );
    return results;
    // return result.map((e) {
    //   return OrderModel.fromLocalMap(e);
    // }).toList();
  }

  //get order item by id order
  Future<List<OrderItem>> getOrderItemByOrderId(int idOrder) async {
    final db = await instance.database;
    final result = await db.query('order_items', where: 'id_order = $idOrder');

    List<OrderItem> results = await Future.wait(
      result.map((item) async {
        // Your asynchronous operation here
        final product = await getProductById(item['id_product'] as int);
        return OrderItem(product: product!, quantity: item['quantity'] as int);
      }),
    );
    return results;

    // return result.map((e) => OrderItem.fromMap(e)).toList();
  }

  //save order from API to local database
  Future<void> saveOrderFromApi({
    required int kasirId,
    required String kasirName,
    required String transactionTime,
    required int totalPrice,
    required int totalItem,
    required String paymentMethod,
    required List<Map<String, dynamic>> orderItems,
  }) async {
    final db = await instance.database;

    // Normalize transaction_time format for duplicate check
    // Frontend saves: "2026-02-01T14:38:35" (ISO format with T)
    // Backend returns: "2026-02-01 14:38:35" (format with space)
    // Convert backend format to frontend format for comparison
    final normalizedTime = transactionTime.replaceAll(' ', 'T');

    // Check if order already exists by normalized transaction_time to avoid duplicates
    final existing = await db.query(
      'orders',
      where: 'transaction_time = ?',
      whereArgs: [normalizedTime],
    );

    if (existing.isNotEmpty) {
      print(
        '⚠️ Order with transaction_time $transactionTime already exists, skipping',
      );
      return;
    }

    // Insert order with normalized transaction_time
    int orderId = await db.insert('orders', {
      'nominal': totalPrice,
      'payment_method': paymentMethod,
      'total_item': totalItem,
      'id_kasir': kasirId,
      'nama_kasir': kasirName,
      'transaction_time': normalizedTime, // Save in frontend format (with T)
      'is_sync': 1, // Mark as already synced from API
    });

    print('✅ Saved order from API with local ID: $orderId');

    // Insert order items
    for (var item in orderItems) {
      await db.insert('order_items', {
        'id_order': orderId,
        'id_product': item['product_id'],
        'quantity': item['quantity'],
        'price': item['price'],
      });
    }

    print('   Saved ${orderItems.length} order items');
  }

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('pos13.db');
    return _database!;
  }

  //remove all data product
  Future<void> removeAllProduct() async {
    final db = await instance.database;
    await db.delete(tableProducts);
  }

  //insert data product from list product
  Future<void> insertAllProduct(List<Product> products) async {
    final db = await instance.database;
    for (var product in products) {
      await db.insert(tableProducts, product.toLocalMap());
    }
  }

  // Smart Sync for Products (Delta Sync Logic Client-Side)
  // Compares remote data with local data to minimize DB operations
  Future<void> syncProducts(List<Product> remoteProducts) async {
    final db = await instance.database;

    await db.transaction((txn) async {
      // 1. Get all local products mapping (ServerID -> LocalData)
      final localData = await txn.query(tableProducts);
      Map<int, Map<String, dynamic>> localMap = {};

      for (var p in localData) {
        final sId = p['product_id'];
        if (sId != null && sId is int) {
          localMap[sId] = p;
        }
      }

      int inserted = 0;
      int updated = 0;
      int deleted = 0;

      // 2. Process Remote Products
      for (var remote in remoteProducts) {
        final serverId = remote.id; // Remote Model 'id' is Server ID

        if (serverId != null) {
          if (localMap.containsKey(serverId)) {
            // Check for changes (Simple check: compare key fields)
            final local = localMap[serverId]!;
            bool isChanged = false;

            if (local['name'] != remote.name) isChanged = true;
            if (local['price'] != remote.price) isChanged = true;
            if (local['stock'] != remote.stock) isChanged = true;
            if (local['category'] != remote.category) isChanged = true;
            // Add more fields if necessary

            if (isChanged) {
              await txn.update(
                tableProducts,
                remote.toLocalMap(),
                where: 'product_id = ?',
                whereArgs: [serverId],
              );
              updated++;
            }

            // Mark as processed by removing from map
            localMap.remove(serverId);
          } else {
            // New Product
            await txn.insert(tableProducts, remote.toLocalMap());
            inserted++;
          }
        }
      }

      // 3. Delete products that are no longer on server
      // Remaining items in localMap are orphans
      for (var sId in localMap.keys) {
        await txn.delete(
          tableProducts,
          where: 'product_id = ?',
          whereArgs: [sId],
        );
        deleted++;
      }

      print('🔄 Smart Product Sync: +$inserted, ~$updated, -$deleted');
    });
  }

  //isert data product
  Future<Product> insertProduct(Product product) async {
    final db = await instance.database;
    int id = await db.insert(tableProducts, product.toMap());
    return product.copyWith(id: id);
  }

  //get all data product
  Future<List<Product>> getAllProduct() async {
    final db = await instance.database;
    final result = await db.query(tableProducts);

    return result.map((e) => Product.fromMap(e)).toList();
  }

  //get product by id
  Future<Product?> getProductById(int id) async {
    final db = await instance.database;
    final result = await db.query(
      tableProducts,
      where: 'product_id = ?',
      whereArgs: [id],
    );

    if (result.isEmpty) {
      return null;
    }

    return Product.fromMap(result.first);
  }

  // Reduce stock for a product after checkout
  Future<void> reduceProductStock(int productId, int quantity) async {
    final db = await instance.database;

    // Get current stock
    final result = await db.query(
      tableProducts,
      where: 'product_id = ?',
      whereArgs: [productId],
    );

    if (result.isNotEmpty) {
      final currentStock = result.first['stock'] as int;
      final newStock = (currentStock - quantity).clamp(0, currentStock);

      await db.update(
        tableProducts,
        {'stock': newStock},
        where: 'product_id = ?',
        whereArgs: [productId],
      );

      print(
        '📦 Stock reduced for product $productId: $currentStock -> $newStock',
      );
    }
  }

  // Reduce stock for multiple products (after checkout)
  Future<void> reduceMultipleProductStock(
    List<Map<String, dynamic>> items,
  ) async {
    for (var item in items) {
      await reduceProductStock(
        item['productId'] as int,
        item['quantity'] as int,
      );
    }
  }
}
