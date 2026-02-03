import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_ta/core/constants/colors.dart';
import 'package:project_ta/core/extensions/build_context_ext.dart';
import 'package:project_ta/data/datasources/auth_local_datasource.dart';
import 'package:project_ta/data/models/response/auth_response_model.dart';
import 'package:project_ta/presentation/auth/pages/login_page.dart';
import 'package:project_ta/presentation/home/pages/dashboard_page.dart';
import 'package:project_ta/presentation/setting/pages/manage_printer_page.dart';
import 'package:project_ta/presentation/setting/pages/report/report_page.dart';
import 'package:project_ta/presentation/setting/pages/sync_data_page.dart';
import 'package:project_ta/presentation/user_management/pages/user_list_page.dart';

import '../../../core/assets/assets.gen.dart';
import '../../../core/components/menu_button.dart';
import '../../../core/components/spaces.dart';
import '../../home/bloc/logout/logout_bloc.dart';
import 'manage_product_page.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  User? currentUser;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  // Load data user yang sedang login untuk cek role dan permission
  Future<void> _loadCurrentUser() async {
    try {
      final authData = await AuthLocalDatasource().getAuthData();
      setState(() {
        currentUser = authData?.user;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            context.push(const DashboardPage());
          },
        ),
        centerTitle: true,
        title: const Text(
          'Pengaturan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          const SpaceHeight(20.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                // Menu Setting Product hanya untuk admin
                if (currentUser?.roles == 'admin')
                  Flexible(
                    child: MenuButton(
                      iconPath: Assets.images.manageProduct.path,
                      label: 'Pengaturan Produk',
                      onPressed: () => context.push(const ManageProductPage()),
                      isImage: true,
                    ),
                  ),
                if (currentUser?.roles == 'admin') const SpaceWidth(15.0),
                Flexible(
                  child: MenuButton(
                    iconPath: Assets.images.managePrinter.path,
                    label: 'Pengaturan Printer',
                    onPressed: () {
                      context.push(const ManagePrinterPage());
                    },
                    isImage: true,
                  ),
                ),
              ],
            ),
          ),
          const SpaceHeight(20.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Flexible(
                  child: MenuButton(
                    iconPath: Assets.images.sync.path,
                    label: 'Sinkronkan Data',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SyncDataPage(),
                        ),
                      );
                    },
                    isImage: true,
                  ),
                ),
                // Menu User Management hanya untuk admin
                if (currentUser?.roles == 'admin') ...[
                  const SpaceWidth(15.0),
                  Flexible(
                    child: MenuButton(
                      iconPath: Assets
                          .images
                          .manageProduct
                          .path, // Using existing icon
                      label: 'Manajemen User',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UserListPage(),
                          ),
                        );
                      },
                      isImage: true,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SpaceHeight(20.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Flexible(
                  child: MenuButton(
                    iconPath: Assets.images.report.path,
                    label: 'Laporan',
                    onPressed: () => context.push(const ReportPage()),
                    isImage: true,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: BlocConsumer<LogoutBloc, LogoutState>(
              listener: (context, state) {
                state.maybeMap(
                  orElse: () {},
                  success: (_) {
                    // Hapus data auth dari local storage
                    AuthLocalDatasource().removeAuthData();
                    // Navigasi ke halaman login
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  },
                );
              },
              builder: (context, state) {
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: () {
                    context.read<LogoutBloc>().add(const LogoutEvent.logout());
                  },
                  child: const Text(
                    'Keluar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
