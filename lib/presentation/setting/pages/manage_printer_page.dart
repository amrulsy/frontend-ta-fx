import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_ta/core/extensions/build_context_ext.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import '../../../core/components/spaces.dart';
import '../../../core/constants/colors.dart';
import '../../../data/datasources/auth_local_datasource.dart';
import '../widgets/menu_printer_button.dart';
import '../widgets/menu_printer_content.dart';

class ManagePrinterPage extends StatefulWidget {
  const ManagePrinterPage({super.key});

  @override
  State<ManagePrinterPage> createState() => _ManagePrinterPageState();
}

class _ManagePrinterPageState extends State<ManagePrinterPage> {
  int selectedIndex = 0;

  String macName = '';
  String? macConnected;

  bool connected = false;
  List<BluetoothInfo> items = [];

  String optionprinttype = "58mm";
  List<String> options = ["58mm", "80mm"];

  @override
  void initState() {
    super.initState();
    initPlatformState();
    loadDataPrinter();
    getBluetoots();
  }

  loadDataPrinter() async {
    macConnected = await AuthLocalDatasource().getPrinter();
    if (macConnected != '') {
      macName = macConnected!;
      await connect(macName);
    }
    optionprinttype = await AuthLocalDatasource().getSizePrinter();

    setState(() {});
  }

  Future<void> initPlatformState() async {
    String platformVersion;
    int porcentbatery = 0;

    try {
      platformVersion = await PrintBluetoothThermal.platformVersion;

      porcentbatery = await PrintBluetoothThermal.batteryLevel;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    if (!mounted) return;

    final bool result = await PrintBluetoothThermal.bluetoothEnabled;
  }

  Future<void> getBluetoots() async {
    setState(() {
      items = [];
    });
    var status2 = await Permission.bluetoothScan.status;
    if (status2.isDenied) {
      await Permission.bluetoothScan.request();
    }
    var status = await Permission.bluetoothConnect.status;
    if (status.isDenied) {
      await Permission.bluetoothConnect.request();
    }

    final List<BluetoothInfo> listResult =
        await PrintBluetoothThermal.pairedBluetooths;

    setState(() {
      items = listResult;
    });
  }

  Future<void> connect(String mac) async {
    setState(() {
      connected = false;
    });
    final bool result =
        await PrintBluetoothThermal.connect(macPrinterAddress: mac);

    connected = true;
    AuthLocalDatasource().savePrinter(mac);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Printer connected with Name $mac'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Future<void> disconnect() async {
    final bool status = await PrintBluetoothThermal.disconnect;
    setState(() {
      connected = false;
    });
    print("status disconnect $status");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              context.pop();
            },
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white)),
        title: const Text('Printer Management'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Container(
            width: context.deviceWidth / 2,
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(8),
            ),
            child: MenuPrinterButton(
              label: 'Search',
              onPressed: () {
                getBluetoots();
                selectedIndex = 0;
                setState(() {});
              },
              isActive: true,
            ),
          ),
          const SpaceHeight(16.0),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Paper Width Size: ',
                style: TextStyle(
                  color: AppColors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SpaceWidth(8.0),
              DropdownButton<String>(
                value: optionprinttype,
                items: const [
                  DropdownMenuItem(
                    value: '58mm',
                    child: Text('58mm'),
                  ),
                  DropdownMenuItem(
                    value: '80mm',
                    child: Text('80mm'),
                  ),
                ],
                onChanged: (String? value) async {
                  await AuthLocalDatasource().saveSizePrinter(value!);
                  setState(() {
                    optionprinttype = value;
                  });
                },
              ),
            ],
          ),
          const SpaceHeight(16.0),
          _Body(
            macName: macName,
            datas: items,
            clickHandler: (mac) async {
              macName = mac;
              await connect(mac);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final String macName;
  final List<BluetoothInfo> datas;

  final Function(String) clickHandler;

  const _Body({
    Key? key,
    required this.macName,
    required this.datas,
    required this.clickHandler,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (datas.isEmpty) {
      return const Text('No data available');
    } else {
      return Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.card, width: 2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: datas.length,
          separatorBuilder: (context, index) => const SpaceHeight(16.0),
          itemBuilder: (context, index) => InkWell(
            onTap: () {
              clickHandler(datas[index].macAdress);
            },
            child: MenuPrinterContent(
              isSelected: macName == datas[index].macAdress,
              data: datas[index],
            ),
          ),
        ),
      );
    }
  }
}
