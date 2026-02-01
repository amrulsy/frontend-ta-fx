import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_ta/core/extensions/string_ext.dart';
import 'package:project_ta/presentation/setting/models/category_model.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/components/buttons.dart';
import '../../../core/utils/connectivity_helper.dart';
import '../../../core/components/custom_dropdown.dart';
import '../../../core/components/custom_text_field.dart';
import '../../../core/components/image_picker_widget.dart';
import '../../../core/components/spaces.dart';
import '../../../data/models/response/category_response_model.dart';
import '../../../data/models/response/product_response_model.dart';
import '../../home/bloc/category/category_bloc.dart';
import '../../home/bloc/product/product_bloc.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  TextEditingController? nameController;
  TextEditingController? priceController;
  TextEditingController? stockController;

  Category? category;

  XFile? imageFile;

  bool isBestSeller = false;

  final List<CategoryModel> categories = [
    CategoryModel(name: 'Drink', value: 'drink'),
    CategoryModel(name: 'Food', value: 'food'),
    CategoryModel(name: 'Snack', value: 'snack'),
  ];

  @override
  void initState() {
    nameController = TextEditingController();
    priceController = TextEditingController();
    stockController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    nameController!.dispose();
    priceController!.dispose();
    stockController!.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Add Product',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          CustomTextField(controller: nameController!, label: 'Product Name'),
          const SpaceHeight(16.0),
          CustomTextField(
            controller: priceController!,
            label: 'Product Price',
            keyboardType: TextInputType.number,
            onChanged: (value) {},
          ),
          const SpaceHeight(16.0),
          ImagePickerWidget(
            label: 'Photo',
            onChanged: (file) {
              if (file == null) {
                return;
              }
              imageFile = file;
            },
          ),
          const SpaceHeight(16.0),
          CustomTextField(
            controller: stockController!,
            label: 'Stock',
            keyboardType: TextInputType.number,
          ),
          const SpaceHeight(16.0),
          Row(
            children: [
              Checkbox(
                value: isBestSeller,
                onChanged: (value) {
                  setState(() {
                    isBestSeller = value!;
                  });
                },
              ),
              const Text('Best Seller'),
            ],
          ),
          const SpaceHeight(16.0),
          BlocBuilder<CategoryBloc, CategoryState>(
            builder: (context, state) {
              List<Category> categories = [];
              state.maybeWhen(
                orElse: () {},
                loadedLocal: (data) {
                  categories = data;
                },
              );
              return CustomDropdown<Category>(
                value: categories.first,
                items: categories,
                label: 'Category',
                onChanged: (value) {
                  category = value!;
                },
              );
            },
          ),
          const SpaceHeight(16.0),
          Row(
            children: [
              Expanded(
                child: Button.outlined(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  label: 'Batal',
                ),
              ),
              const SpaceWidth(16.0),
              Expanded(
                child: BlocConsumer<ProductBloc, ProductState>(
                  listener: (context, state) {
                    state.maybeMap(
                      orElse: () {},
                      success: (_) {
                        Navigator.pop(context);
                      },
                    );
                  },
                  builder: (context, state) {
                    return state.maybeWhen(
                      orElse: () {
                        return const Center(child: CircularProgressIndicator());
                      },
                      loading: () {
                        return const Center(child: CircularProgressIndicator());
                      },
                      success: (_) {
                        return Button.filled(
                          onPressed: () async {
                            // Check internet connectivity
                            final isConnected = await ConnectivityHelper()
                                .isConnected();

                            if (!isConnected) {
                              // Show offline dialog
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Row(
                                    children: [
                                      Icon(Icons.wifi_off, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('No Internet Connection'),
                                    ],
                                  ),
                                  content: const Text(
                                    'Please connect to the internet to add a product.',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                              return;
                            }

                            // Validate inputs
                            if (nameController!.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter product name'),
                                ),
                              );
                              return;
                            }

                            if (imageFile == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please select an image'),
                                ),
                              );
                              return;
                            }

                            final String name = nameController!.text;
                            final int price =
                                priceController!.text.toIntegerFromText;
                            final int stock =
                                stockController!.text.toIntegerFromText;
                            final Product product = Product(
                              name: name,
                              price: price,
                              stock: stock,
                              category: '',
                              categoryId: category!.id,
                              isBestSeller: isBestSeller,
                              image: imageFile!.path,
                            );
                            context.read<ProductBloc>().add(
                              ProductEvent.addProduct(product, imageFile!),
                            );
                          },
                          label: 'Simpan',
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          const SpaceHeight(20.0),
        ],
      ),
    );
  }
}
