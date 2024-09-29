const express = require('express');
const bodyParser = require('body-parser');
const axios = require('axios');
require('dotenv').config(); // .env 파일에서 API 키를 읽어오기 위해

const app = express();
const port = 3000;

// 환경 변수에서 OpenAI API 키를 가져옵니다. .env 파일에 OPENAI_API_KEY=<your_key> 추가 필요
const OPENAI_API_KEY = process.env.OPENAI_API_KEY;

app.use(bodyParser.json());

// Translate 요청 (GPT-4 사용)
app.post('/translate', async (req, res) => {
  console.log('Translate request received:', req.body);
  const { text } = req.body;

  try {
    const response = await axios.post('https://api.openai.com/v1/chat/completions', {
      model: 'gpt-4', // gpt-4 또는 gpt-4-turbo 모델 사용
      messages: [
        { role: 'system', content: 'You are a helpful assistant that translates text.' }, // 시스템 메시지
        { role: 'user', content: `Translate the following text to Japanese: ${text}` }  // 사용자 요청 메시지
      ],
      max_tokens: 60,
      temperature: 0.7,
    }, {
      headers: {
        'Authorization': `Bearer ${OPENAI_API_KEY}`,
        'Content-Type': 'application/json'
      }
    });

    const translatedText = response.data.choices?.[0]?.message?.content?.trim(); // 응답 데이터 처리
    if (translatedText) {
      res.json({ translatedText });
    } else {
      res.status(500).send('Translation failed: No response data');
    }
    
  } catch (error) {
    console.error('Translation failed:', error.response ? error.response.data : error.message);
    res.status(500).send('Translation failed');
  }
});

// Feedback 요청 (GPT-4 사용)
app.post('/feedback', async (req, res) => {
  console.log('Feedback request received:', req.body);
  const { text } = req.body;

  try {
    const response = await axios.post('https://api.openai.com/v1/chat/completions', {
      model: 'gpt-4', // gpt-4 또는 gpt-4-turbo 모델 사용
      messages: [
        { role: 'system', content: 'You are a helpful assistant that provides feedback on pronunciation.' }, // 시스템 메시지
        { role: 'user', content: `Provide feedback on the pronunciation of the following Japanese text: ${text}` }  // 사용자 요청 메시지
      ],
      max_tokens: 60,
      temperature: 0.7,
    }, {
      headers: {
        'Authorization': `Bearer ${OPENAI_API_KEY}`,
        'Content-Type': 'application/json'
      }
    });

    const feedback = response.data.choices?.[0]?.message?.content?.trim(); // 응답 데이터 처리
    if (feedback) {
      res.json({ feedback });
    } else {
      res.status(500).send('Feedback failed: No response data');
    }
    
  } catch (error) {
    console.error('Feedback generation failed:', error.response ? error.response.data : error.message);
    res.status(500).send('Feedback generation failed');
  }
});

app.listen(port, () => {
  console.log(`Server is running on http://localhost:${port}`);
});