import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

/// VoiceHelper - tiện ích nhận diện giọng nói, dùng lại ở mọi page
class VoiceHelper {
  // Singleton cho speech instance
  static final SpeechToText _speech = SpeechToText();
  static bool _isInitialized = false;
  static bool get isListening => _speech.isListening;
  static String _lastLocaleId = 'vi_VN'; // Mặc định tiếng Việt

  /// Khởi tạo, kiểm tra quyền micro, trả về true nếu dùng được
  static Future<bool> init() async {
    if (_isInitialized) return true;
    bool available = await _speech.initialize(
      onStatus: (status) {
        // print('VoiceHelper status: $status');
      },
      onError: (error) {
        // print('VoiceHelper error: $error');
      },
    );
    _isInitialized = available;
    return available;
  }

  /// Lấy danh sách locale hỗ trợ (dùng để show user chọn ngôn ngữ nếu muốn)
  static Future<List<LocaleName>> getSupportedLocales() async {
    await init();
    return await _speech.locales();
  }

  /// Bắt đầu lắng nghe. Có thể truyền locale (default tiếng Việt).
  /// onResult nhận text nhận diện được.
  static Future<void> listen({
    String localeId = 'vi_VN',
    required void Function(String text) onResult,
  }) async {
    await init();
    _lastLocaleId = localeId;
    await _speech.listen(
      localeId: localeId,
      onResult: (SpeechRecognitionResult result) {
        onResult(result.recognizedWords);
      },
      // ignore: deprecated_member_use
      listenMode: ListenMode.confirmation,
    );
  }

  /// Stop lắng nghe
  static Future<void> stop() async {
    if (_speech.isListening) await _speech.stop();
  }

  /// Cancel lắng nghe (không trả về kết quả)
  static Future<void> cancel() async {
    if (_speech.isListening) await _speech.cancel();
  }

  /// Kiểm tra đang lắng nghe không
  static bool get isRecognizing => _speech.isListening;

  /// Lấy localeId cuối cùng đã dùng
  static String get lastLocaleId => _lastLocaleId;
}
