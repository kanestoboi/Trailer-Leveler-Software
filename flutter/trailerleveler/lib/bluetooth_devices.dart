import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'dart:async';
import 'dart:math';

import 'package:flutter_blue/gen/flutterblue.pbjson.dart';

FlutterBlue flutterBlue = FlutterBlue.instance;

double x, y, z = 0.0;
int xoutput = 0;
int youtput = 0;
int zoutput = 0;
int minVal = -262144;
int maxVal = 262144;

double RAD_TO_DEG = 57.296;
double PI = 3.14;

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

    BluetoothCharacteristic readCharacteristic;

    for (BluetoothService service in services) {
      if (service.uuid == new Guid("76491400-7DD9-11ED-A1EB-0242AC120002")) {
        List<BluetoothCharacteristic> characteristics = service.characteristics;

        for (BluetoothCharacteristic characteristic in characteristics) {
          if (characteristic.uuid ==
              new Guid("76491401-7DD9-11ED-A1EB-0242AC120002")) {
            print("Write characteristic found!!");
            readCharacteristic = characteristic;
          }
        }
      }

      if (service.uuid == new Guid("0000FFE0-0000-1000-8000-00805F9B34FB")) {
        List<BluetoothCharacteristic> characteristics = service.characteristics;

        for (BluetoothCharacteristic characteristic in characteristics) {
          if (characteristic.uuid ==
              new Guid("0000FFE1-0000-1000-8000-00805F9B34FB")) {
            print("Write characteristic found!!");
            readCharacteristic = characteristic;
          }
        }
      }
    }

    await readCharacteristic.setNotifyValue(true);
    readCharacteristic.value.listen((value) async {
      if (value.length == 12) {
        int accX = (value[3] << 24 | value[2] << 16 | value[1] << 8 | value[0]);
        int accY = (value[7] << 24 | value[6] << 16 | value[5] << 8 | value[4]);
        int accZ =
            (value[11] << 24 | value[10] << 16 | value[9] << 8 | value[8]);

        int maskedN = (value[2] & (1 << 2));
        int thebit = maskedN >> 2;

        print("Value[0]" + (value[0]).toString());

        if (thebit == 1) {
          accX = accX | 0xFFFFFFFFFF000000;
        }

        print(accX);

        maskedN = (value[6] & (1 << 2));
        thebit = maskedN >> 2;

        if (thebit == 1) {
          accY = accY | 0xFFFFFFFFFF000000;
        }

        maskedN = (value[10] & (1 << 2));
        thebit = maskedN >> 2;

        if (thebit == 1) {
          accZ = accZ | 0xFFFFFFFFFF000000;
        }

        xoutput = (0.9896 * xoutput + 0.01042 * accX).round();
        youtput = (0.9896 * youtput + 0.01042 * accY).round();
        zoutput = (0.9896 * zoutput + 0.01042 * accZ).round();

        double xAng = map(xoutput, minVal, maxVal, -90, 90);
        double yAng = map(youtput, minVal, maxVal, -90, 90);
        double zAng = map(zoutput, minVal, maxVal, -90, 90);

        //print(
        //"x: $accX, y: $accY, z: $accZ, xAng: $xAng, yAng: $yAng, zAng: $zAng");

        x = RAD_TO_DEG * (atan2(-yAng, -zAng) + PI);
        //x = num.parse(x.toStringAsFixed(2));
        y = RAD_TO_DEG * (atan2(-xAng, -zAng) + PI);
        //y = num.parse(y.toStringAsFixed(2));
        z = RAD_TO_DEG * (atan2(-yAng, -xAng) + PI);
        //z = num.parse(z.toStringAsFixed(2));

        var obj = {"xAngle": x, "yAngle": y, "zAngle": z};

        print("x: $x, y: $y, z: $z");

        _streamController.sink.add(obj);
      }
    });

    Navigator.pop(context, stream);
  }
}

double map(int value, int low1, int high1, int low2, int high2) {
  return low2 + ((high2 - low2) * (value - low1) / (high1 - low1));
}
