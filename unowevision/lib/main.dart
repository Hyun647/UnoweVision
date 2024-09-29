import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:provider/provider.dart';
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
  String _translatedText = "";
  String _feedback = "";
  bool _isListening = false;

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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(_text),
            ElevatedButton(
              onPressed: () => _speak(),
              child: Text('말하기'),
            ),
            ElevatedButton(
              onPressed: _listen,
              child: Text('듣기'),
            ),
            ElevatedButton(
              onPressed: _translate,
              child: Text('번역하기'),
            ),
            Text(_translatedText),
            ElevatedButton(
              onPressed: _getFeedback,
              child: Text('피드백 받기'),
            ),
            Text(_feedback),
          ],
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
            _handleVoiceCommand(_text);
          }
        }),
        localeId: "ko_KR",
      );
    }
  }

  Future _translate() async {
    print('Sending translate request: $_text');
    final response = await http.post(
      Uri.parse('http://localhost:3000/translate'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'text': _text,
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        _translatedText = jsonDecode(response.body)['translatedText'];
      });
      _speak("번역: $_translatedText");
    } else {
      _speak('번역에 실패했습니다');
    }
  }

  Future _getFeedback() async {
    print('Sending feedback request: $_text');
    final response = await http.post(
      Uri.parse('http://localhost:3000/feedback'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'text': _text,
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        _feedback = jsonDecode(response.body)['feedback'];
      });
      _speak("피드백: $_feedback");
    } else {
      _speak('피드백 받기에 실패했습니다');
    }
  }

  void _handleVoiceCommand(String command) {
    if (command.contains("번역")) {
      _translate();
    } else if (command.contains("피드백")) {
      _getFeedback();
    } else if (command.contains("말하기")) {
      _speak();
    } else {
      _speak("죄송합니다, 그 명령을 이해하지 못했습니다.");
    }
  }
}