import 'package:flutter/services.dart';
import 'package:http/http.dart';

abstract class DataService {
  Future<Response> uploadFile(Uint8List? fileBytes, String? fileName);
}
