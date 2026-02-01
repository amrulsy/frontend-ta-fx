import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_ta/core/components/spaces.dart';
import 'package:project_ta/core/extensions/build_context_ext.dart';
import 'package:project_ta/presentation/home/bloc/product/product_bloc.dart';
import 'package:project_ta/presentation/setting/bloc/sync_order/sync_order_bloc.dart';

import '../../../core/constants/colors.dart';
import '../../../data/datasources/product_local_datasource.dart';
import '../../home/bloc/category/category_bloc.dart';

class SyncDataPage extends StatefulWidget {
  const SyncDataPage({super.key});

  @override
  State<SyncDataPage> createState() => _SyncDataPageState();
}

class _SyncDataPageState extends State<SyncDataPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            context.pop();
          },
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
        title: const Text('Sync Data'),
        centerTitle: true,
      ),
      //textfield untuk input server key
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          //button sync data product
          BlocConsumer<ProductBloc, ProductState>(
            listener: (context, state) {
              state.maybeMap(
                orElse: () {},
                success: (successState) async {
                  await ProductLocalDatasource.instance.removeAllProduct();
                  await ProductLocalDatasource.instance.insertAllProduct(
                    successState.products.toList(),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.primary,
                      content: Text('Sync data product success'),
                    ),
                  );
                },
              );
            },
            builder: (context, state) {
              return state.maybeWhen(
                orElse: () {
                  return ElevatedButton(
                    onPressed: () {
                      context.read<ProductBloc>().add(
                        const ProductEvent.fetch(),
                      );
                    },
                    child: const Text('Sync Data Product'),
                  );
                },
                loading: () {
                  return const Center(child: CircularProgressIndicator());
                },
              );
            },
          ),
          const SpaceHeight(20),
          //button sync data order
          BlocConsumer<SyncOrderBloc, SyncOrderState>(
            listener: (context, state) {
              state.maybeMap(
                orElse: () {},
                success: (_) async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.primary,
                      content: Text('Sync data orders success'),
                    ),
                  );
                },
                error: (errorState) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.red,
                      content: Text(errorState.message),
                    ),
                  );
                },
              );
            },
            builder: (context, state) {
              return state.maybeWhen(
                orElse: () {
                  return ElevatedButton(
                    onPressed: () {
                      context.read<SyncOrderBloc>().add(
                        const SyncOrderEvent.sendOrder(),
                      );
                    },
                    child: const Text('Sync Data Orders'),
                  );
                },
                loading: () {
                  return const Center(child: CircularProgressIndicator());
                },
              );
            },
          ),
          const SpaceHeight(20),
          //button sync categories
          BlocConsumer<CategoryBloc, CategoryState>(
            listener: (context, state) {
              state.maybeMap(
                orElse: () {},
                loaded: (data) async {
                  await ProductLocalDatasource.instance.removeAllCategories();
                  await ProductLocalDatasource.instance.insertAllCategories(
                    data.categories,
                  );
                  context.read<CategoryBloc>().add(
                    const CategoryEvent.getCategoriesLocal(),
                  );
                  context.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.primary,
                      content: Text('Sync data categories success'),
                    ),
                  );
                },
              );
            },
            builder: (context, state) {
              return state.maybeWhen(
                orElse: () {
                  return ElevatedButton(
                    onPressed: () {
                      context.read<CategoryBloc>().add(
                        const CategoryEvent.getCategories(),
                      );
                    },
                    child: const Text('Sync Data Categories'),
                  );
                },
                loading: () {
                  return const Center(child: CircularProgressIndicator());
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
