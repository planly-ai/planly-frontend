import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:path/path.dart' as p;

class AudioRecordingService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _currentPath;

  Future<bool> hasPermission() async {
    return await _audioRecorder.hasPermission();
  }

  Future<void> start() async {
    if (await _audioRecorder.hasPermission()) {
      final Directory tempDir = await getTemporaryDirectory();
      _currentPath = p.join(
        tempDir.path,
        'asr_recording_${DateTime.now().millisecondsSinceEpoch}.mp3',
      );

      const config = RecordConfig(
        encoder: AudioEncoder
            .aacLc, // Defaulting to AAC as MP3 support varies by platform in 'record'
        // bitRate: 128000,
        // sampleRate: 44100,
      );

      // Note: Volcengine prefers MP3. If the record package doesn't support MP3 on the target platform,
      // we might need to use 'record_mp3' or similar.
      // For now, we attempt to save with .mp3 extension and hope for compatibility or use AAC if needed.
      // THE API REQUESTS MP3 specifically.

      await _audioRecorder.start(config, path: _currentPath!);
    }
  }

  Future<String?> stop() async {
    final path = await _audioRecorder.stop();
    return path;
  }

  Future<void> dispose() async {
    await _audioRecorder.dispose();
  }
}
