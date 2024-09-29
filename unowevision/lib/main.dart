import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '일본어 학습 AI',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  FlutterTts flutterTts = FlutterTts();
  stt.SpeechToText speech = stt.SpeechToText();
  String _text = "안녕하세요, 무엇을 도와드릴까요?";
  bool _isListening = false;
  Color _backgroundColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _speak("일본어 학습 AI 앱에 오신 것을 환영합니다. 무엇을 도와드릴까요?");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('일본어 학습 AI'),
      ),
      body: GestureDetector(
        onDoubleTap: () => _speak(),
        onLongPressStart: (_) {
          setState(() {
            _backgroundColor = Colors.green;
          });
          _listen();
        },
        onLongPressEnd: (_) {
          setState(() {
            _backgroundColor = Colors.white;
          });
          _stopListening();
        },
        onTap: () => _speak(_text),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 100),
          color: _backgroundColor,
          child: Center(
            child: Text(_text),
          ),
        ),
      ),
    );
  }

  Future _speak([String? text]) async {
    await flutterTts.setLanguage("ko-KR");
    await flutterTts.speak(text ?? _text);
  }

  Future _listen() async {
    bool available = await speech.initialize();
    if (available) {
      setState(() {
        _isListening = true;
      });
      speech.listen(
        onResult: (val) => setState(() {
          _text = val.recognizedWords;
          if (val.finalResult) {
            _isListening = false;
            _getAnswer(); // 음성 인식이 끝나면 바로 질문을 보냄
          }
        }),
        localeId: "ko_KR",
      );
    }
  }

  Future _stopListening() async {
    speech.stop();
    setState(() {
      _isListening = false;
    });
  }

  Future _getAnswer() async {
    print('Sending answer request: $_text');
    final response = await http.post(
      Uri.parse('http://localhost:3000/answer'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'question': _text,
      }),
    );

    if (response.statusCode == 200) {
      final answer = jsonDecode(response.body)['answer'];
      setState(() {
        _text = answer;
      });
    } else {
      _speak('질문에 대한 답변을 가져오지 못했습니다');
    }
  }

  void _handleVoiceCommand(String command) {
    if (command.contains("질문")) {
      _getAnswer();
    } else {
      _speak("죄송합니다, 그 명령을 이해하지 못했습니다.");
    }
  }
}