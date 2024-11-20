import 'package:async_redux/async_redux.dart';
import 'package:flutter/services.dart';
import 'package:scenario_management_tool_for_testers/Services/http_post.dart';
import 'package:scenario_management_tool_for_testers/Services/response.dart';
import 'package:scenario_management_tool_for_testers/Services/data_services.dart';
import 'package:scenario_management_tool_for_testers/appstate.dart';

class UploadImageAction extends ReduxAction<AppState> {
  DataService dataService = locator();
  final Uint8List fileBytes;
  final String fileName;

  UploadImageAction(this.fileBytes, this.fileName);

  @override
  Future<AppState> reduce() async {
    if (fileBytes.isEmpty || fileName.isEmpty) {
      throw UserException("Invalid file or file name.");
    }
    DataResponse responseApi =
        (await dataService.uploadFile(fileBytes, fileName)) as DataResponse;

    if (responseApi.err != null) {
      throw UserException("Upload failed: ${responseApi.err}");
    }
    return state.copy(response: responseApi);
  }
}
