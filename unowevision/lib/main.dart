import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_speech/google_speech.dart'; // google_speech 패키지 import
import 'package:flutter_dotenv/flutter_dotenv.dart'; // flutter_dotenv 패키지 추가
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Flutter 프레임워크가 초기화될 때까지 대기
  try {
    await dotenv.load(fileName: ".env"); // 환경 변수 로드
    print('환경 변수 로드 성공');
  } catch (e) {
    print('Error loading .env file: $e'); // 예외 처리 추가
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
  int _selectedIndex = 0;
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> _qaList = [];

  // 발음 평가 결과를 저장할 변수 추가
  String _pronunciationScore = "";

  @override
  void initState() {
    super.initState();
    print('HomeScreen 초기화');
    _speak("일본어 학습 AI 앱에 오신 것을 환영합니다. 무엇을 도와드릴까요?");
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
        return "검색";
      case 2:
        return "프로필";
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    print('HomeScreen 빌드 시작');
    List<Widget> _pages = <Widget>[
      _buildHome(),
      _buildSearch(),
      _buildProfile(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('일본어 학습 AI'),
        backgroundColor: Colors.black,
      ),
      body: Column(
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
        backgroundColor: Colors.black,
        unselectedItemColor: Colors.white,
      ),
    );
  }

  Widget _buildHome() {
    return GestureDetector(
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
      onTap: () {
        try {
          _stopTTS();
        } catch (e) {
          print('Error stopping TTS: $e');
        }
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 100),
        color: _backgroundColor,
        child: Center(
          child: Text(
            _text,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '질문: $question',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              '답변: $answer',
              style: TextStyle(fontSize: 16),
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
        });
        speech.listen(
          onResult: (val) => setState(() {
            _text = val.recognizedWords;
            if (val.finalResult) {
              _isListening = false;
              _getAnswer(); // 음성 인식이 끝나면 바로 질문을 보냄
              _evaluatePronunciation(_text); // 발음 평가 함수 호출
            }
          }),
          localeId: "ko_KR",
        );
      }
    } catch (e) {
      print('Error initializing speech recognition: $e');
    }
  }

  Future _stopListening() async {
    try {
      speech.stop();
      setState(() {
        _isListening = false;
      });
    } catch (e) {
      print('Error stopping speech recognition: $e');
    }
  }

  Future _getAnswer() async {
    print('Sending answer request: $_text');
    final response = await http.post(
      Uri.parse('http://110.15.29.199:7654/answer'), // 변경된 URL
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
        _qaList.add({'question': _text, 'answer': answer});
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