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
    );
  }
}

class JapaneseLearningScreen extends StatefulWidget {
  @override
  _JapaneseLearningScreenState createState() => _JapaneseLearningScreenState();
}

class _JapaneseLearningScreenState extends State<JapaneseLearningScreen> {
  final ChatGptService _chatGptService = ChatGptService();
  stt.SpeechToText _speech;
  FlutterTts _flutterTts;
  bool _isListening = false;
  String _text = 'Press the button and start speaking';
  String _response = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
  }

  void _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(onResult: (val) => setState(() {
        _text = val.recognizedWords;
      }));
    }
  }

  void _stopListening() async {
    setState(() => _isListening = false);
    _speech.stop();
    _getResponse();
  }

  void _getResponse() async {
    String response = await _chatGptService.getJapaneseLearningResponse(_text);
    setState(() {
      _response = response;
    });
    _speak(response);
  }

  void _speak(String text) async {
    await _flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Japanese Learning App')),
      body: Column(
        children: [
          Text(_text),
          Text(_response),
          FloatingActionButton(
            onPressed: _isListening ? _stopListening : _startListening,
            child: Icon(_isListening ? Icons.mic : Icons.mic_none),
          ),
        ],
      ),
    );
  }
}