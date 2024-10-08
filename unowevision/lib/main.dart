import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_speech/google_speech.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/onboarding_screen.dart';
import 'package:camera/camera.dart';

List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
    print('환경 변수 로드 성공');
  } catch (e) {
    print('Error loading .env file: $e');
  }
  cameras = await availableCameras();
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
  String _pronunciationScore = "";

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _speak("일본어 학습 AI 앱에 오신 것을 환영합니다. 무엇을 도와드릴까요?");
  }

  void _requestPermissions() async {
    var microphoneStatus = await Permission.microphone.status;
    var cameraStatus = await Permission.camera.status;

    if (!microphoneStatus.isGranted || !cameraStatus.isGranted) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.microphone,
        Permission.camera,
      ].request();

      if (statuses[Permission.microphone]!.isGranted) {
        print('마이크 권한 허용됨');
      } else {
        print('마이크 권한 거부됨');
      }

      if (statuses[Permission.camera]!.isGranted) {
        print('카메라 권한 허용됨');
      } else {
        print('카메라 권한 거부됨');
      }
    } else {
      print('마이크 및 카메라 권한 이미 허용됨');
    }
  }

  Future _speak(String text) async {
    await flutterTts.setLanguage("ko-KR");
    await flutterTts.speak(text);
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
              _getAnswer(_text); // 음성 인식이 끝나면 바로 질문을 보냄
              _evaluatePronunciation(_text); // 발음 평가 함수 호출
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
      Uri.parse('http://110.15.29.199:7654/answer'), // 변경된 URL
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
        _text = answer;
      });
      _speak(answer); // 답변이 오면 바로 TTS로 읽어줌
    } else {
      _speak('질문에 대한 답변을 가져오지 못했습니다');
    }
  }

  // 발음 평가 함수 추가
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

    final audio = await _getAudioContent(); // 음성 데이터를 가져오는 함수

    final response = await client.recognize(config, audio);
    final score = response.results.first.alternatives.first.confidence;

    setState(() {
      _pronunciationScore = "발음 평가 점수: ${score * 100}%";
    });

    _speak(_pronunciationScore); // 발음 평가 점수를 TTS로 읽어줌
  }

  // 음성 데이터를 가져오는 함수 (예시)
  Future<List<int>> _getAudioContent() async {
    // 여기에 음성 데이터를 가져오는 로직을 추가하세요
    // 예를 들어, 로컬 파일에서 음성 데이터를 읽어올 수 있습니다.
    return [];
  }

  void _openCamera() {
    _speak("카메라");
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CameraScreen()),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      _speak("홈");
    } else {
      _openCamera();
    }
  }

  Widget _buildHome() {
    return GestureDetector(
      onDoubleTap: () => _speak,
      onLongPressStart: (_) {
        setState(() {
          _backgroundColor = Colors.white;
          _text = "음성인식 중입니다.";
          _speak("음성인식 중입니다.");
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
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! < 0) {
          _openCamera();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('일본어 학습 AI'),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(child: _buildHome()),
          if (_pronunciationScore.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _pronunciationScore,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera),
            label: 'Camera',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _controller = CameraController(
        cameras[0],
        ResolutionPreset.high,
      );
      _initializeControllerFuture = _controller.initialize();
      await _initializeControllerFuture;
    } catch (e) {
      print('카메라 초기화 오류: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendPictureToGoogleVision(XFile image) async {
    final bytes = await image.readAsBytes();
    final base64Image = base64Encode(bytes);

    final apiKey = dotenv.env['GOOGLE_VISION_API_KEY'];
    final url = 'https://vision.googleapis.com/v1/images:annotate?key=$apiKey';

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'requests': [
          {
            'image': {'content': base64Image},
            'features': [
              {'type': 'LABEL_DETECTION', 'maxResults': 10},
            ],
          },
        ],
      }),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      print('Google Vision API 응답: $responseBody');

      final labels = responseBody['responses'][0]['labelAnnotations']
          .map((label) => label['description'])
          .join(', ');

      _speak('이미지 분석 결과는 다음과 같습니다: $labels');
    } else {
      print('Google Vision API 요청 실패');
      print('응답 코드: ${response.statusCode}');
      print('응답 메시지: ${response.body}');
      _speak('이미지 분석에 실패했습니다.');
    }
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();
      if (!mounted) return;

      await _sendPictureToGoogleVision(image);
    } catch (e) {
      print('사진 촬영 오류: $e');
    }
  }

  Future _speak(String text) async {
    await flutterTts.setLanguage("ko-KR");
    await flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('카메라')),
      body: GestureDetector(
        onLongPress: () async {
          await _takePicture();
        },
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! > 0) {
            _speak("홈");
            Navigator.pop(context);
          }
        },
        child: FutureBuilder<void>(
          future: _initializeControllerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return CameraPreview(_controller);
            } else {
              return Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }
}