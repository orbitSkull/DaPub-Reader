class PiperVoice {
  final String key;
  final String name;
  final String language;
  final String country;
  final String quality;
  final String onnxPath;
  final String configPath;

  PiperVoice({
    required this.key,
    required this.name,
    required this.language,
    required this.country,
    required this.quality,
    required this.onnxPath,
    required this.configPath,
  });

  factory PiperVoice.fromJson(String key, Map<String, dynamic> json) {
    // Extract name and quality from the key or nested structure if available
    // For now, let's use the key and structure as seen in voices.json
    final name = json['name'] ?? key.split('-').skip(1).first;
    final language = json['language']?['code'] ?? key.split('_').first;
    final country = json['language']?['country'] ?? '';
    final quality = json['quality'] ?? '';
    
    // Relative paths from voices.json
    final files = json['files'] as Map<String, dynamic>;
    String? onnx;
    String? config;
    
    files.forEach((path, info) {
      if (path.endsWith('.onnx')) {
        onnx = path;
      } else if (path.endsWith('.onnx.json')) {
        config = path;
      }
    });

    return PiperVoice(
      key: key,
      name: name,
      language: language,
      country: country,
      quality: quality,
      onnxPath: onnx ?? '',
      configPath: config ?? '',
    );
  }

  String get modelUrl => 'https://huggingface.co/rhasspy/piper-voices/resolve/main/$onnxPath';
  String get configUrl => 'https://huggingface.co/rhasspy/piper-voices/resolve/main/$configPath';
  
  String get modelPrefKey => "piper_voice_custom_${key}_model";
  String get configPrefKey => "piper_voice_custom_${key}_config";

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PiperVoice && runtimeType == other.runtimeType && key == other.key;

  @override
  int get hashCode => key.hashCode;
}
