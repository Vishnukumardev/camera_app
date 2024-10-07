import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_view/photo_view.dart';
import 'package:test_app/src/Camerascreen.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({Key? key}) : super(key: key);

  @override
  _GalleryScreenState createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<AssetEntity> _mediaList = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchImagesFromStorage();
  }

  Future<void> _fetchImagesFromStorage() async {
    final PermissionState result = await PhotoManager.requestPermissionExtend();
    if (result.isAuth) {
      List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
      );
      List<AssetEntity> media = await albums[0].getAssetListPaged(
        page: 0,
        size: 100,
      );

      setState(() {
        _mediaList = media;
      });
    } else {
      PhotoManager.openSetting();
    }
  }

  void _openImageViewer(BuildContext context, File imageFile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageViewerScreen(imageFile: imageFile),
      ),
    );
  }

  Future<void> _pickImageFromStorage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final File imageFile = File(image.path);
      _openImageViewer(context, imageFile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Gallery'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CameraScreen()),
                );
              },
              child: Icon(Icons.camera),
            ),
          )
        ],
      ),
      body: _mediaList.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4.0,
                mainAxisSpacing: 4.0,
              ),
              itemCount: _mediaList.length + 1, // Add one for the picker
              itemBuilder: (context, index) {
                if (index == 0) {
                  // First grid item to pick an image
                  return GestureDetector(
                    onTap: _pickImageFromStorage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        border: Border.all(color: Colors.grey),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.add_a_photo_rounded,
                          size: 40,
                        ),
                      ),
                    ),
                  );
                } else {
                  return FutureBuilder<File?>(
                    future: _mediaList[index - 1].file,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done &&
                          snapshot.hasData) {
                        return GestureDetector(
                          onTap: () =>
                              _openImageViewer(context, snapshot.data!),
                          child: Image.file(
                            snapshot.data!,
                            fit: BoxFit.cover,
                          ),
                        );
                      } else {
                        return const Center(child: CircularProgressIndicator());
                      }
                    },
                  );
                }
              },
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
                  MaterialPageRoute(builder: (context) => const CameraScreen()),
                );
              },
              child: Icon(Icons.camera),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: PhotoView(
            backgroundDecoration: BoxDecoration(color: Colors.white),
            imageProvider: FileImage(imageFile),
          ),
        ),
      ),
    );
  }
}
