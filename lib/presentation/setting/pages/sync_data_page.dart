import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_ta/core/components/spaces.dart';
import 'package:project_ta/core/extensions/build_context_ext.dart';
import 'package:project_ta/core/utils/connectivity_helper.dart';
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
        title: const Text('Sinkronkan Data'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          // Tombol sinkronisasi data produk dari server ke local database
          BlocConsumer<ProductBloc, ProductState>(
            listener: (context, state) {
              state.maybeMap(
                orElse: () {},
                success: (successState) async {
                  // Gunakan smart sync untuk menghindari delete semua data lalu insert ulang
                  // Smart sync hanya update data yang berubah
                  await ProductLocalDatasource.instance.syncProducts(
                    successState.products.toList(),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.primary,
                      content: Text('Sinkronisasi data produk berhasil'),
                    ),
                  );
                },
              );
            },
            builder: (context, state) {
              return state.maybeWhen(
                orElse: () {
                  return ElevatedButton(
                    onPressed: () async {
                      // Cek koneksi internet sebelum melakukan sinkronisasi
                      final isConnected = await ConnectivityHelper()
                          .isConnected();
                      if (!isConnected) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Colors.orange,
                            content: Text(
                              'Tidak ada koneksi internet. Silakan hubungkan untuk sinkronisasi data.',
                            ),
                          ),
                        );
                        return;
                      }

                      // Trigger event untuk fetch data produk dari server
                      context.read<ProductBloc>().add(
                        const ProductEvent.fetch(),
                      );
                    },
                    child: const Text('Sinkronkan Data Produk'),
                  );
                },
                loading: () {
                  return const Center(child: CircularProgressIndicator());
                },
              );
            },
          ),
          const SpaceHeight(20),
          // Tombol sinkronisasi data pesanan lokal ke server
          BlocConsumer<SyncOrderBloc, SyncOrderState>(
            listener: (context, state) {
              state.maybeMap(
                orElse: () {},
                success: (_) async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.primary,
                      content: Text('Sinkronisasi data pesanan berhasil'),
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
                    onPressed: () async {
                      // Cek koneksi internet sebelum mengirim data
                      final isConnected = await ConnectivityHelper()
                          .isConnected();
                      if (!isConnected) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Colors.orange,
                            content: Text(
                              'Tidak ada koneksi internet. Silakan hubungkan untuk sinkronisasi data.',
                            ),
                          ),
                        );
                        return;
                      }

                      // Trigger event untuk mengirim data pesanan lokal ke server
                      context.read<SyncOrderBloc>().add(
                        const SyncOrderEvent.sendOrder(),
                      );
                    },
                    child: const Text('Sinkronkan Data Pesanan'),
                  );
                },
                loading: () {
                  return const Center(child: CircularProgressIndicator());
                },
              );
            },
          ),
          const SpaceHeight(20),
          // Tombol sinkronisasi data kategori dari server ke local database
          BlocConsumer<CategoryBloc, CategoryState>(
            listener: (context, state) {
              state.maybeMap(
                orElse: () {},
                loaded: (data) async {
                  // Hapus semua kategori lokal terlebih dahulu
                  await ProductLocalDatasource.instance.removeAllCategories();
                  // Insert kategori baru dari server
                  await ProductLocalDatasource.instance.insertAllCategories(
                    data.categories,
                  );
                  // Refresh kategori dari local database
                  context.read<CategoryBloc>().add(
                    const CategoryEvent.getCategoriesLocal(),
                  );
                  context.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.primary,
                      content: Text('Sinkronisasi data kategori berhasil'),
                    ),
                  );
                },
              );
            },
            builder: (context, state) {
              return state.maybeWhen(
                orElse: () {
                  return ElevatedButton(
                    onPressed: () async {
                      // Cek koneksi internet sebelum melakukan sinkronisasi
                      final isConnected = await ConnectivityHelper()
                          .isConnected();
                      if (!isConnected) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Colors.orange,
                            content: Text(
                              'Tidak ada koneksi internet. Silakan hubungkan untuk sinkronisasi data.',
                            ),
                          ),
                        );
                        return;
                      }

                      // Trigger event untuk fetch data kategori dari server
                      context.read<CategoryBloc>().add(
                        const CategoryEvent.getCategories(),
                      );
                    },
                    child: const Text('Sinkronkan Data Kategori'),
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
