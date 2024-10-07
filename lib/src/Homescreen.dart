import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'Camerascreen.dart';
import 'Galleryscreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final status = await [
      Permission.camera,
      Permission.photos,
      Permission.videos,
    ].request();

    if (status[Permission.camera]!.isGranted &&
        status[Permission.photos]!.isGranted &&
        status[Permission.videos]!.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permissions granted!')),
      );
    } else {
      _showPermissionDeniedDialog();
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permissions Denied'),
          content:
              const Text('This app requires camera and storage permissions.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                exit(0); // Exit the app
              },
              child: const Text('Exit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Home'),
      ),
      body: Center(
        child: Column(
          children: [
            GestureDetector(
              onTap: () async {
                if (await Permission.camera.isGranted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CameraScreen()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Camera permission required!')),
                  );
                }
              },
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(20)),
                      height: 350,
                      width: MediaQuery.of(context).size.width,
                      child: Center(
                        child: Icon(
                          Icons.add_a_photo_rounded,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 5.0,
                  ),
                  const Text('Click here to take a picture'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (await Permission.photos.isGranted ||
                    await Permission.videos.isGranted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const GalleryScreen()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Storage permission required!')),
                  );
                }
              },
              child: const Text('Go to Gallery'),
            ),
          ],
        ),
      ),
    );
  }
}
