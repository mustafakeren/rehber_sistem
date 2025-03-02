import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ImageCapture extends StatefulWidget{
  const ImageCapture({super.key});

  @override
  State<ImageCapture> createState() {
    return _ImageCaptureState();
  }
}

  class _ImageCaptureState extends State<ImageCapture>{
    File? _takenImage;

    void _takePicture() async{
      final imagePicker = ImagePicker();
      final pickedImage = await imagePicker.pickImage(source: ImageSource.camera, maxWidth: 600);

      if(pickedImage == null){
        return;
      }
      setState(() {
        _takenImage = File(pickedImage.path);
      });
    }


    @override
    Widget build(BuildContext context){
      Widget content = TextButton.icon(
        icon: const Icon(Icons.camera),
        label: const Text('Capture Image'),
        onPressed: _takePicture,
      );

      if(_takenImage != null){
        content = Image.file(
          _takenImage!,
          fit: BoxFit.cover,
          width: double.infinity,
        );
      }
      return Container(
        height: 250,
        width: double.infinity,
        alignment: Alignment.center,
        child: content,
      );
    }
  }
