import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';

loadModel() async {
  await Tflite.LoadModel(
     model: "assets/mobilenet_v1_1.0_224.tflite";
     labels: "assets/mobilenet_v1_1.0_224.txt"
  );
}


// inside initCamera() below imgCamera

runModelOnStreamFrames(),


runModelOnStreamFrames() async{
   if(imgCamera !- null)
   {
    var recognitions = await Tflite.runModelOnFrame(
      bytesList: imgCamera.planes.map((plane)
      {
        return plane.bytes;
      }).toList(),

      imageHeight: imgCamera.height,
      imageWidth: imgCamera.width,
      imageMean: 127.5,
      imageStd: 127.5,
      rotation: 90,
      numResults: 2,
      threshold: 0.1,
      asynch: true,
    ); 
    result="";

    recognitions.forEach((response)
    {
      result += response["label"] + "  " + (response["confidence"] as double), toStringAsFixed(2) + "\n\n";
      
    });

    setSate((){
      result;
    });

    isWorking = false;
   }
}



 
void initState(){
  super.initState();

  loadModel(); 
} 

void dispose() async
{
  super.dispose();

  await Tflite.close();
  cameraController.dispose();
}

 

 //widget..after stack(;;;),

 Center(
  child: Container(
    margin: EdgeInserts.only(top:55.0),
    child: SingleChildScrollView(
    child: Text(
      result,
      style: TextStyle(
        backgroundColor: Colors.black87,
        fontSize: 30.0,
        color: Colors.white,
      ),
      textAlign: TextAlign.center,
      ),
    ),  
    ),
 ),