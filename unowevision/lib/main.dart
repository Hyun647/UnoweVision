import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_speech/google_speech.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/onboarding_screen.dart';

List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
    print('환경 변수 로드 성공');
  } catch (e) {
    print('Error loading .env file: $e');
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print('MyApp 빌드 시작');
    return MaterialApp(
      title: '일본어 학습 AI',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: FutureBuilder<bool>(
        future: _checkOnboardingCompleted(),
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else {
            if (snapshot.data == true) {
              return HomeScreen();
            } else {
              return OnboardingScreen();
            }
          }
        },
      ),
      routes: {
        '/home': (context) => HomeScreen(),
      },
    );
  }

  Future<bool> _checkOnboardingCompleted() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboardingCompleted') ?? false;
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  FlutterTts flutterTts = FlutterTts();
  stt.SpeechToText speech = stt.SpeechToText();
  String _text = "안녕하세요\n무엇을 도와드릴까요?";
  bool _isListening = false;
  Color _backgroundColor = Colors.white;
  int _selectedIndex = 0;
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> _qaList = [];
  String _pronunciationScore = "";

  @override
  void initState() {
    super.initState();
    print('HomeScreen 초기화');
    _requestMicrophonePermission();
    _speak("일본어 학습 AI 앱에 오신 것을 환영합니다. 무엇을 도와드릴까요?");
  }

  void _requestMicrophonePermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      if (await Permission.microphone.request().isGranted) {
        print('마이크 권한 허용됨');
      } else {
        print('마이크 권한 거부됨');
      }
    } else {
      print('마이크 권한 이미 허용됨');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _speak(_getTabName(index));
  }

  String _getTabName(int index) {
    switch (index) {
      case 0:
        return "홈";
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    print('HomeScreen 빌드 시작');
    return Scaffold(
      appBar: AppBar(
        title: Text('일본어 학습 AI'),
        backgroundColor: Colors.black,
      ),
      body: _buildHome(), // 홈 화면만 표시
    );
  }

  Widget _buildHome() {
    return GestureDetector(
      onDoubleTap: () => _speak(),
      onLongPressStart: (_) {
        setState(() {
          _backgroundColor = Colors.white;
          _text = "음성인식 중입니다.";
        });
        _listen();
      },
      onLongPressEnd: (_) {
        setState(() {
          _backgroundColor = Colors.white;
        });
        _stopListening();
      },
      onTap: () {
        try {
          _stopTTS();
        } catch (e) {
          print('Error stopping TTS: $e');
        }
      },
      child: Stack(
        children: [
          AnimatedContainer(
            duration: Duration(milliseconds: 100),
            color: _backgroundColor,
            child: Center(
              child: Icon(
                Icons.mic,
                size: 100,
                color: _isListening ? Colors.green : Colors.red,
              ),
            ),
          ),
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Unowe',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                _text,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future _speak([String? text]) async {
    await flutterTts.setLanguage("ko-KR");
    await flutterTts.speak(text ?? _text);
  }

  Future _stopTTS() async {
    await flutterTts.stop();
  }

  Future _listen() async {
    try {
      bool available = await speech.initialize(
        onStatus: (status) => print('onStatus: $status'),
        onError: (error) => print('onError: $error'),
      );
      if (available) {
        setState(() {
          _isListening = true;
          _text = "음성인식 중입니다.";
        });
        speech.listen(
          onResult: (val) => setState(() {
            _text = val.recognizedWords;
            if (val.finalResult) {
              _isListening = false;
              _getAnswer(_text);
              _evaluatePronunciation(_text);
            }
          }),
          localeId: "ko_KR",
        );
      } else {
        print('음성 인식 사용 불가');
      }
    } catch (e) {
      print('음성 인식 초기화 오류: $e');
    }
  }

  Future _stopListening() async {
    try {
      await speech.stop();
      setState(() {
        _isListening = false;
        _text = "안녕하세요\n무엇을 도와드릴까요?";
      });
    } catch (e) {
      print('Error stopping speech recognition: $e');
    }
  }

  Future _getAnswer(String question) async {
    print('Sending answer request: $question');
    final response = await http.post(
      Uri.parse('http://110.15.29.199:7654/answer'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'question': question,
      }),
    );

    if (response.statusCode == 200) {
      final answer = jsonDecode(response.body)['answer'];
      setState(() {
        _qaList.add({'question': question, 'answer': answer});
        _text = answer;
      });
      _speak(answer);
    } else {
      _speak('질문에 대한 답변을 가져오지 못했습니다');
    }
  }

  Future _evaluatePronunciation(String text) async {
    final serviceAccount = ServiceAccount.fromString(
      await File(dotenv.env['GOOGLE_APPLICATION_CREDENTIALS']!).readAsString(),
    );
    final client = SpeechToText.viaServiceAccount(serviceAccount);
    final config = RecognitionConfig(
      encoding: AudioEncoding.LINEAR16,
      model: RecognitionModel.basic,
      sampleRateHertz: 16000,
      languageCode: 'ko-KR',
    );

    final audio = await _getAudioContent();

    final response = await client.recognize(config, audio);
    final score = response.results.first.alternatives.first.confidence;

    setState(() {
      _pronunciationScore = "발음 평가 점수: ${score * 100}%";
    });

    _speak(_pronunciationScore);
  }

  Future<List<int>> _getAudioContent() async {
    return [];
  }
}
