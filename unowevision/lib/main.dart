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
      title: 'Japanese Learning AI',
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
  String _text = "Hello, how can I help you?";
  String _translatedText = "";
  String _feedback = "";

  @override
  void initState() {
    super.initState();
    _speak("Welcome to the Japanese Learning AI app. How can I assist you today?");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Japanese Learning AI'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(_text),
            ElevatedButton(
              onPressed: () => _speak(),
              child: Text('Speak'),
            ),
            ElevatedButton(
              onPressed: _listen,
              child: Text('Listen'),
            ),
            ElevatedButton(
              onPressed: _translate,
              child: Text('Translate'),
            ),
            Text(_translatedText),
            ElevatedButton(
              onPressed: _getFeedback,
              child: Text('Get Feedback'),
            ),
            Text(_feedback),
          ],
        ),
      ),
    );
  }

  Future _speak([String? text]) async {
    await flutterTts.speak(text ?? _text);
  }

  Future _listen() async {
    bool available = await speech.initialize();
    if (available) {
      speech.listen(onResult: (val) => setState(() {
        _text = val.recognizedWords;
        _handleVoiceCommand(_text);
      }));
    }
  }

  Future _translate() async {
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
      _speak("Translation: $_translatedText");
    } else {
      throw Exception('Failed to translate text');
    }
  }

  Future _getFeedback() async {
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
      _speak("Feedback: $_feedback");
    } else {
      throw Exception('Failed to get feedback');
    }
  }

  void _handleVoiceCommand(String command) {
    if (command.toLowerCase().contains("translate")) {
      _translate();
    } else if (command.toLowerCase().contains("feedback")) {
      _getFeedback();
    } else if (command.toLowerCase().contains("speak")) {
      _speak();
    } else {
      _speak("Sorry, I didn't understand that command.");
    }
  }
}