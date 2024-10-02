import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Noi에게 뭐든 물어보세요',
      description: '음성 인식을 하여 질문에\n대한 대답을 할 수 있습니다.',
      image: 'assets/images/onboardingphone.png',
    ),
    OnboardingPage(
      title: '일본어 교재 음성 제공',
      description: '왼쪽 제스처를 사용하여 카메라를 열어보세요\nNoi가 TTS로 읽어드립니다.',
      image: 'assets/images/onboardingphone.png',
    ),
    OnboardingPage(
      title: '발음 피드백',
      description: '음성 데이터 수집 후 일본어 데이터를 통해\n발음 정확도, 억양등의 피드백을 제공해 드립니다.',
      image: 'assets/images/onboardingphone.png',
    ),
    OnboardingPage(
      title: '학습 진도율 생성',
      description: '교재 내 단원의 학습완료 여부, 피드백 데이터를\n저장하여 개인화된 학습 계획을 생성할 수 있습니다.',
      image: 'assets/images/onboardingphone.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemBuilder: (context, index) {
              return buildPageContent(_pages[index]);
            },
          ),
          Positioned(
            top: 70, // 점들을 조금 더 아래로 내림
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => buildDot(index),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: buildBottomButtons(),
          ),
        ],
      ),
    );
  }

  Widget buildPageContent(OnboardingPage page) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(height: 120), // 80에서 120으로 변경하여 더 아래로 내림
          Text(
            page.title,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          Text(
            page.description,
            style: TextStyle(fontSize: 13),
            textAlign: TextAlign.center,
          ),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Image.asset(
                page.image,
                fit: BoxFit.contain,
                width: double.infinity,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDot(int index) {
    return Container(
      height: 10,
      width: 10,
      margin: EdgeInsets.only(right: 5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _currentPage == index ? Colors.blue : Colors.grey,
      ),
    );
  }

  Widget buildBottomButtons() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, -1),
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/home');
            },
            child: Text(
              'SKIP',
              style: TextStyle(
                color: Colors.blue, // SKIP 버튼의 텍스트 색을 파란색으로 변경
                fontSize: 16,
              ),
            ),
          ),
          _currentPage == _pages.length - 1
              ? ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/home');
                  },
                  child: Text('시작하기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white, // 텍스트 색상을 흰색으로 설정
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  ),
                )
              : ElevatedButton(
                  onPressed: () {
                    _pageController.nextPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Text('NEXT'), // '다음'을 'NEXT'로 변경
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white, // 텍스트 색상을 흰색으로 설정
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  ),
                ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final String image;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.image,
  });
}