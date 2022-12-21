import 'dart:async';

import 'package:flutter/material.dart';
import 'package:trailerleveler/bluetooth_devices.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:intl/intl.dart';

FlutterBlue flutterBlue = FlutterBlue.instance;

class AnglesPage extends StatefulWidget {
  @override
  PageState createState() => PageState();
}

class PageState extends State<AnglesPage> {
  double _xAngleCalibration = 0.0;
  double _yAngleCalibration = 0.0;
  double _zAngleCalibration = 0.0;
  double _xAngle = 0.0;
  double _yAngle = 0.0;
  double _zAngle = 0.0;

  double _caravanWidth = 2.4;
  double _caravanLength = 2.4;

  String downArrow = "\u2b07";
  String upArrow = "\u2b06";

  String horizontalReference = 'right';

  // save in the state for caching!
  SharedPreferences _sharedPreferences;

  @override
  void initState() {
    super.initState();
    setupSharedPreferences();
  }

  setupSharedPreferences() async {
    _sharedPreferences = await SharedPreferences.getInstance();

    double xAngleSharedPreferences =
        _sharedPreferences.getDouble('xAngleCalibration') ?? 0;

    double yAngleSharedPreferences =
        _sharedPreferences.getDouble('yAngleCalibration') ?? 0;

    double zAngleSharedPreferences =
        _sharedPreferences.getDouble('zAngleCalibration') ?? 0;

    _xAngleCalibration = xAngleSharedPreferences;
    _yAngleCalibration = yAngleSharedPreferences;
    _zAngleCalibration = zAngleSharedPreferences;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: PreferredSize(
            preferredSize: const Size(double.infinity, kToolbarHeight),
            child: Builder(
                builder: (context) => AppBar(
                        title: const Text('Trailer Leveler'),
                        actions: <Widget>[
                          IconButton(
                            icon: const Icon(Icons.add_link),
                            onPressed: () async {
                              MaterialPageRoute newRoute = MaterialPageRoute(
                                  builder: (BuildContext context) =>
                                      BluetoothDevices());

                              final result =
                                  await Navigator.of(context).push(newRoute);

                              //print('content ${result}');

                              result.listen((value) {
                                setState(() {
                                  _xAngle = value['xAngle'];
                                  _yAngle = value['yAngle'];
                                  _zAngle = value['zAngle'];
                                });
                              });
                            },
                          ),
                          PopupMenuButton<String>(
                            onSelected: handleClick,
                            itemBuilder: (BuildContext context) {
                              return {'Calibrate', 'Set Caravan Dimensions'}
                                  .map((String choice) {
                                return PopupMenuItem<String>(
                                  value: choice,
                                  child: Text(choice),
                                );
                              }).toList();
                            },
                          ),
                        ]))

            // StreamBuilder
            ),
        body: Center(
            child: Column(
          children: [
            Center(
                child: Transform.rotate(
                    angle: pi / 180.0 * (_xAngle - _xAngleCalibration),
                    child: Image.asset('images/camper_rear.png', width: 100))),
            Row(children: <Widget>[
              Expanded(child: getLeftHeightStringWidget()),
              Expanded(child: getRightHeightStringWidget()),
            ]),
            Padding(
              padding: const EdgeInsets.all(30.0),
              child: Center(
                  child: Transform.rotate(
                      angle: pi / 180 * (_yAngle - _yAngleCalibration),
                      child:
                          Image.asset('images/camper_side.png', width: 150))),
            ),
            Row(children: <Widget>[
              Expanded(
                  child: Padding(
                padding: const EdgeInsets.fromLTRB(50.0, 0, 0, 0),
                child: getJockyHeightWidget(),
              )),
            ])
          ],
        )),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: setXAngle,
        ));
  }

  setXAngle() {
    setState(() => {_xAngle++});
  }

  setYAngle(double angle) {
    _yAngle = angle;
  }

  Widget getLeftHeightStringWidget() {
    double height;

    if (horizontalReference != 'left') {
      height = num.parse(
          (tan((_xAngle - _xAngleCalibration) * pi / 180.0) * _caravanWidth)
              .toStringAsFixed(3));
    } else {
      height = 0.0;
    }

    var format = new NumberFormat("##0.000", "en_US");

    String heightString;
    Color textColor = Colors.red;

    if (height > 0) {
      heightString = '$downArrow ${format.format(height.abs())}';
    } else if (height < 0) {
      heightString = '$upArrow ${format.format(height.abs())}';
    } else {
      heightString = '0.00';
      textColor = Colors.green;
    }

    return Text(heightString,
        textAlign: TextAlign.center,
        style: TextStyle(
            fontSize: 36, color: textColor, fontWeight: FontWeight.bold));
  }

  Widget getRightHeightStringWidget() {
    double height;

    if (horizontalReference != 'right') {
      height = num.parse(
          (tan((_xAngle - _xAngleCalibration) * pi / 180.0) * _caravanWidth)
              .toStringAsFixed(3));
    } else {
      height = 0.0;
    }

    var format = new NumberFormat("##0.000", "en_US");

    String heightString;
    Color textColor = Colors.red;

    if (height < 0) {
      heightString = '$downArrow ${format.format(height.abs())}';
    } else if (height > 0) {
      heightString = '$upArrow ${format.format(height.abs())}';
    } else {
      heightString = '0.00';
      textColor = Colors.green;
    }

    return Text(
      heightString,
      textAlign: TextAlign.center,
      style: TextStyle(
          fontSize: 36, color: textColor, fontWeight: FontWeight.bold),
    );
  }

  Widget getJockyHeightWidget() {
    double height = num.parse(
        (tan((_yAngle - _yAngleCalibration) * pi / 180.0) * _caravanLength)
            .toStringAsFixed(3));

    var format = new NumberFormat("##0.000", "en_US");

    String heightString;
    Color textColor = Colors.red;

    if (height > 0) {
      heightString = '$downArrow ${format.format(height.abs())}';
    } else if (height < 0) {
      heightString = '$upArrow ${format.format(height.abs())}';
    } else {
      heightString = '0.00';
      textColor = Colors.green;
    }

    return Text(
      heightString,
      textAlign: TextAlign.left,
      style: TextStyle(
          fontSize: 36, color: textColor, fontWeight: FontWeight.bold),
    );
  }

  Future<void> handleClick(String value) async {
    switch (value) {
      case 'Calibrate':
        {
          await _showCalibrationDialog();
          _xAngleCalibration = _xAngle;
          _yAngleCalibration = _yAngle;
          _zAngleCalibration = _zAngle;
          _sharedPreferences.setDouble('xAngleCalibration', _xAngleCalibration);
          _sharedPreferences.setDouble('yAngleCalibration', _yAngleCalibration);
          _sharedPreferences.setDouble('zAngleCalibration', _zAngleCalibration);

          break;
        }
      case 'Set Caravan Dimensions':
        {
          await _showDimensionsDialog();
          break;
        }
    }
  }

  Future<void> _showCalibrationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Calibrate Trailer Leveler'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('This will calibrate the sensor.'),
                Text('Make sure that the device is level and press OK.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDimensionsDialog() async {
    final _caravanWidthController = TextEditingController();
    final _caravanLengthController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Dimensions Trailer Leveler'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Caravan Width'),
                TextField(
                  keyboardType: TextInputType.number,
                  controller: _caravanWidthController,
                  decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter width in meters'),
                ),
                Text('Caravan Length'),
                TextField(
                  keyboardType: TextInputType.number,
                  controller: _caravanLengthController,
                  decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter width in meters'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                try {
                  _caravanWidth = double.parse(_caravanWidthController.text);
                  _caravanLength = double.parse(_caravanLengthController.text);
                } catch (e) {
                  return;
                }

                _caravanWidthController.dispose();
                _caravanLengthController.dispose();

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
