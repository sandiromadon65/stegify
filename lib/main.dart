import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_steganography/decoder.dart';
import 'package:flutter_steganography/encoder.dart';
import 'package:flutter_steganography/requests/requests.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:stegify_mobile/decoding.dart';
import 'package:stegify_mobile/encode.dart';
import 'package:stegify_mobile/loading_states.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  LoadingState savingState;
  TextEditingController mymessage = TextEditingController();
  TextEditingController mypassword = TextEditingController();
  Uint8List image;
  String text = "Example";
  final picker = ImagePicker();
  bool isLoading = false;

  Future getImage() async {
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 100);
    if (pickedFile != null) {
      setState(() {
        isLoading = true;
      });
      File _image = File(pickedFile.path);
      EncodeRequest request = EncodeRequest(
          _image.readAsBytesSync(), mymessage.text,
          key: mypassword.text);
      // for async
      image = await encodeMessageIntoImageAsync(request);
      setState(() {
        isLoading = false;
      });
    } else {
      print('No image selected.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(text),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //2 elevated buttons encoder and decoder
            ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => EncodingResultScreen()));
                },
                child: Text("Encoder")),
            ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => DecodingResultScreen()));
                },
                child: Text("Decoder")),
          ],
        ),
      ),
    );
  }

  Future<void> saveImage(Uint8List imageData) async {
    if (Platform.isAndroid) {
      PermissionStatus status = await Permission.storage.status;
      if (!status.isGranted) {
        if (!await Permission.storage.request().isGranted) {
          print('no storage permission to save image');
          return;
        }
      }
    }
    setState(() {
      this.savingState = LoadingState.LOADING;
    });
    dynamic response =
        await ImageGallerySaver.saveImage(imageData, quality: 100);
    print(response);
    if (response.toString().toLowerCase().contains('not found')) {
      setState(() {
        this.savingState = LoadingState.ERROR;
      });
      throw FlutterError('save_image_to_gallert_failed');
    }
    setState(() {
      this.savingState = LoadingState.SUCCESS;
    });
  }
}
