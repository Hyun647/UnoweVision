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

  @override
  void initState() {
    super.initState();
    _speak("일본어 학습 AI 앱에 오신 것을 환영합니다. 무엇을 도와드릴까요?");
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
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
      body: _pages[_selectedIndex],
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
      onTap: () => _stopTTS(),
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
              Text(
                _text,
                style: TextStyle(fontSize: 18),
              ),
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
            '사용자 이름',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 5),
          Text(
            'user@example.com',
            style: TextStyle(fontSize: 16, color: Colors.grey),
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
      Uri.parse('http://localhost:3000/answer'),
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
}