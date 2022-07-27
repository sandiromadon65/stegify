import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:flutter_steganography/decoder.dart';
import 'package:flutter_steganography/encoder.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_steganography/requests/requests.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Encode Result Screen
///
/// {@category Screens}
/// {@category Screens: Encode Result}
class EncodingResultScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _EncodingResultScreen();
  }
}

class _EncodingResultScreen extends State<EncodingResultScreen> {
  bool saveLoading = false;
  FirebaseStorage storage = FirebaseStorage.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  Uint8List encodeImage = Uint8List(0);
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
      saveLoading = true;
    });
    EncodeRequest request =
        EncodeRequest(imageData, mymessage.text, key: mypassword.text);
    Uint8List res = await encodeMessageIntoImageAsync(request);
    encodeImage = res;
    var snapshot = await storage
        .ref()
        .child('images/${DateTime.now().millisecondsSinceEpoch}.png')
        .putData(encodeImage)
        .whenComplete(() => print('Uploaded'));
    var downloadUrl = await snapshot.ref.getDownloadURL();
    CollectionReference images = firestore.collection('image');
    await images.add({
      'url': downloadUrl,
    }).then((value) => print('saved'));
    // print(encodeImage);
    // prefs.setString('encodeImage', jsonEncode(encodeImage));
    // String fileName = path.path.split('/').last;
    // final hasil =
    //     await ImageGallerySaver.saveImage(res, isReturnImagePathOfIOS: true);
    // print(hasil);
    setState(() {
      saveLoading = false;
    });
  }

//globalKey
  GlobalKey<ScaffoldState> globalKey = GlobalKey<ScaffoldState>();
  Future<void> _save() async {
    RenderRepaintBoundary boundary =
        globalKey.currentContext.findRenderObject();
    ui.Image image = await boundary.toImage(pixelRatio: 2.0);
    ByteData byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData.buffer.asUint8List();
    Navigator.pop(context, pngBytes);
  }

  Uint8List image;
  final picker = ImagePicker();
  bool isLoading = false;
  File path = File('');
  TextEditingController mymessage = TextEditingController();
  TextEditingController mypassword = TextEditingController();
  Future getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File _image = File(pickedFile.path);
      path = _image;
      print(path.path);
      image = _image.readAsBytesSync();
      setState(() {
        isLoading = true;
      });
    } else {
      print('No image selected.');
    }
  }

  String text = "";
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: Text('Encode'),
        leading: IconButton(
            key: Key('encoded_screen_back_btn'),
            icon: Icon(Icons.arrow_back_ios),
            onPressed: () {
              Navigator.pop(context);
            }),
      ),
      resizeToAvoidBottomInset: false,
      body: saveLoading == true
          ? Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  width: width * 0.8,
                  height: height * 0.4,
                  alignment: Alignment.center,
                  child: isLoading == false
                      ? Text(
                          'Encoded Image',
                          style: TextStyle(fontSize: 20),
                        )
                      : Image.file(path),
                ),
                Container(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: mymessage,
                      decoration: InputDecoration(
                        labelText: 'Message',
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    TextField(
                      controller: mypassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                      ),
                    ),
                  ],
                )),
                ElevatedButton(
                    onPressed: () {
                      saveImage(image);
                    },
                    child: Text('Save Image')),
                const SizedBox(
                  height: 10,
                ),
                ElevatedButton(
                    onPressed: () async {
                      // File files = File(
                      //     "///storage/emulated/0/Pictures/1658909172315.jpg");
                      // Uint8List bytes = files.readAsBytesSync();
                      DecodeRequest request =
                          DecodeRequest(encodeImage, key: mypassword.text);
                      text = await decodeMessageFromImageAsync(request);
                      print(text);
                      setState(() {});
                    },
                    child: Text('Decode Image')),
                const SizedBox(
                  height: 10,
                ),
                Text(text.isEmpty ? 'No message found' : text),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: getImage,
        tooltip: 'Pick Image',
        child: Icon(Icons.add_a_photo),
      ),
    );
  }
}
