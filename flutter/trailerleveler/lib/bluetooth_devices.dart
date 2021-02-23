import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'dart:async';

FlutterBlue flutterBlue = FlutterBlue.instance;

class BluetoothDevices extends StatefulWidget {
  BluetoothDevices({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _BluetoothDevicesState createState() => _BluetoothDevicesState();

  Widget build(BuildContext context) {
    return BluetoothDevices();
  }
}

class _BluetoothDevicesState extends State<BluetoothDevices> {
  final _devices = <BluetoothDevice>[];

  String one = "0";
  String two = "0";

  @override
  dispose() async {
    super.dispose();
  }

  Widget _buildList() {
    return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _devices.length,
        itemBuilder: (context, item) => this._buildRow(_devices[item]));
  }

  Widget _buildRow(BluetoothDevice device) {
    return ListTile(
      title: Text(device.name),
      trailing: Text("Connect"),
      onTap: () => connectToDevice(device),
    );
  }

  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Discover Devices'), actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add_link),
            onPressed: () async {
              Navigator.pop(context, 'Yep!');
            },
          ),
        ]),
        body: _buildList(),
        floatingActionButton: StreamBuilder<bool>(
          stream: FlutterBlue.instance.isScanning,
          initialData: false,
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.data) {
              return FloatingActionButton(
                child: Icon(Icons.stop),
                onPressed: stopScanPressed,
                backgroundColor: Colors.red,
              );
            } else {
              return FloatingActionButton(
                  child: Icon(Icons.refresh), onPressed: refreshPressed);
            }
          },
        ),
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          child: Container(
            height: 50.0,
            child: Center(
              child: Column(
                  children: <Widget>[Text('One: ${one}'), Text('One: ${two}')]),
            ),
          ),
        ));
  }

  void stopScanPressed() {
    FlutterBlue.instance.stopScan();
  }

  void refreshPressed() {
    // Clear the devices in the discovered list
    _devices.clear();
    // clear the ListView
    setState(() => {});

    // Listen to scan results
    flutterBlue.scanResults.listen((results) {
      // Add unique scan results to _devices list
      for (ScanResult r in results) {
        if (r.device.name != '' && !_devices.contains(r.device)) {
          print('${r.device.name} found! rssi: ${r.rssi}, ID: ${r.device.id}');
          _devices.add(r.device);
          setState(() => {});
        }
      }
    });

    print("starting scan");
    FlutterBlue.instance.startScan(timeout: Duration(seconds: 8));
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    final _streamController = StreamController<Map<String, double>>();

    Stream<Map<String, double>> stream = _streamController.stream;

    await device.connect();
    List<BluetoothService> services = await device.discoverServices();

    await services[2].characteristics[0].setNotifyValue(true);
    services[2].characteristics[0].value.listen((value) async {
      if (value.length == 7) {
        var obj = {
          "xAngle": ((value[0] << 8) + value[1] + value[2] / 100.0),
          "yAngle": ((value[3] << 8) + value[4] + value[5] / 100.0)
        };

        _streamController.sink.add(obj);
      }
    });

    Navigator.pop(context, stream);
  }
}
