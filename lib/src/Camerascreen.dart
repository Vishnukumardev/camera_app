import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:photo_manager/photo_manager.dart';
import 'package:test_app/src/Galleryscreen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  List<CameraDescription>? _cameras;
  CameraController? _cameraController;
  int _selectedCameraIndex = 0;
  XFile? _lastCapturedImage;
  File? _recentImage;
  double _zoomLevel = 1.0;
  late double _maxZoomLevel;

  @override
  void initState() {
    super.initState();
    _initializeCameras();
    _fetchRecentImage();
  }

  Future<void> _initializeCameras() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _cameraController = CameraController(
        _cameras![_selectedCameraIndex],
        ResolutionPreset.high,
      );
      await _cameraController!.initialize();
      _maxZoomLevel = await _cameraController!.getMaxZoomLevel();
      if (!mounted) return;
      setState(() {});
    }
  }

  Future<void> _fetchRecentImage() async {
    final PermissionState permission =
        await PhotoManager.requestPermissionExtend();

    if (permission != PermissionState.authorized) {
      print('Permission not granted');
      return;
    }

    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
    );

    if (paths.isNotEmpty) {
      final List<AssetEntity> recentImages =
          await paths.first.getAssetListPaged(
        page: 0,
        size: 1,
      );

      if (recentImages.isNotEmpty) {
        final AssetEntity asset = recentImages.first;
        final File? file = await asset.file;

        if (file != null) {
          setState(() {
            _recentImage = file;
          });
        } else {
          print('No file found for the recent image asset.');
        }
      } else {
        print('No recent images found in the asset path.');
      }
    } else {
      print('No asset paths available.');
    }
  }

  Future<void> _captureImage() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        XFile image = await _cameraController!.takePicture();
        await _saveImageToGallery(File(image.path));

        setState(() {
          _lastCapturedImage = image;
          _recentImage = File(image.path);
        });
      } catch (e) {
        print("Error capturing image: $e");
      }
    }
  }

  Future<void> _saveImageToGallery(File imageFile) async {
    try {
      final PermissionState permission =
          await PhotoManager.requestPermissionExtend();
      if (permission == PermissionState.authorized) {
        String filename = path.basename(imageFile.path);

        await PhotoManager.editor.saveImage(
          imageFile.readAsBytesSync(),
          title: filename,
          filename: filename,
        );
        print("Image saved to gallery.");
      } else {
        print('Permission not granted to access the gallery.');
      }
    } catch (e) {
      print("Error saving image to gallery: $e");
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController!.value.flashMode == FlashMode.off) {
      await _cameraController!.setFlashMode(FlashMode.torch);
    } else {
      await _cameraController!.setFlashMode(FlashMode.off);
    }
    setState(() {});
  }

  void _setZoom(double zoom) {
    setState(() {
      _zoomLevel = zoom;
      _cameraController?.setZoomLevel(_zoomLevel);
    });
  }

  void _swapCamera() {
    setState(() {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
      _initializeCameras();
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _cameraController == null || !_cameraController!.value.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Positioned.fill(
                  child: CameraPreview(_cameraController!),
                ),
                Positioned(
                  bottom: 40,
                  left: 20,
                  child: GestureDetector(
                    onTap: () {
                      if (_recentImage != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ImageViewerScreen(
                              imageFile: _recentImage!,
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      width: 65,
                      height: 65,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                        shape: BoxShape.circle,
                        image: _recentImage != null
                            ? DecorationImage(
                                image: FileImage(_recentImage!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 40,
                  left: 20,
                  right: 20,
                  child: GestureDetector(
                    onTap: _captureImage,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 80,
                  right: 20,
                  child: RotatedBox(
                    quarterTurns: 135,
                    child: Slider(
                      value: _zoomLevel,
                      min: 1.0,
                      max: _maxZoomLevel,
                      onChanged: _setZoom,
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  left: 20,
                  child: IconButton(
                    icon: Icon(
                      _cameraController?.value.flashMode == FlashMode.torch
                          ? Icons.flash_on
                          : Icons.flash_off,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: _toggleFlash,
                  ),
                ),
                Positioned(
                  bottom: 40,
                  right: 20,
                  child: IconButton(
                    icon: const Icon(
                      Icons.cameraswitch,
                      color: Colors.white,
                      size: 50,
                    ),
                    onPressed: _swapCamera,
                  ),
                ),
              ],
            ),
    );
  }
}

class ImageViewerScreen extends StatelessWidget {
  final File imageFile;

  const ImageViewerScreen({Key? key, required this.imageFile})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
         backgroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const GalleryScreen()),
                );
              },
              child: Icon(Icons.image),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Image.file(imageFile),
        ),
      ),
    );
  }
}
