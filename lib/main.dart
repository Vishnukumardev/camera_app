import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:test_app/src/Homescreen.dart';

List<CameraDescription> cameras = [];

void main() {
  // Fetch the available cameras before initializing the app.
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
