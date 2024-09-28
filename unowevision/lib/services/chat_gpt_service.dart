import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatGptService {
  final String apiKey = '';

  Future<String> getJapaneseLearningResponse(String prompt) async {
    print('Sending request to OpenAI API...');
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o',
        'messages': [
          {'role': 'system', 'content': '이 시스템은 시각장애인을 위해 일본어 학습을 돕는 역할을 수행합니다. 답변은 TTS 친화적 형식으로 제공되며, 일본어와 한국어를 모두 사용하여 답변을 제공합니다. 또한, 한국어로 일본어 발음을 설명해 주세요. 모든 답변은 존댓말로 이루어져야 합니다.'},
          {'role': 'user', 'content': '질문: $prompt\n답변:'},
        ],
      }),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['choices'][0]['message']['content'].trim();
    } else {
      print('Failed to load response: ${response.statusCode} ${response.body}');
      throw Exception('Failed to load response');
    }
  }
}

