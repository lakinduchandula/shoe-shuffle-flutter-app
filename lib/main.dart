// ignore_for_file: avoid_print, depend_on_referenced_packages

import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? imageFile;
  String? _textData;

  Future sendImageToServer() async {
    print('Sending Image to Server... ============');

    var url = 'http://ec2-100-25-202-77.compute-1.amazonaws.com/image';
    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.files
        .add(await http.MultipartFile.fromPath('img', imageFile!.path));
    var response = await request.send();

    print('Response status: ${response.statusCode}');

    response.stream.transform(utf8.decoder).listen((value) {
      setState(() {
        _textData = value;
      });
    });
  }

  Future pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        imageQuality: 50,
      );
      if (pickedFile == null) return;

      var imageTemp = File(pickedFile.path);
      imageTemp = await compressImage(imageTemp.path, 50);

      try {
        await sendImageToServer();
      } catch (e) {
        print(e);
      }

      print('==== Done Uploading and Getting Prediction ====');

      setState(() {
        imageFile = imageTemp;
      });
    } on PlatformException catch (e) {
      print('Failed to pick image: $e');
    }
  }

  Future<File> compressImage(String path, int quality) async {
    final newPath = p.join((await getTemporaryDirectory()).path,
        '${DateTime.now()}.${p.extension(path)}');

    final result = await FlutterImageCompress.compressAndGetFile(path, newPath,
        quality: quality);

    return result!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      backgroundColor: Colors.blue[300],
      body: Column(
        children: [
          const Spacer(),
          imageFile == null
              ? const Text(
                  'No Image Selected',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : Image.file(
                  imageFile!,
                  width: 160,
                  height: 160,
                  fit: BoxFit.cover,
                ),
          _textData == null ? Container() : Text(_textData!),
          const Spacer(),
          Container(
            alignment: Alignment.center,
            child: const Text(
              'Image Upload and Get Prediction',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: buildButton(
              title: 'Pick Gallery Image',
              icon: Icons.image_outlined,
              onClicked: () => pickImage(ImageSource.gallery),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: buildButton(
              title: 'Pick Camera Image',
              icon: Icons.camera_alt_outlined,
              onClicked: () => pickImage(ImageSource.camera),
            ),
          ),
          const Spacer()
        ],
      ),
    );
  }
}

Widget buildButton({
  required String title,
  required IconData icon,
  required VoidCallback onClicked,
}) {
  return ElevatedButton(
    onPressed: onClicked,
    style: ElevatedButton.styleFrom(
      minimumSize: const Size.fromHeight(56),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      textStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    child: Row(
      children: [
        Icon(icon),
        const SizedBox(width: 16),
        Text(title),
      ],
    ),
  );
}
