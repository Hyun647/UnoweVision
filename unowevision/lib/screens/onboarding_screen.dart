import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            physics: ClampingScrollPhysics(),
            onPageChanged: (int page) => setState(() => _currentPage = page),
            itemBuilder: (context, index) => buildPageContent(_pages[index], index),
          ),
          Positioned(
            top: 70,
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

  Widget buildPageContent(OnboardingPage page, int index) {
    return Container(
      color: Color(0xFFFAFAFA),
      padding: EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(height: 100), // 120에서 100으로 줄임
          Text(
            page.title,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10), // 20에서 10으로 줄임
          Text(
            page.description,
            style: TextStyle(fontSize: 13),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10), // 새로 추가한 SizedBox
          Expanded(
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Image.asset(
                  page.image,
                  fit: BoxFit.contain,
                  width: double.infinity,
                ),
                if (index != 1) // Unowe 텍스트를 2번째 페이지에서 제외
                  Positioned(
                    top: 80,
                    left: 0,
                    right: 0,
                    child: Text(
                      'Unowe',
                      style: TextStyle(
                        color: Color(0xFF007AFF),
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (index == 1) // 2번째 페이지에 카메라 UI 추가
                  Positioned(
                    top: 10,
                    child: Column(
                      children: [
                        Container(
                          width: 252, // onboardingphone 이미지 너비에 맞춤
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(35),
                              topRight: Radius.circular(35),
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                left: 25, // 왼쪽에서 오른쪽으로 변경
                                top: 25, // 0에서 22로 변경하여 아이콘을 아래로 내림
                                child: Container(
                                  width: 15, // 22에서 18로 줄임
                                  height: 15, // 22에서 18로 줄임
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.transparent, // 배경색을 투명하게
                                    border: Border.all(color: Colors.white, width: 1), // 테두리 두께를 1.5에서 1로 줄임
                                  ),
                                  child: Icon(
                                    Icons.flash_off,
                                    color: Colors.white,
                                    size: 12, // 크기 유지
                                  ),
                                ),
                              ),
                              Center(
                                child: Padding(
                                  padding: EdgeInsets.only(top: 10), // 위쪽 패딩 추가
                                  child: Icon(
                                    Icons.keyboard_arrow_up, // arrow_upward에서 keyboard_arrow_up으로 변경
                                    color: Colors.white,
                                    size: 24, // 크기를 30에서 24로 줄임
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 25,
                                top: 27, // 20에서 24로 변경하여 아래로 내림
                                child: Image.asset(
                                  'assets/images/Live.png',
                                  height: 16, // 20에서 16으로 줄임
                                ),
                              ),
                              Positioned(
                                top: 10,
                                right: 88, // 중앙에서 살짝 오른쪽으로 이동
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 252, // onboardingphone 이미지 너비에 맞춤
                          height: MediaQuery.of(context).size.height * 0.54,
                          child: Stack(
                            children: [
                              Image.asset(
                                'assets/images/cameraeximg.png',
                                fit: BoxFit.cover, // fill에서 cover로 변경
                                width: 252, // 너비를 명시적으로 지정
                                height: double.infinity,
                              ),
                              Positioned(
                                bottom: 25, // 20에서 25로 변경하여 전체적으로 위로 올림
                                left: 0,
                                right: 0,
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        buildZoomOption('.5', 20), // 크기를 30에서 25로 줄임
                                        SizedBox(width: 15),
                                        buildZoomOption('1x', 27), // 크기 유지
                                        SizedBox(width: 15),
                                        buildZoomOption('3', 20), // 크기를 30에서 25로 줄임
                                      ],
                                    ),
                                    SizedBox(height: 12), // 10에서 12로 변경하여 간격 조절
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        buildCameraOption('슬로 모션', false),
                                        buildCameraOption('비디오', false),
                                        buildCameraOption('사진', true),
                                        buildCameraOption('인물 사진', false),
                                        buildCameraOption('파노라마', false),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                bottom: MediaQuery.of(context).size.height * 0.15, // 0.2에서 0.18로 변경
                                right: 50, // 60에서 55로 변경
                                child: Image.asset(
                                  'assets/images/focus.png',
                                  width: 80, // 이미지 크기 조정
                                  height: 80,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                if (index == 0 || index == 2)
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.169,
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/waitingimg.gif',
                          width: 210,
                          height: 210,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(height: 6),
                        Text(
                          index == 2
                              ? '콘니치아 보다 곤니찌와로\n발음하는 것이 좋을 것 같아요!'
                              : '환영합니다.\n무엇을 도와드릴까요?',
                          style: TextStyle(
                            color: Color(0xFF007AFF),
                            fontSize: 16, // 18에서 16으로 줄임
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                if (index == 3) // 4번째 페이지에 진도율 그래프 추가
                  Positioned(
                    top: 150, // Unowe 글자 아래로 위치 조정
                    left: 40,
                    right: 40,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '2024년 10월 1일',
                          style: TextStyle(
                            color: Color(0xFF007AFF),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Stack(
                          children: [
                            Container(
                              height: 10,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: LinearProgressIndicator(
                                  value: 0.8,
                                  backgroundColor: Colors.grey[300],
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              top: 0,
                              bottom: 0,
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 50,
                                    child: Container(),
                                  ),
                                  Container(
                                    width: 2,
                                    color: Colors.white,
                                  ),
                                  Expanded(
                                    flex: 50,
                                    child: Container(),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              left: 0,
                              bottom: -20,
                              child: Text(
                                '0%',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: -20,
                              child: Text(
                                '80%',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
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
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Color(0xFFFAFAFA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
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
                onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                child: Text('시작하기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                ),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                  child: Text(
                    'SKIP',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 16,
                    ),
                  ),
                ),
                SizedBox(width: 100),
                ElevatedButton(
                  onPressed: () {
                    _pageController.nextPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Text('NEXT'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  ),
                ),
              ],
            ),
    );
  }

  Widget buildCameraOption(String text, bool isSelected) {
    return Text(
      text,
      style: TextStyle(
        color: isSelected ? Colors.yellow : Colors.white,
        fontSize: 10,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget buildZoomOption(String text, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withOpacity(0.3), // 0.5에서 0.3으로 변경하여 더 투명하게 만듦
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: size == 27 ? 12 : 10, // 1x는 글자 크기 유지, 나머지는 작게
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