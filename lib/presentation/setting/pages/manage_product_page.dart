import 'package:flutter/material.dart';
import 'package:project_ta/core/utils/connectivity_helper.dart';
import 'package:project_ta/presentation/product/pages/product_list_page.dart';
import 'package:project_ta/presentation/category/pages/category_list_page.dart';
import 'package:project_ta/presentation/product/pages/product_form_page.dart';
import 'package:project_ta/presentation/category/pages/category_form_page.dart';

class ManageProductPage extends StatefulWidget {
  const ManageProductPage({super.key});

  @override
  State<ManageProductPage> createState() => _ManageProductPageState();
}

class _ManageProductPageState extends State<ManageProductPage> {
  // Status koneksi internet untuk mengaktifkan/menonaktifkan fitur
  bool isOnline = true;

  @override
  void initState() {
    super.initState();
    // Cek konektivitas saat halaman pertama kali dibuka
    _checkConnectivity();
  }

  // Fungsi untuk memeriksa status koneksi internet
  Future<void> _checkConnectivity() async {
    final connected = await ConnectivityHelper().isConnected();
    setState(() {
      isOnline = connected;
    });
  }

  // Fungsi navigasi dengan pengecekan koneksi internet terlebih dahulu
  Future<void> _navigateWithConnectivityCheck(
    BuildContext context,
    Widget page,
  ) async {
    final connected = await ConnectivityHelper().isConnected();
    if (!connected) {
      _showOfflineDialog();
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  // Tampilkan dialog peringatan ketika tidak ada koneksi internet
  void _showOfflineDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.red),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Tidak Ada Koneksi Internet',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: const Text(
          'Silakan hubungkan ke internet untuk mengelola produk dan kategori.',
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
          'Manajemen',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Pilih apa yang ingin Anda kelola:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),

            // Card navigasi untuk manajemen produk
            Card(
              elevation: 4,
              child: InkWell(
                onTap: () async {
                  await _navigateWithConnectivityCheck(
                    context,
                    const ProductListPage(),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.inventory,
                          color: Colors.blue,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Manajemen Produk',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Kelola produk Anda, tambah item baru, edit yang ada, dan hapus produk.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Card navigasi untuk manajemen kategori
            Card(
              elevation: 4,
              child: InkWell(
                onTap: () async {
                  await _navigateWithConnectivityCheck(
                    context,
                    const CategoryListPage(),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.category,
                          color: Colors.green,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Manajemen Kategori',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Kelola kategori produk, buat kategori baru, dan organisir produk Anda.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Tombol aksi cepat
            const Text(
              'Aksi Cepat:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isOnline
                        ? () async {
                            await _navigateWithConnectivityCheck(
                              context,
                              const ProductFormPage(),
                            );
                          }
                        : null, // Tombol dinonaktifkan saat offline
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Produk'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isOnline
                        ? () async {
                            await _navigateWithConnectivityCheck(
                              context,
                              const CategoryFormPage(),
                            );
                          }
                        : null, // Tombol dinonaktifkan saat offline
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Kategori'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
