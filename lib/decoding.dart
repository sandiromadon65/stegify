import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_steganography/decoder.dart';
import 'package:flutter_steganography/requests/decode_request.dart';
import 'package:flutter_steganography/requests/encode_request.dart';
import 'package:image_picker/image_picker.dart';

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
  String path = '';
  Uint8List images;
  String text = 'Empty';
  Future getImage() async {
    final pickedFile = await FilePicker.platform.pickFiles();
    if (pickedFile != null) {
      setState(() {
        isLoading = true;
      });
      File _image = File(pickedFile.files.single.path);
      path = _image.path;
      images = _image.readAsBytesSync();
      setState(() {
        isLoading = false;
      });
    } else {
      print('No image selected.');
    }
  }

  FirebaseFirestore firestore = FirebaseFirestore.instance;

  //get data from firebase firestore as stream
  Stream<QuerySnapshot> get dataStream {
    return firestore.collection('image').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: Text('Decode'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          path.isEmpty
              ? Container()
              : Container(
                  height: height * 0.4,
                  width: width * 0.8,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: FileImage(File(path)),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
          Text(
            'Password:',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextField(
            controller: mypassword,
            obscureText: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Password',
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          ElevatedButton(
              onPressed: () {
                decodeImage();
              },
              child: Text('Decode')),
          const SizedBox(
            height: 10,
          ),
          Text(
            'Decoded Text: $text',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          getImage();
        },
        child: Icon(Icons.photo_library),
      ),
    );
  }

  decodeImage() async {
    File files = File(path);
    DecodeRequest request =
        DecodeRequest(files.readAsBytesSync(), key: mypassword.text);
    text = await decodeMessageFromImageAsync(request);
    print(text);
    setState(() {
      isLoading = false;
    });
  }
}
//  return StreamBuilder<QuerySnapshot>(
//         stream: dataStream,
//         builder: ((context, snapshot) {
//           if (snapshot.hasData) {
//             return Scaffold(
//               appBar: AppBar(
//                 title: Text('Decode Result'),
//               ),
//               body: ListView.builder(
//                   itemCount: snapshot.data.docs.length,
//                   itemBuilder: (context, index) {
//                     var data = snapshot.data.docs[index].data();
//                     return InkWell(
//                       onTap: () {
//                         Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                                 builder: (context) => DecodeScreen(
//                                       imageUrl: data['url'],
//                                     )));
//                       },
//                       child: Container(
//                           margin: EdgeInsets.all(10),
//                           height: height * 0.2,
//                           width: width * 0.8,
//                           decoration: BoxDecoration(
//                               image: DecorationImage(
//                             image: NetworkImage(data['url']),
//                           ))),
//                     );
//                   }),
//             );
//           } else {
//             return Scaffold(
//               appBar: AppBar(
//                 title: Text('Decode Result'),
//               ),
//               body: Center(
//                 child: CircularProgressIndicator(),
//               ),
//             );
//           }
//         }));