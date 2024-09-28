import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'services/chat_gpt_service.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: JapaneseLearningScreen(),
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
    );
  }
}

class JapaneseLearningScreen extends StatefulWidget {
  @override
  _JapaneseLearningScreenState createState() => _JapaneseLearningScreenState();
}

class _JapaneseLearningScreenState extends State<JapaneseLearningScreen> {
  final ChatGptService _chatGptService = ChatGptService();
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  String _text = '';
  String _response = '';
  Color _backgroundColor = Colors.white;
  List<dynamic> _voices = [];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _initializeTts();
  }

  void _initializeTts() async {
    await _flutterTts.setLanguage('ko-KR');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _voices = await _flutterTts.getVoices;
    if (_voices.isNotEmpty) {
      // 첫 번째 목소리를 선택하여 설정
      var selectedVoice = Map<String, String>.from(_voices.first);
      await _flutterTts.setVoice(selectedVoice);
    }

    _flutterTts.setCompletionHandler(() {
      // 음성 안내가 끝난 후 마이크를 켜지 않음
    });

    _speak("앱이 시작되었습니다. 질문을 말하세요.");
  }

  void _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (val) => setState(() {
          _text = val.recognizedWords;
          if (val.finalResult) {
            _getResponse();
          }
        }),
        localeId: 'ko_KR',
      );
    }
  }

  void _stopListening() async {
    setState(() => _isListening = false);
    _speech.stop();
  }

  void _getResponse() async {
    try {
      print('Recognized text: $_text');
      String response = await _chatGptService.getJapaneseLearningResponse(_text);
      setState(() {
        _response = response;
      });
      print('Response from API: $response');
      _speakResponse(response);
    } catch (e) {
      print('Error: $e');
      setState(() {
        _response = '응답을 불러오는데 실패했습니다.';
      });
      _speak('응답을 불러오는데 실패했습니다.');
    }
  }

  void _speakResponse(String response) {
    // 응답을 파싱하여 괄호 안의 내용을 제거
    final cleanedResponse = response.replaceAll(RegExp(r'\([^)]*\)'), '');

    // 응답을 파싱하여 일본어와 발음을 분리
    final regex = RegExp(r'"([^"]+)"를 일본어로 말하면 "([^"]+)"입니다. 발음은 "([^"]+)"입니다.');
    final match = regex.firstMatch(cleanedResponse);

    if (match != null) {
      final koreanText = match.group(1);
      final japaneseText = match.group(2);
      final pronunciation = match.group(3);

      // 일본어 읽기
      _flutterTts.setLanguage('ja-JP');
      _flutterTts.speak(japaneseText!);

      // 발음 읽기
      _flutterTts.setLanguage('ko-KR');
      _flutterTts.speak(pronunciation!);
    } else {
      // 파싱에 실패한 경우 전체 응답을 읽기
      _speak(cleanedResponse);
    }
  }

  void _speak(String text) {
    _flutterTts.stop(); // 기존 TTS 읽기를 중지
    _flutterTts.setVolume(1.0); // TTS 볼륨을 항상 최대치로 설정
    _flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('UnoweVision')),
      body: GestureDetector(
        onLongPressStart: (details) {
          setState(() {
            _backgroundColor = Colors.green;
          });
          _startListening();
        },
        onLongPressEnd: (details) {
          setState(() {
            _backgroundColor = Colors.white;
          });
          _stopListening();
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          color: _backgroundColor,
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                size: 100,
                color: _isListening ? Colors.red : Colors.grey,
              ),
              SizedBox(height: 20),
              Text(
                '질문을 말하세요:',
                style: TextStyle(fontSize: 24),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              if (_text.isNotEmpty || _response.isNotEmpty)
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_text.isNotEmpty)
                          Text(
                            '질문: $_text',
                            style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
                            textAlign: TextAlign.center,
                          ),
                        if (_response.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Text(
                              '답변: $_response',
                              style: TextStyle(fontSize: 18),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}