
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:provider/provider.dart';

import 'screens/homescreen.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  // @override
  // void initState() {
  //   //set initial Orientation to landscape
  //   SystemChrome.setPreferredOrientations([
  //     DeviceOrientation.landscapeLeft,
  //     DeviceOrientation.landscapeRight,
  //   ]);
  //   super.initState();
  // }
  @override
  Widget build(BuildContext context) {
    return StreamProvider<InternetConnectionStatus>(
      initialData: InternetConnectionStatus.connected,
      create: (_){
        return InternetConnectionChecker().onStatusChange;
      },
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Rental Empire',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: Colors.blue[600],
        ),
        home: const HomePage(title: 'Rental Empire'),
      ),
    );
  }
}