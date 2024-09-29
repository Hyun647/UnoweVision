const express = require('express');
const bodyParser = require('body-parser');
const jwt = require('jsonwebtoken');
const { Sequelize, DataTypes } = require('sequelize');
const axios = require('axios');

const app = express();
const port = 3000;

app.use(bodyParser.json());

const sequelize = new Sequelize('database', 'username', 'password', {
  host: 'localhost',
  dialect: 'mysql'
});

const User = sequelize.define('User', {
  username: {
    type: DataTypes.STRING,
    allowNull: false
  },
  password: {
    type: DataTypes.STRING,
    allowNull: false
  }
});

app.post('/login', async (req, res) => {
  const { username, password } = req.body;
  const user = await User.findOne({ where: { username, password } });
  if (user) {
    const token = jwt.sign({ id: user.id }, 'your_jwt_secret');
    res.json({ token });
  } else {
    res.status(401).send('Invalid credentials');
  }
});

app.post('/translate', async (req, res) => {
  const { text } = req.body;
  try {
    const response = await axios.post('https://translation.googleapis.com/language/translate/v2', {
      q: text,
      target: 'ja',
      format: 'text'
    }, {
      headers: {
        'Authorization': `Bearer YOUR_GOOGLE_CLOUD_API_KEY`
      }
    });
    res.json({ translatedText: response.data.data.translations[0].translatedText });
  } catch (error) {
    res.status(500).send('Translation failed');
  }
});

app.post('/feedback', async (req, res) => {
  const { text } = req.body;
  // 여기에 발음 피드백 로직을 추가합니다.
  // 예를 들어, 머신러닝 모델을 사용하여 발음 피드백을 제공할 수 있습니다.
  // 여기서는 간단한 예제로 대체합니다.
  const feedback = `Your pronunciation of "${text}" is good.`;
  res.json({ feedback });
});

app.listen(port, () => {
  console.log(`Server is running on http://localhost:${port}`);
});