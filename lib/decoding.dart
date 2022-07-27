import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_steganography/decoder.dart';
import 'package:flutter_steganography/requests/decode_request.dart';
import 'package:flutter_steganography/requests/encode_request.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Decode Result Screen
///
/// {@category Screens}
/// {@category Screens: Decode Result}
class DecodingResultScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _DecodingResultScreen();
  }
}

class _DecodingResultScreen extends State<DecodingResultScreen> {
  final picker = ImagePicker();
  TextEditingController mypassword = TextEditingController();
  bool isLoading = false;
  Uint8List images;
  String text = 'Empty';
  Future getImage() async {
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
    if (pickedFile != null) {
      setState(() {
        isLoading = true;
      });
      File _image = File(pickedFile.path);
      images = _image.readAsBytesSync();
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
        title: Text("Decoding Image"),
        leading: IconButton(
            key: Key('decoded_screen_back_btn'),
            icon: Icon(Icons.arrow_back_ios),
            onPressed: () {
              Navigator.pop(context);
            }),
      ),
      resizeToAvoidBottomInset: false,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            child: isLoading == false
                ? Column(
                    children: [
                      Text(
                        'Decoded Text',
                        style: TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: mypassword,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      ElevatedButton(
                          onPressed: () async {
                            SharedPreferences prefs =
                                await SharedPreferences.getInstance();
                            var data = prefs.getString('encodeImage');
                            var decode = jsonDecode(data);
                            Uint8List image = decode;
                            DecodeRequest request =
                                DecodeRequest(image, key: mypassword.text);
                            text = await decodeMessageFromImageAsync(request);
                            print(text);
                            setState(() {
                              isLoading = false;
                            });
                          },
                          child: Text('Decoded Message')),
                    ],
                  )
                : Center(
                    child: CircularProgressIndicator(),
                  ),
          ),
          Text(text),
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
