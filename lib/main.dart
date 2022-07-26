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
  String text = "";
  final picker = ImagePicker();
  bool isLoading = false;

  Future getImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.camera);
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

  bool isLoading2 = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(text),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          SizedBox(
            height: 20,
          ),
          RaisedButton(
            child: Text('Select Image'),
            onPressed: () {
              getImage();
            },
          ),
          SizedBox(
            height: 20,
          ),
          isLoading
              ? CircularProgressIndicator()
              : text.isNotEmpty
                  ? Text(text)
                  : image != null
                      ? Image.memory(image)
                      : Container(),
          SizedBox(
            height: 20,
          ),
          image != null
              ? Column(
                  children: [
                    //decode message from image
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
                          setState(() {
                            isLoading = true;
                          });
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
              : Column(
                  children: [
                    Text(
                      'Message:',
                      style: TextStyle(fontSize: 20),
                    ),
                    TextField(
                      controller: mymessage,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Message',
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Text(
                      'Password:',
                      style: TextStyle(fontSize: 20),
                    ),
                    TextField(
                      controller: mypassword,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Password',
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                  ],
                )
        ],
      ),
      floatingActionButton: text.isNotEmpty
          ? FloatingActionButton(
              onPressed: () {
                isLoading = false;
                image = null;
                text = "";
                mymessage.clear();
                mypassword.clear();
                isLoading2 = false;
                setState(() {});
              },
              child: Icon(Icons.remove_circle),
            )
          : null,
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
