import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite/tflite.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sign Language App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(title: 'Sign Language App'),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late CameraController _controller;
  late List<CameraDescription> _cameras;
  bool _isModelLoaded = false;
  String _recognizedSign = '';

  @override
  void initState() {
    super.initState();

    _initCamera();
    _loadModel();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future _initCamera() async {
    _cameras = await availableCameras();
    _controller = CameraController(_cameras[0], ResolutionPreset.medium);
    _controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  Future _loadModel() async {
    await Tflite.loadModel(
      model: 'assets/model.tflite',
      labels: 'assets/labels.txt',
    ).then((value) {
      setState(() {
        _isModelLoaded = true;
      });
    });
  }

  Future _recognizeSign() async {
    if (_isModelLoaded) {
      var recognitions = await Tflite.runModelOnImage(
        path: _controller.value.isTakingPicture!,
        imageMean: 127.5,
        imageStd: 127.5,
        numResults: 1,
        threshold: 0.5,
      );

      setState(() {
        _recognizedSign = recognitions![0]['label'] as String;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _controller.value.isInitialized
          ? Stack(
              children: [
                CameraPreview(_controller),
                Center(
                  child: Text(
                    _recognizedSign,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24.0,
                    ),
                  ),
                ),
              ],
            )
          : Center(
              child: CircularProgressIndicator(),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _recognizeSign,
        tooltip: 'Recognize Sign',
        child: Icon(Icons.camera),
      ),
    );
  }
}