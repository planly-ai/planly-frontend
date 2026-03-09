import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Api doc: https://www.volcengine.com/docs/6561/1631584?lang=zh
class AsrService {
  final String _apiUrl =
      'https://openspeech.bytedance.com/api/v3/auc/bigmodel/recognize/flash';

  final String _appId = dotenv.env['VOLCENGINE_APP_ID'] ?? '';
  final String _accessToken = dotenv.env['VOLCENGINE_ACCESS_TOKEN'] ?? '';

  final Dio _dio = Dio();
  final Uuid _uuid = const Uuid();

  Future<String?> recognize(String filePath) async {
    try {
      final File audioFile = File(filePath);
      if (!await audioFile.exists()) {
        print('Audio file not found: $filePath');
        return null;
      }

      final List<int> audioBytes = await audioFile.readAsBytes();
      final String base64Audio = base64Encode(audioBytes);

      final Map<String, dynamic> body = {
        "user": {"uid": _appId},
        "audio": {"data": base64Audio},
        "request": {"model_name": "bigmodel"},
      };

      final Map<String, String> headers = {
        'X-Api-App-Key': _appId,
        'X-Api-Access-Key': _accessToken,
        'X-Api-Resource-Id': 'volc.bigasr.auc_turbo',
        'X-Api-Request-Id': _uuid.v4(),
        'X-Api-Sequence': '-1',
        'Content-Type': 'application/json',
      };

      final response = await _dio.post(
        _apiUrl,
        data: body,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['result'] != null && data['result']['text'] != null) {
          return data['result']['text'];
        }
      }

      print('ASR Error: ${response.statusCode} - ${response.data}');
      return null;
    } catch (e) {
      print('ASR Exception: $e');
      return null;
    }
  }
}
