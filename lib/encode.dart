import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:stegify_mobile/loading_states.dart';
import 'package:flutter_steganography/decoder.dart';
import 'package:flutter_steganography/encoder.dart';
import 'package:flutter_steganography/requests/requests.dart';

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
    imageData = await encodeMessageIntoImageAsync(request);
    dynamic response =
        await ImageGallerySaver.saveImage(imageData, quality: 100);
    if (response.toString().toLowerCase().contains('not found')) {
      throw FlutterError('save_image_to_gallert_failed');
    }
    setState(() {
      saveLoading = false;
    });
  }

  Uint8List image;
  final picker = ImagePicker();
  bool isLoading = false;
  File path = File('');
  TextEditingController mymessage = TextEditingController();
  TextEditingController mypassword = TextEditingController();
  Future getImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.camera);
    if (pickedFile != null) {
      File _image = File(pickedFile.path);
      path = _image;
      image = _image.readAsBytesSync();
      setState(() {
        isLoading = true;
      });
    } else {
      print('No image selected.');
    }
  }

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
                  child: isLoading == false
                      ? Column(
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
                        )
                      : ElevatedButton(
                          onPressed: () {
                            saveImage(image);
                          },
                          child: Text('Save Image')),
                )
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
