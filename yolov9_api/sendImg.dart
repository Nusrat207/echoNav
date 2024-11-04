import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<void> detectObjects(File imageFile) async {
  final request = http.MultipartRequest(
      'POST', Uri.parse('http://<server_ip>:8000/detect'));
  request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

  final response = await request.send();

  if (response.statusCode == 200) {
    final respStr = await response.stream.bytesToString();
    final detections = jsonDecode(respStr) as List;

    for (var detection in detections) {
      print(
          "Label: ${detection['label']}, Confidence: ${detection['confidence']}, Box: ${detection['box']}");
    }
  } else {
    print("Failed to detect objects. Status code: ${response.statusCode}");
  }
}




//FLUTTER CALLING FUNCTION
/*
void onDetectButtonPressed(File imageFile) async {
  await detectObjects(imageFile);
}
*/

//DEPENDENCIES
/*
dependencies:
  http: ^0.13.3
*/

//BASH   uvicorn main:app --host 0.0.0.0 --port 8000
