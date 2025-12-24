import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ScanBillService {
  Future<dynamic> scanBill(XFile image) async {
    var request = http.MultipartRequest(
      "POST",
      Uri.parse("http://3.108.110.151:5001/scan-bill"),
    );

    request.files.add(
      await http.MultipartFile.fromPath("image", image.path),
    );

    var response = await request.send();
    var body = await response.stream.bytesToString();

    print("📌 RAW API RESPONSE:");
    print(body);

    if (response.statusCode == 200) {
      return jsonDecode(body);
    } else {
      throw Exception("Scan failed: ${response.statusCode} → $body");
    }
  }
}
