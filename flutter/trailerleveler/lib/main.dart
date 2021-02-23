import 'package:flutter/material.dart';

import 'package:trailerleveler/angles_page.dart';
import 'package:trailerleveler/bluetooth_bloc.dart';

import 'package:wakelock/wakelock.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // To keep the screen on:
    Wakelock.enable();
    return MaterialApp(home: AnglesPage());
  }
}
