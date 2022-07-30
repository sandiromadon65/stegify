import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_steganography/decoder.dart';
import 'package:flutter_steganography/requests/decode_request.dart';

class DecodeScreen extends StatefulWidget {
  final String imageUrl;
  const DecodeScreen({Key key, this.imageUrl}) : super(key: key);

  @override
  State<DecodeScreen> createState() => _DecodeScreenState();
}

class _DecodeScreenState extends State<DecodeScreen> {
  TextEditingController mypassword = TextEditingController();
  bool isLoading = false;
  String text = 'Empty';
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: Text('Decode'),
        leading: IconButton(
            key: Key('decoded_screen_back_btn'),
            icon: Icon(Icons.arrow_back_ios),
            onPressed: () {
              Navigator.pop(context);
            }),
      ),
      resizeToAvoidBottomInset: false,
      body: isLoading == true
          ? Center(
              child: CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  width: width * 0.8,
                  height: height * 0.4,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(widget.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                TextField(
                  controller: mypassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                  ),
                ),
                ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        isLoading = true;
                      });
                      Uint8List bytes =
                          (await NetworkAssetBundle(Uri.parse(widget.imageUrl))
                                  .load(widget.imageUrl))
                              .buffer
                              .asUint8List();
                      DecodeRequest request =
                          DecodeRequest(bytes, key: mypassword.text);
                      text = await decodeMessageFromImageAsync(request);
                      setState(() {
                        isLoading = false;
                      });
                    },
                    child: Text('Decode Image')),
                const SizedBox(
                  height: 10,
                ),
                Text(
                  text ?? 'Result',
                  style: TextStyle(fontSize: 20),
                ),
              ],
            ),
    );
  }
}
