const express = require('express');
const bodyParser = require('body-parser');
const axios = require('axios');
const multer = require('multer');
const fs = require('fs');
require('dotenv').config(); // .env 파일에서 API 키를 읽어오기 위해

const app = express();
const port = 3000;

// Google Cloud Vision API 키를 직접 설정합니다.
const GOOGLE_CLOUD_VISION_API_KEY = 'AIzaSyAw0TRhRWxqy3QxPSyq3Vufi5KDorPRCxo';

app.use(bodyParser.json());
const upload = multer({ dest: 'uploads/' });

// Answer 요청 (GPT-4 사용)
app.post('/answer', async (req, res) => {
  console.log('답변 요청을 받았습니다:', req.body);
  const { question } = req.body;

  try {
    const response = await axios.post('https://api.openai.com/v1/chat/completions', {
      model: 'gpt-4', // gpt-4 또는 gpt-4-turbo 모델 사용
      messages: [
        { role: 'system', content: '당신은 시각 장애인의 일본어 학습을 돕기 위해 설계된 AI입니다. TTS 출력에 적합한 형식으로 응답을 제공하십시오.' }, // 시스템 메시지
        { role: 'user', content: `다음 질문에 한국어로 답변해 주세요: ${question}` }  // 사용자 요청 메시지
      ],
      temperature: 0.7,
    }, {
      headers: {
        'Authorization': `Bearer ${process.env.OPENAI_API_KEY}`,
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

// 사진 업로드 요청 처리
app.post('/upload', upload.single('picture'), async (req, res) => {
  console.log('사진 업로드 요청을 받았습니다:', req.file);

  try {
    const image = fs.readFileSync(req.file.path, { encoding: 'base64' });

    const response = await axios.post(`https://vision.googleapis.com/v1/images:annotate?key=${GOOGLE_CLOUD_VISION_API_KEY}`, {
      requests: [
        {
          image: {
            content: image,
          },
          features: [
            {
              type: 'LABEL_DETECTION',
              maxResults: 10,
            },
          ],
        },
      ],
    });

    const labels = response.data.responses[0].labelAnnotations.map(label => label.description).join(', ');
    res.json({ answer: `이 사진에는 다음과 같은 항목들이 있습니다: ${labels}` });

    // 업로드된 파일 삭제
    fs.unlinkSync(req.file.path);
  } catch (error) {
    console.error('사진 처리 실패:', error.response ? error.response.data : error.message);
    res.status(500).send('사진 처리 실패');
  }
});

app.listen(port, () => {
  console.log(`서버가 http://localhost:${port} 에서 실행 중입니다`);
});