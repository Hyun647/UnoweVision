import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // HomeScreen이 정의된 파일을 import

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
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

  void _completeOnboarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingCompleted', true);
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(0),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      backgroundColor: Color(0xFFFAFAFA),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                physics: ClampingScrollPhysics(),
                onPageChanged: (int page) => setState(() => _currentPage = page),
                itemBuilder: (context, index) => buildPageContent(_pages[index], index, constraints),
              ),
              Positioned(
                top: constraints.maxHeight * 0.05,
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
                child: buildBottomButtons(constraints),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget buildPageContent(OnboardingPage page, int index, BoxConstraints constraints) {
    double screenWidth = constraints.maxWidth;
    double screenHeight = constraints.maxHeight;

    return Container(
      color: Color(0xFFFAFAFA),
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(height: screenHeight * 0.15),
          Text(
            page.title,
            style: TextStyle(fontSize: screenWidth * 0.06, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: screenHeight * 0.02),
          Text(
            page.description,
            style: TextStyle(fontSize: screenWidth * 0.035),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: screenHeight * 0.02),
          Expanded(
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Image.asset(
                  page.image,
                  fit: BoxFit.contain,
                  width: double.infinity,
                ),
                if (index == 1)
                  Positioned(
                    top: screenHeight * 0.016,
                    child: buildCameraUI(screenWidth, screenHeight),
                  ),
                if (index != 1)
                  Positioned(
                    top: screenHeight * 0.1,
                    left: 0,
                    right: 0,
                    child: Text(
                      'Unowe',
                      style: TextStyle(
                        color: Color(0xFF007AFF),
                        fontSize: screenWidth * 0.12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (index == 0 || index == 2)
                  Positioned(
                    top: screenHeight * 0.17,
                    child: buildWaitingUI(screenWidth, screenHeight, index),
                  ),
                if (index == 3)
                  Positioned(
                    top: screenHeight * 0.25,
                    left: screenWidth * 0.1,
                    right: screenWidth * 0.1,
                    child: buildProgressUI(screenWidth, screenHeight),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCameraUI(double screenWidth, double screenHeight) {
    return Column(
      children: [
        Container(
          width: screenWidth * 0.7152,
          height: screenHeight * 0.08,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(screenWidth * 0.105),
              topRight: Radius.circular(screenWidth * 0.105),
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: screenWidth * 0.05,
                top: screenHeight * 0.031,
                child: Container(
                  width: screenWidth * 0.04,
                  height: screenWidth * 0.04,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: Icon(
                    Icons.flash_off,
                    color: Colors.white,
                    size: screenWidth * 0.03,
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: EdgeInsets.only(top: screenHeight * 0.01),
                  child: Icon(
                    Icons.keyboard_arrow_up,
                    color: Colors.white,
                    size: screenWidth * 0.06,
                  ),
                ),
              ),
              Positioned(
                right: screenWidth * 0.05,
                top: screenHeight * 0.035,
                child: Image.asset(
                  'assets/images/Live.png',
                  height: screenHeight * 0.02,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: screenWidth * 0.7152,
          height: screenHeight * 0.53,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/cameraeximg.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
              Positioned(
                bottom: screenHeight * 0.03,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        buildZoomOption('.5', screenWidth * 0.05, screenHeight),
                        SizedBox(width: screenWidth * 0.04),
                        buildZoomOption('1x', screenWidth * 0.07, screenHeight),
                        SizedBox(width: screenWidth * 0.04),
                        buildZoomOption('3', screenWidth * 0.05, screenHeight),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        buildCameraOption('슬로 모션', false, screenWidth),
                        buildCameraOption('비디오', false, screenWidth),
                        buildCameraOption('사진', true, screenWidth),
                        buildCameraOption('인물 사진', false, screenWidth),
                        buildCameraOption('파노라마', false, screenWidth),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: screenHeight * 0.15,
                right: screenWidth * 0.1,
                child: Image.asset(
                  'assets/images/focus.png',
                  width: screenWidth * 0.2,
                  height: screenWidth * 0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildWaitingUI(double screenWidth, double screenHeight, int index) {
    return Column(
      children: [
        Image.asset(
          'assets/images/waitingimg.gif',
          width: screenWidth * 0.6,
          height: screenWidth * 0.6,
          fit: BoxFit.contain,
        ),
        SizedBox(height: screenHeight * 0.01),
        Text(
          index == 2
              ? '콘니치아 보다 곤니찌와로\n발음하는 것이 좋을 것 같아요!'
              : '환영합니다.\n무엇을 도와드릴까요?',
          style: TextStyle(
            color: Color(0xFF007AFF),
            fontSize: screenWidth * 0.04,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget buildProgressUI(double screenWidth, double screenHeight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '2024년 10월 1일',
          style: TextStyle(
            color: Color(0xFF007AFF),
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: screenHeight * 0.02),
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: screenWidth * 0.8,
              height: screenHeight * 0.015,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(screenHeight * 0.0075),
                child: LinearProgressIndicator(
                  value: 0.8,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
            ),
            Container(
              width: 2,
              height: screenHeight * 0.015,
              color: Colors.white,
            ),
            Positioned(
              left: 0,
              bottom: -screenHeight * 0.025,
              child: Text(
                '0%',
                style: TextStyle(
                  color: Color(0xFF007AFF),
                  fontSize: screenWidth * 0.03,
                ),
              ),
            ),
            Positioned(
              left: screenWidth * 0.8 * 0.8, // 80%의 위치
              bottom: -screenHeight * 0.025,
              child: Text(
                '80%',
                style: TextStyle(
                  color: Color(0xFF007AFF),
                  fontSize: screenWidth * 0.03,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: screenHeight * 0.1),
        Text(
          '오늘의 학습 진도율은 80% 입니다.\n오늘 하루 수고하셨습니다',
          style: TextStyle(
            color: Color(0xFF007AFF),
            fontSize: screenWidth * 0.04,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget buildBottomButtons(BoxConstraints constraints) {
    double screenWidth = constraints.maxWidth;
    double screenHeight = constraints.maxHeight;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: screenHeight * 0.02,
      ),
      decoration: BoxDecoration(
        color: Color(0xFFFAFAFA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(screenWidth * 0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, -1),
            blurRadius: 5,
          ),
        ],
      ),
      child: _currentPage == _pages.length - 1
          ? Center(
              child: ElevatedButton(
                onPressed: _completeOnboarding,
                child: Text('시작하기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.04),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.08,
                    vertical: screenHeight * 0.015,
                  ),
                ),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    'SKIP',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: screenWidth * 0.04,
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.25),
                ElevatedButton(
                  onPressed: () => _pageController.nextPage(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                  child: Text('NEXT'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.04),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.08,
                      vertical: screenHeight * 0.01,
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

  Widget buildCameraOption(String text, bool isSelected, double screenWidth) {
    return Text(
      text,
      style: TextStyle(
        color: isSelected ? Colors.yellow : Colors.white,
        fontSize: screenWidth * 0.025,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget buildZoomOption(String text, double size, double screenHeight) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withOpacity(0.3),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: size == screenHeight * 0.07 ? size * 0.4 : size * 0.5,
            fontWeight: FontWeight.bold,
          ),
        ),
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