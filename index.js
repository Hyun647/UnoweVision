const express = require('express');
const bodyParser = require('body-parser');
const axios = require('axios');
require('dotenv').config(); // .env 파일에서 API 키를 읽어오기 위해

const app = express();
const port = 3000;

// 환경 변수에서 OpenAI API 키를 가져옵니다. .env 파일에 OPENAI_API_KEY=<your_key> 추가 필요
const OPENAI_API_KEY = process.env.OPENAI_API_KEY;

app.use(bodyParser.json());

// Answer 요청 (GPT-4 사용)
app.post('/answer', async (req, res) => {
  console.log('답변 요청을 받았습니다:', req.body);
  const { question } = req.body;

  try {
    const response = await axios.post('https://api.openai.com/v1/chat/completions', {
      model: 'gpt-4', // gpt-4 또는 gpt-4-turbo 모델 사용
      messages: [
        { role: 'system', content: '당신은 시각 장애인을 돕기 위해 설계된 AI입니다. TTS 출력에 적합한 형식으로 응답을 제공하십시오.' }, // 시스템 메시지
        { role: 'user', content: `다음 질문에 한국어로 답변해 주세요: ${question}` }  // 사용자 요청 메시지
      ],
      max_tokens: 60,
      temperature: 0.7,
    }, {
      headers: {
        'Authorization': `Bearer ${OPENAI_API_KEY}`,
        'Content-Type': 'application/json'
      }
    });

    const answer = response.data.choices?.[0]?.message?.content?.trim(); // 응답 데이터 처리
    if (answer) {
      res.json({ answer });
    } else {
      res.status(500).send('답변 실패: 응답 데이터가 없습니다');
    }
    
  } catch (error) {
    console.error('답변 생성 실패:', error.response ? error.response.data : error.message);
    res.status(500).send('답변 생성 실패');
  }
});

app.listen(port, () => {
  console.log(`서버가 http://localhost:${port} 에서 실행 중입니다`);
});