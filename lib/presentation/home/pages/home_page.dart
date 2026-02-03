import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_ta/core/constants/colors.dart';
import 'package:project_ta/presentation/home/bloc/product/product_bloc.dart';
import 'package:project_ta/core/utils/connectivity_helper.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../core/assets/assets.gen.dart';
import '../../../core/components/menu_button.dart';
import '../../../core/components/search_input.dart';
import '../../../core/components/spaces.dart';
import '../../../data/datasources/auth_local_datasource.dart';
import '../bloc/category/category_bloc.dart';
import '../widgets/product_card.dart';
import '../widgets/product_empty.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final searchController = TextEditingController();
  final indexValue = ValueNotifier(0);
  int currentIndex = 0;

  @override
  void initState() {
    // Load produk dan kategori dari database lokal saat halaman pertama kali dibuka
    context.read<ProductBloc>().add(const ProductEvent.fetchLocal());
    context.read<CategoryBloc>().add(const CategoryEvent.getCategoriesLocal());
    // Koneksi ke printer yang tersimpan
    AuthLocalDatasource().getPrinter().then((value) async {
      if (value.isNotEmpty) {
        await PrintBluetoothThermal.connect(macPrinterAddress: value);
      }
    });
    super.initState();
  }

  // Fungsi untuk handle ketika kategori dipilih
  void onCategoryTap(int index) {
    searchController.clear();
    setState(() {
      currentIndex = index;
    });
  }

  // Widget badge untuk menampilkan status koneksi internet (Online/Offline)
  Widget _buildStatusBadge(bool isOnline) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOnline ? AppColors.white.withOpacity(0.2) : Colors.red,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            isOnline ? Icons.wifi : Icons.wifi_off,
            color: Colors.white,
            size: 16,
          ),
          const SpaceWidth(8),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primary,
        title: const Text(
          'Katalog',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          StreamBuilder<List<ConnectivityResult>>(
            stream: ConnectivityHelper().onConnectivityChanged,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final isOnline = !snapshot.data!.contains(
                  ConnectivityResult.none,
                );
                return _buildStatusBadge(isOnline);
              }
              // If no stream data yet, check once
              return FutureBuilder<bool>(
                future: ConnectivityHelper().isConnected(),
                builder: (_, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const SizedBox();
                  }
                  return _buildStatusBadge(snap.data ?? false);
                },
              );
            },
          ),
          const SpaceWidth(16),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SearchInput(
            controller: searchController,
            onChanged: (value) {
              if (value.isNotEmpty) {
                context.read<ProductBloc>().add(
                  ProductEvent.searchProduct(value),
                );
              } else {
                context.read<ProductBloc>().add(
                  const ProductEvent.fetchAllFromState(),
                );
              }
            },
          ),
          const SpaceHeight(16.0),
          BlocBuilder<CategoryBloc, CategoryState>(
            builder: (context, state) {
              return state.maybeWhen(
                orElse: () {
                  return const SizedBox();
                },
                loading: () {
                  return const Center(child: CircularProgressIndicator());
                },
                error: (message) {
                  return Center(child: Text(message));
                },
                loadedLocal: (categories) {
                  return SizedBox(
                    height: 120,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        SizedBox(
                          width: 90,
                          child: MenuButton(
                            iconPath: Assets.icons.allCategories.path,
                            label: 'Semua',
                            isActive: currentIndex == 0,
                            onPressed: () {
                              onCategoryTap(0);
                              context.read<ProductBloc>().add(
                                const ProductEvent.fetchLocal(),
                              );
                            },
                          ),
                        ),
                        const SpaceWidth(10.0),
                        ...categories
                            .map(
                              (e) => SizedBox(
                                width: 90,
                                child: MenuButton(
                                  iconPath: Assets.icons.allCategories.path,
                                  label: e.name,
                                  isActive: currentIndex == e.id,
                                  onPressed: () {
                                    onCategoryTap(e.id);
                                    context.read<ProductBloc>().add(
                                      ProductEvent.fetchByCategory(e.name),
                                    );
                                  },
                                ),
                              ),
                            )
                            .toList(),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          const SpaceHeight(16.0),
          BlocBuilder<ProductBloc, ProductState>(
            builder: (context, state) {
              return state.maybeWhen(
                orElse: () {
                  return const SizedBox();
                },
                loading: () {
                  return const Center(child: CircularProgressIndicator());
                },
                error: (message) {
                  return Center(child: Text(message));
                },
                success: (products) {
                  if (products.isEmpty) return const ProductEmpty();
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: products.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          childAspectRatio: 0.75,
                          crossAxisCount: 2,
                          crossAxisSpacing: 16.0,
                          mainAxisSpacing: 16.0,
                        ),
                    itemBuilder: (context, index) =>
                        ProductCard(data: products[index]),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
