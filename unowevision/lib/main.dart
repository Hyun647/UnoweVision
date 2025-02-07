import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_speech/google_speech.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/onboarding_screen.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 전체 화면 모드 설정
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // 상태바와 네비게이션 바를 투명하게 설정
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));

  try {
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
      title: 'UnoweVision',
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
  List<Map<String, String>> _qaList = []; // 대화 히스토리 저장
  String _pronunciationScore = "";

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _speak("유노이 비전에 오신 것을 환영합니다. 화면을 꾹 눌러 대화를 시작해보세요.");
  }


  void _requestPermissions() async {
    var microphoneStatus = await Permission.microphone.status;

    if (!microphoneStatus.isGranted) {
      PermissionStatus status = await Permission.microphone.request();

      if (status.isGranted) {
        print('마이크 권한 허용됨');
      } else {
        print('마이크 권한 거부됨');
      }
    } else {
      print('마이크 권한 이미 허용됨');
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
      // TTS 중지
      await _stopTTS();

      bool available = await speech.initialize(
        onStatus: (status) => print('onStatus: $status'),
        onError: (error) => print('onError: $error'),
      );
      if (available) {
        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(duration: 100); // 100ms 동안 진동
        }
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
    final apiKey = '';
    // 대화 히스토리를 포함하여 메시지 생성
    List<Map<String, String>> messages = [
      {'role': 'system', 'content': '당신은 시각 장애인의 일본어 학습을 돕기 위해 설계된 AI입니다. 당신의 이름은 노이(Noi)입니다. 답변은 최대한 간결하게 해주세요. 답변에 ()괄호를 넣지 마시오. 사용자는 어제 일본어로 인사에 대해 학습했습니다.'},
    ];

    // 기존 대화 히스토리를 추가
    for (var qa in _qaList) {
      messages.add({'role': 'user', 'content': qa['question']!});
      messages.add({'role': 'assistant', 'content': qa['answer']!});
    }

    // 현재 질문 추가
    messages.add({'role': 'user', 'content': '다음 질문에 한국어로 답변해 주세요: $question'});

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': messages,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final decodedResponse = utf8.decode(response.bodyBytes);
      final answer = jsonDecode(decodedResponse)['choices'][0]['message']['content'].trim();
      setState(() {
        _qaList.add({'question': question, 'answer': answer}); // 대화 히스토리에 추가
        _text = answer;
      });
      _speak(answer);
    } else {
      print('Error: ${response.statusCode}');
      print('Response body: ${response.body}');
      _speak('질문에 대한 답변을 가져오지 못했습니다');
    }
  }

  Future _evaluatePronunciation(String text) async {
    final apiKey = '구글 API 키';
    final client = SpeechToText.viaApiKey(apiKey);
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
          _isListening = true; // 마이크 아이콘을 초록색으로 변경
        });
        _listen();
      },
      onLongPressEnd: (_) {
        setState(() {
          _backgroundColor = Colors.white;
          _isListening = false; // 마이크 아이콘을 빨간색으로 변경
        });
        _stopListening();
      },
      onTap: () {
        try {
          _stopTTS();
          _speak("화면을 꾹 눌러주세요.");
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

  Widget _buildProfile() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: AssetImage('assets/images/teamlogo.png'),
          ),
          SizedBox(height: 20),
          Text(
            "UnoweTeam",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Text(
            "이메일 : unoweteam@gmail.com",
            style: TextStyle(fontSize: 18),
          ),
          // 추가적인 프로필 정보나 위젯을 여기에 추가할 수 있습니다.
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> _pages = <Widget>[
      _buildHome(),
      _buildProfile(),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('UnoweVision'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _pages[_selectedIndex]),
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
