import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_speech/google_speech.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'screens/onboarding_screen.dart'; // 온보딩 화면 import

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
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: OnboardingScreen(), // 초기 화면을 OnboardingScreen으로 설정
      routes: {
        '/home': (context) => HomeScreen(), // HomeScreen으로 이동하기 위한 라우트 추가
      },
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
    _requestMicrophonePermission(); // 마이크 권한 요청
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
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    print('HomeScreen 빌드 시작');
    List<Widget> _pages = <Widget>[
      _buildHome(), // 홈 화면
      _buildSearch(), // 검색 화면
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
            icon: Icon(Icons.search),
            label: 'Search',
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

  Widget _buildSearch() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.all(16.0),
            children: [
              Text(
                'GPT에게 질문하세요:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '질문 입력',
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _sendQuestion,
                child: Text('질문 보내기'),
              ),
              SizedBox(height: 20),
              ..._qaList.map((qa) => _buildCard(qa['question']!, qa['answer']!)).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfile() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage('https://via.placeholder.com/150'),
          ),
          SizedBox(height: 10),
          Text(
            'UnoweTeam',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 5),
          Text(
            'unoweteam@gmail.com',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(String question, String answer) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
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
        _qaList.add({'question': question, 'answer': answer});
        _text = answer;
      });
      _speak(answer); // 답변이 오면 바로 TTS로 읽어줌
    } else {
      _speak('질문에 대한 답변을 가져오지 못했습니다');
    }
  }

  Future _sendQuestion() async {
    final question = _controller.text;
    if (question.isEmpty) return;

    print('Sending question: $question');
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
        _qaList.add({'question': question, 'answer': answer});
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
}
