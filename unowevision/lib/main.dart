import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_speech/google_speech.dart'; // google_speech 패키지 import
import 'package:flutter_dotenv/flutter_dotenv.dart'; // flutter_dotenv 패키지 추가
import 'dart:io';
import 'package:permission_handler/permission_handler.dart'; // permission_handler 패키지 추가
import 'package:camera/camera.dart'; // camera 패키지 추가

List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Flutter 프레임워크가 초기화될 때까지 대기
  try {
    await dotenv.load(fileName: ".env"); // 환경 변수 로드
    print('환경 변수 로드 성공');
  } catch (e) {
    print('Error loading .env file: $e'); // 예외 처리 추가
  }

  // 카메라 초기화
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
  String _text = "안녕하세요\n무엇을 도와드릴까요?";
  bool _isListening = false;
  Color _backgroundColor = Colors.white;
  int _selectedIndex = 0;
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> _qaList = [];

  // 발음 평가 결과를 저장할 변수 추가
  String _pronunciationScore = "";

  @override
  void initState() {
    super.initState();
    print('HomeScreen 초기화');
    _requestPermissions(); // 마이크 및 카메라 권한 요청
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
    final apiKey = '여기에 API키 입력'; // 실제 API 키로 교체
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4', // gpt-4 또는 gpt-4-turbo 모델 사용
        'messages': [
          {'role': 'system', 'content': '당신은 시각 장애인의 일본어 학습을 돕기 위해 설계된 AI입니다. TTS 출력에 적합한 형식으로 응답을 제공하십시오.'},
          {'role': 'user', 'content': '다음 질문에 한국어로 답변해 주세요: $question'}
        ],
        'temperature': 0.7,
      }),
    );

    if (response.statusCode == 200) {
      // 응답 본문을 UTF-8로 디코딩
      final decodedResponse = utf8.decode(response.bodyBytes);
      final answer = jsonDecode(decodedResponse)['choices'][0]['message']['content'].trim();
      setState(() {
        _qaList.add({'question': question, 'answer': answer});
        _text = answer;
      });
      _speak(answer); // 답변이 오면 바로 TTS로 읽어줌
    } else {
      print('Error: ${response.statusCode}');
      print('Response body: ${response.body}');
      _speak('질문에 대한 답변을 가져오지 못했습니다');
    }
  }

  Future _sendQuestion() async {
    final question = _controller.text;
    if (question.isEmpty) return;

    print('Sending question: $question');
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4', // gpt-4 또는 gpt-4-turbo 모델 사용
        'messages': [
          {'role': 'system', 'content': '당신은 시각 장애인의 일본어 학습을 돕기 위해 설계된 AI입니다. TTS 출력에 적합한 형식으로 응답을 제공하십시오.'},
          {'role': 'user', 'content': '다음 질문에 한국어로 답변해 주세요: $question'}
        ],
        'temperature': 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final answer = jsonDecode(response.body)['choices'][0]['message']['content'].trim();
      setState(() {
        _qaList.add({'question': question, 'answer': answer});
        _text = answer;
      });
      _speak(answer); // 답변이 오면 바로 TTS로 읽어줌
    } else {
      print('Error: ${response.statusCode}');
      print('Response body: ${response.body}');
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
    _speak("카메라"); // 카메라 화면으로 전환 시 "카메라" 알림
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CameraScreen()),
    );
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
      case 1:
        return "프로필";
      default:
        return "";
    }
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
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! < 0) {
          _openCamera(); // 오른쪽으로 드래그하면 카메라 화면으로 전환
        }
      },
      child: Stack(
        children: [
          AnimatedContainer(
            duration: Duration(milliseconds: 100),
            color: _backgroundColor, // 배경색을 검은색으로 설정
            child: Center(
              child: Icon(
                Icons.mic, // 음성 인식에 반응하는 아이콘
                size: 100,
                color: _isListening ? Colors.green : Colors.red, // 음성 인식 중일 때 색상 변경
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

  Widget _buildProfile() {
    // 프로필 화면을 구성하는 로직을 여기에 추가하세요
    return Center(child: Text("프로필 화면"));
  }

  @override
  Widget build(BuildContext context) {
    print('HomeScreen 빌드 시작');
    List<Widget> _pages = <Widget>[
      _buildHome(), // 홈 화면
      _buildProfile(), // 프로필 화면
    ];


    return Scaffold(
      appBar: AppBar(
        title: Text('일본어 학습 AI'),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(child: _pages[_selectedIndex]), // 선택된 페이지 표시
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
            icon: Icon(Icons.person),
            label: 'Profile',
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
  FlutterTts flutterTts = FlutterTts(); // TTS 인스턴스 추가

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      cameras[0], // 사용 가능한 첫 번째 카메라 사용
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();
      if (!mounted) return;

      // 사진을 서버로 전송
      await _sendPictureToServer(image);
    } catch (e) {
      print('사진 촬영 오류: $e');
    }
  }

  Future<void> _sendPictureToServer(XFile image) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('http://110.15.29.199:7654/upload'), // 서버의 IP 주소와 포트 번호 확인
    );
    request.files.add(await http.MultipartFile.fromPath('picture', image.path));
    final response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final answer = jsonDecode(responseBody)['answer'];
      print('서버 응답: $answer');
      _speak(answer); // 답변을 TTS로 읽어줌
    } else {
      print('사진 전송 실패');
      print('응답 코드: ${response.statusCode}');
      print('응답 메시지: ${await response.stream.bytesToString()}');
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
          print('화면 꾹 누름 - 사진 촬영 시도');
          await _takePicture();
        }, // 화면을 꾹 누르면 사진 촬영
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! > 0) {
            _speak("홈"); // 홈 화면으로 전환 시 "홈" 알림
            Navigator.pop(context); // 왼쪽으로 드래그하면 홈 화면으로 돌아감
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
