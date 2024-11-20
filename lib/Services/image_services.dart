import 'dart:convert';
import 'package:mime/mime.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:scenario_management_tool_for_testers/Services/data_services.dart';
import 'package:scenario_management_tool_for_testers/Services/response.dart'; // For MediaType

class Services extends DataService {
  final fileUploadUrl = "https://dev.orderbookings.com/api/image-test-upload";
  // @override
  // Future<Response> uploadFile(Uint8List? fileBytes, String? fileName) {
  //   return performHTTPPOST(fileUploadUrl,
  //       fileBytes: fileBytes, fileName: fileName);
  // }

  Future<DataResponse> performHTTPGET(String url) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return DataResponse(data: jsonDecode(response.body), err: "");
      } else {
        return DataResponse(
            data: null, err: 'Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      return DataResponse(data: null, err: 'Failed to load data: $e');
    }
  }

  Future<DataResponse> performHTTPPOST(
    String url, {
    dynamic data,
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    try {
      http.Response response;
      if (fileBytes != null && fileName != null) {
        String? mimeType = lookupMimeType(fileName);
        print("MIME type: $mimeType");
        if (mimeType == null) {
          return DataResponse(
            data: null,
            err: 'Could not determine file MIME type',
          );
        }
        var mediaType = mimeType.split('/');

        var request = http.MultipartRequest('POST', Uri.parse(url));
        request.files.add(http.MultipartFile.fromBytes(
          'image', // Ensure the backend expects this key
          fileBytes,
          filename: fileName,
          contentType: MediaType(mediaType[0], mediaType[1]),
        ));

        if (data != null) {
          data.forEach((key, value) {
            request.fields[key] = value.toString();
          });
        }

        print("Sending request to $url with fields: ${request.fields}");
        print("File size: ${fileBytes.length} bytes");

        var streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);

        print("Response status code: ${response.statusCode}");
        print("Response body: ${response.body}");
      } else {
        response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(data),
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return DataResponse(data: jsonDecode(response.body), err: "");
      } else {
        return DataResponse(
            data: null, err: 'Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      print("Error in performHTTPPOST: $e");
      return DataResponse(data: null, err: 'Failed to upload image: $e');
    }
  }

  // Future<DataResponse> performHTTPPOST(
  //   String url, {
  //   dynamic data,
  //   Uint8List? fileBytes,
  //   String? fileName,
  // }) async {
  //   try {
  //     http.Response response;
  //     if (fileBytes != null && fileName != null) {
  //       String? mimeType = lookupMimeType(
  //           fileName); // Lookup the MIME type based on the file extension
  //       if (mimeType == null) {
  //         return DataResponse(
  //           data: null,
  //           err: 'Could not determine file MIME type',
  //         );
  //       }
  //       var mediaType = mimeType.split('/');

  //       var request = http.MultipartRequest('POST', Uri.parse(url));
  //       request.files.add(http.MultipartFile.fromBytes(
  //         'image', // The key name for the file in the API (matches your cURL example)
  //         fileBytes,
  //         filename: fileName,
  //         contentType: MediaType(mediaType[0], mediaType[1]),
  //       ));

  //       if (data != null) {
  //         data.forEach((key, value) {
  //           request.fields[key] = value.toString();
  //         });
  //       }

  //       var streamedResponse = await request.send();
  //       response = await http.Response.fromStream(streamedResponse);
  //     } else {
  //       response = await http.post(
  //         Uri.parse(url),
  //         headers: {'Content-Type': 'application/json'},
  //         body: jsonEncode(data),
  //       );
  //     }

  //     if (response.statusCode == 200 || response.statusCode == 201) {
  //       return DataResponse(data: jsonDecode(response.body), err: "");
  //     } else {
  //       return DataResponse(
  //           data: null, err: 'Failed to upload image: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     return DataResponse(data: null, err: 'Failed to upload image: $e');
  //   }
  // }

  Future<DataResponse> performHTTPPUT(
      String url, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      print("Updated ${response.statusCode}");
      if (response.statusCode == 200) {
        return DataResponse(data: jsonDecode(response.body), err: "");
      } else {
        return DataResponse(
            data: null, err: 'Failed to update data: ${response.statusCode}');
      }
    } catch (e) {
      return DataResponse(data: null, err: 'Failed to update data: $e');
    }
  }

  Future<DataResponse> performHTTPDELETE(String url) async {
    try {
      final response = await http.delete(Uri.parse(url));

      if (response.statusCode == 200) {
        print('Deleted ${response.statusCode}');
        return DataResponse(data: jsonDecode(response.body), err: "");
      } else {
        return DataResponse(
            data: null, err: 'Failed to delete data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete data: $e');
    }
  }

  @override
  Future<http.Response> uploadFile(
      Uint8List? fileBytes, String? fileName) async {
    final result = await performHTTPPOST(
      fileUploadUrl,
      fileBytes: fileBytes,
      fileName: fileName,
    );
    if (result.data != null) {
      // Convert the response to an HTTP Response object if needed
      return http.Response(jsonEncode(result.data), 200);
    } else {
      return http.Response(jsonEncode({'error': result.err}), 400);
    }
  }
}
