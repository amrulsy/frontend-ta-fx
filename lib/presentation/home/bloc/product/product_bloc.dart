import 'package:bloc/bloc.dart';
import 'package:project_ta/data/datasources/product_local_datasource.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:project_ta/data/datasources/product_remote_datasource.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../data/models/request/product_request_model.dart';
import '../../../../data/models/response/product_response_model.dart';

part 'product_bloc.freezed.dart';
part 'product_event.dart';
part 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRemoteDatasource _productRemoteDatasource;
  List<Product> products = [];
  // Helper to sort products: Available first, Out of Stock last
  void _sortProducts(List<Product> list) {
    list.sort((a, b) {
      if (a.stock > 0 && b.stock == 0) return -1; // a comes first
      if (a.stock == 0 && b.stock > 0) return 1; // b comes first
      return 0; // maintain original order otherwise
    });
  }

  ProductBloc(this._productRemoteDatasource) : super(const _Initial()) {
    on<_Fetch>((event, emit) async {
      emit(const ProductState.loading());
      final response = await _productRemoteDatasource.getProducts();
      response.fold((l) => emit(ProductState.error(l)), (r) {
        products = r.data;
        _sortProducts(products); // Sort
        emit(ProductState.success(products));
      });
    });

    on<_FetchLocal>((event, emit) async {
      emit(const ProductState.loading());
      final localPproducts = await ProductLocalDatasource.instance
          .getAllProduct();
      products = localPproducts;
      _sortProducts(products); // Sort
      emit(ProductState.success(products));
    });

    on<_FetchByCategory>((event, emit) async {
      emit(const ProductState.loading());

      final newProducts = event.category == 'all'
          ? List<Product>.from(products)
          : products
                .where((element) => element.category == event.category)
                .toList();

      _sortProducts(newProducts); // Sort
      emit(ProductState.success(newProducts));
    });

    on<_AddProduct>((event, emit) async {
      emit(const ProductState.loading());
      final requestData = ProductRequestModel(
        name: event.product.name,
        price: event.product.price,
        stock: event.product.stock,
        categoryId: event.product.categoryId,
        isBestSeller: event.product.isBestSeller ? 1 : 0,
        image: event.image,
      );
      final response = await _productRemoteDatasource.addProduct(requestData);

      response.fold((l) => emit(ProductState.error(l)), (r) {
        products.add(r.data);
        _sortProducts(products); // Sort
        emit(ProductState.success(products));
      });
    });

    on<_SearchProduct>((event, emit) async {
      emit(const ProductState.loading());
      final newProducts = products
          .where(
            (element) =>
                element.name.toLowerCase().contains(event.query.toLowerCase()),
          )
          .toList();

      _sortProducts(newProducts); // Sort
      emit(ProductState.success(newProducts));
    });

    on<_FetchAllFromState>((event, emit) async {
      emit(const ProductState.loading());
      _sortProducts(products); // Sort (just in case)
      emit(ProductState.success(products));
    });
  }
}
