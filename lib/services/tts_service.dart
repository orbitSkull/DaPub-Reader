import 'dart:io';
import 'package:flutter/material.dart';
import 'package:piper_tts_plugin/piper_tts_plugin.dart';
import 'package:piper_tts_plugin/enums/piper_voice_pack.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TtsState { idle, loading, ready, playing, paused, error }

class TtsService extends ChangeNotifier {
  final PiperTtsPlugin _tts = PiperTtsPlugin();
  final AudioPlayer _player = AudioPlayer();
  
  TtsState _state = TtsState.idle;
  String? _currentText;
  double _speechRate = 1.0;
  double _pitch = 1.0;
  PiperVoicePack _selectedVoice = PiperVoicePack.norman;
  String? _errorMessage;
  String? _audioPath;

  TtsState get state => _state;
  double get speechRate => _speechRate;
  double get pitch => _pitch;
  PiperVoicePack get selectedVoice => _selectedVoice;
  bool get isPlaying => _state == TtsState.playing;
  bool get isPaused => _state == TtsState.paused;
  String? get errorMessage => _errorMessage;
  AudioPlayer get player => _player;

  TtsService() {
    _loadSettings();
    _initPlayer();
  }

  void _initPlayer() {
    _player.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        _state = TtsState.ready;
        notifyListeners();
      }
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _speechRate = prefs.getDouble('defaultSpeechRate') ?? 1.0;
    _pitch = prefs.getDouble('defaultPitch') ?? 1.0;
    final voiceIndex = prefs.getInt('selectedVoice') ?? PiperVoicePack.norman.index;
    _selectedVoice = PiperVoicePack.values[voiceIndex];
  }

  void setSpeechRate(double rate) {
    _speechRate = rate.clamp(0.5, 2.0);
    notifyListeners();
  }

  void setPitch(double pitch) {
    _pitch = pitch.clamp(0.5, 2.0);
    notifyListeners();
  }

  Future<void> setVoice(PiperVoicePack voice) async {
    _selectedVoice = voice;
    _state = TtsState.idle;
    notifyListeners();
    await initialize();
  }

  Future<void> initialize() async {
    if (_state == TtsState.loading || _state == TtsState.ready) return;
    
    _state = TtsState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _tts.loadViaVoicePack(_selectedVoice);
      _state = TtsState.ready;
    } catch (e) {
      _errorMessage = 'Voice model not loaded. Go to Settings > TTS to download a voice model first.';
      _state = TtsState.error;
    }
    notifyListeners();
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;

    try {
      if (_state != TtsState.ready && _state != TtsState.paused) {
        await initialize();
      }

      if (_state == TtsState.ready) {
        _currentText = text;
        
        final tempDir = await getTemporaryDirectory();
        final outputPath = '${tempDir.path}/piper_output_${DateTime.now().millisecondsSinceEpoch}.wav';
        
        final audioFile = await _tts.synthesizeToFile(
          text: text,
          outputPath: outputPath,
        );
        
        _audioPath = audioFile.path;
        await _player.setFilePath(audioFile.path);
        await _player.play();
        
        _state = TtsState.playing;
        notifyListeners();
      } else if (_state == TtsState.paused) {
        await _player.play();
        _state = TtsState.playing;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      _state = TtsState.error;
      notifyListeners();
    }
  }

  Future<void> pause() async {
    if (_state == TtsState.playing) {
      await _player.pause();
      _state = TtsState.paused;
      notifyListeners();
    }
  }

  Future<void> resume() async {
    if (_state == TtsState.paused) {
      await _player.play();
      _state = TtsState.playing;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _state = TtsState.ready;
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}