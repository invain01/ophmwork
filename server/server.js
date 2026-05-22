const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

function loadDotEnv(filePath) {
  if (!fs.existsSync(filePath)) {
    return;
  }

  const content = fs.readFileSync(filePath, 'utf-8');
  const lines = content.split(/\r?\n/);
  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) {
      continue;
    }

    const equalsIndex = trimmed.indexOf('=');
    if (equalsIndex < 0) {
      continue;
    }

    const key = trimmed.slice(0, equalsIndex).trim();
    const value = trimmed.slice(equalsIndex + 1).trim();
    if (key && !process.env[key]) {
      process.env[key] = value;
    }
  }
}

loadDotEnv(path.join(__dirname, '.env'));

const app = express();
const PORT = Number(process.env.PORT) || 3000;
const DATA_DIR = path.join(__dirname, 'data');
const DATA_FILE = path.join(DATA_DIR, 'health-data.json');
const OPENAI_API_URL = process.env.OPENAI_API_URL || 'https://api.openai.com/v1/chat/completions';
const OPENAI_API_KEY = process.env.OPENAI_API_KEY || '';
const OPENAI_MODEL = process.env.OPENAI_MODEL || 'gpt-4o-mini';

function normalizeOpenAIUrl(value) {
  const raw = typeof value === 'string' ? value.trim() : '';
  if (!raw) {
    return 'https://api.openai.com/v1/chat/completions';
  }

  if (/\/chat\/completions\/?$/i.test(raw) || /\/responses\/?$/i.test(raw)) {
    return raw;
  }

  if (/\/v1\/?$/i.test(raw)) {
    return `${raw.replace(/\/+$/, '')}/chat/completions`;
  }

  if (/^https?:\/\/[^\s/]+$/i.test(raw)) {
    return `${raw}/v1/chat/completions`;
  }

  return raw.replace(/\/+$/, '');
}

const OPENAI_REQUEST_URL = normalizeOpenAIUrl(OPENAI_API_URL);

app.use(cors());
app.use(express.json({ limit: '1mb' }));

function ensureStore() {
  if (!fs.existsSync(DATA_DIR)) {
    fs.mkdirSync(DATA_DIR, { recursive: true });
  }
  if (!fs.existsSync(DATA_FILE)) {
    fs.writeFileSync(DATA_FILE, JSON.stringify({ users: {} }, null, 2));
  }
}

function loadStore() {
  ensureStore();
  try {
    const raw = fs.readFileSync(DATA_FILE, 'utf-8');
    const parsed = JSON.parse(raw);
    if (!parsed || typeof parsed !== 'object') {
      return { users: {} };
    }
    if (!parsed.users || typeof parsed.users !== 'object') {
      parsed.users = {};
    }
    return parsed;
  } catch (error) {
    return { users: {} };
  }
}

function saveStore(store) {
  ensureStore();
  fs.writeFileSync(DATA_FILE, JSON.stringify(store, null, 2));
}

function isValidDateKey(value) {
  return typeof value === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(value);
}

function pad2(value) {
  return String(value).padStart(2, '0');
}

function formatDate(date) {
  const year = date.getFullYear();
  const month = pad2(date.getMonth() + 1);
  const day = pad2(date.getDate());
  return `${year}-${month}-${day}`;
}

function parseDateKey(value) {
  if (!isValidDateKey(value)) {
    return null;
  }
  const [year, month, day] = value.split('-').map(Number);
  const date = new Date(year, month - 1, day);
  if (Number.isNaN(date.getTime())) {
    return null;
  }
  return date;
}

function normalizeDateKey(value) {
  if (isValidDateKey(value)) {
    return value;
  }
  if (typeof value !== 'string' || value.length === 0) {
    return null;
  }
  const match = value.match(/(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})/);
  if (match) {
    const year = match[1];
    const month = pad2(match[2]);
    const day = pad2(match[3]);
    return `${year}-${month}-${day}`;
  }
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    return null;
  }
  return formatDate(parsed);
}

function toNumber(value, fallback) {
  const parsed = Number(value);
  if (Number.isFinite(parsed)) {
    return parsed;
  }
  if (Number.isFinite(fallback)) {
    return fallback;
  }
  return 0;
}

function normalizeWeight(value, fallback) {
  let weight = toNumber(value, fallback);
  if (!Number.isFinite(weight) || weight <= 0) {
    return 0;
  }
  while (weight >= 300) {
    weight = weight / 10;
  }
  return Math.round(weight * 10) / 10;
}

function getUserId(req) {
  const userId = req.query.userId || req.body.userId || 'user_001';
  return String(userId);
}

function getUserStore(store, userId) {
  if (!store.users[userId]) {
    store.users[userId] = {};
  }
  return store.users[userId];
}

function getReadableUserStore(store, userId) {
  if (store.users[userId]) {
    return store.users[userId];
  }
  const keys = Object.keys(store.users);
  if (keys.length > 0) {
    return store.users[keys[0]];
  }
  return {};
}

function normalizeAssistantHistory(history) {
  if (!Array.isArray(history)) {
    return [];
  }

  const messages = [];
  for (const item of history.slice(-12)) {
    if (!item || typeof item !== 'object') {
      continue;
    }
    const role = item.role === 'assistant' ? 'assistant' : 'user';
    const content = typeof item.content === 'string' ? item.content.trim() : '';
    if (!content) {
      continue;
    }
    messages.push({ role, content });
  }
  return messages;
}

function buildAssistantMessages(message, history) {
  const messages = [
    {
      role: 'system',
      content: '你是一名中文健康助手。你要给出清晰、简洁、可执行的健康建议，但不能代替医生诊断。遇到胸痛、呼吸困难、昏厥、持续高烧、剧烈疼痛或其他紧急症状时，必须立即建议用户尽快就医或呼叫急救。优先给出安全、温和、非药物的日常建议。'
    }
  ];
  messages.push(...normalizeAssistantHistory(history));
  messages.push({ role: 'user', content: message });
  return messages;
}

function buildFallbackReply(message) {
  const trimmed = typeof message === 'string' ? message.trim() : '';
  if (!trimmed) {
    return '请先告诉我你的健康问题，我会尽量给出可执行的日常建议。';
  }
  return '当前健康助手暂时未连接到 GPT API。我可以先给你一个通用建议：把问题拆成饮食、运动、睡眠和症状四部分，再根据最近几天的变化逐步调整。如果你有明显不适，请优先就医。';
}

function extractAssistantReply(payload) {
  if (!payload || typeof payload !== 'object') {
    return '';
  }

  const choices = payload.choices;
  if (Array.isArray(choices) && choices.length > 0) {
    const firstChoice = choices[0] || {};
    const candidateSources = [
      firstChoice.message && firstChoice.message.content,
      firstChoice.delta && firstChoice.delta.content,
      firstChoice.text,
      firstChoice.content
    ];
    for (const candidate of candidateSources) {
      if (typeof candidate === 'string' && candidate.trim()) {
        return candidate.trim();
      }
    }
  }

  const directCandidates = [
    payload.reply,
    payload.message,
    payload.content,
    payload.result,
    payload.output_text,
    payload.answer,
    payload.data && payload.data.reply,
    payload.data && payload.data.message,
    payload.data && payload.data.content,
    payload.data && payload.data.result
  ];

  for (const candidate of directCandidates) {
    if (typeof candidate === 'string' && candidate.trim()) {
      return candidate.trim();
    }
  }

  if (payload.error) {
    if (typeof payload.error === 'string' && payload.error.trim()) {
      return payload.error.trim();
    }
    if (payload.error.message && typeof payload.error.message === 'string' && payload.error.message.trim()) {
      return payload.error.message.trim();
    }
  }

  if (payload.msg && typeof payload.msg === 'string' && payload.msg.trim()) {
    return payload.msg.trim();
  }

  return '';
}

async function callOpenAI(message, history) {
  const apiKey = OPENAI_API_KEY.trim();
  if (!apiKey || apiKey === '请在这里明文填写你的 OpenAI API Key') {
    return { reply: buildFallbackReply(message), source: 'fallback', reason: 'OPENAI_API_KEY is not set' };
  }

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 60000);
  try {
    const response = await fetch(OPENAI_REQUEST_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${apiKey}`
      },
      body: JSON.stringify({
        model: OPENAI_MODEL,
        messages: buildAssistantMessages(message, history),
        temperature: 0.6
      }),
      signal: controller.signal
    });

    const text = await response.text();
    if (!response.ok) {
      throw new Error(`OpenAI request failed: ${response.status} ${text}`);
    }

    const payload = JSON.parse(text);
    const reply = extractAssistantReply(payload);
    if (!reply) {
      throw new Error(`OpenAI response did not contain assistant content: ${text}`);
    }

    return { reply, source: 'openai', model: OPENAI_MODEL };
  } finally {
    clearTimeout(timeoutId);
  }
}

function buildRecord(dateKey, payload, existing) {
  const fallback = existing || {};
  return {
    date: dateKey,
    steps: toNumber(payload.steps, fallback.steps),
    stepGoal: toNumber(payload.stepGoal, fallback.stepGoal),
    waterIntake: toNumber(payload.waterIntake, fallback.waterIntake),
    waterGoal: toNumber(payload.waterGoal, fallback.waterGoal),
    weight: normalizeWeight(payload.weight, fallback.weight),
    sleepHours: toNumber(payload.sleepHours, fallback.sleepHours),
    sleepGoal: toNumber(payload.sleepGoal, fallback.sleepGoal),
    heartRate: toNumber(payload.heartRate, fallback.heartRate),
    lastUpdated: typeof payload.lastUpdated === 'string'
      ? payload.lastUpdated
      : (fallback.lastUpdated || dateKey)
  };
}

app.get('/health/ping', (req, res) => {
  res.json({ status: 'ok' });
});

app.get('/health/daily', (req, res) => {
  const dateKey = normalizeDateKey(req.query.date);
  if (!dateKey) {
    return res.status(400).json({ error: 'Invalid date' });
  }
  const userId = getUserId(req);
  const store = loadStore();
  const userData = getReadableUserStore(store, userId);
  const record = userData[dateKey] || null;
  if (record) {
    const fixed = {
      ...record,
      weight: normalizeWeight(record.weight, 0)
    };
    if (fixed.weight !== record.weight) {
      userData[dateKey] = fixed;
      saveStore(store);
    }
    return res.json({ data: fixed });
  }
  return res.json({ data: null });
});

app.put('/health/daily', (req, res) => {
  const dateKey = normalizeDateKey(req.body.date);
  if (!dateKey) {
    return res.status(400).json({ error: 'Invalid date' });
  }
  const userId = getUserId(req);
  const store = loadStore();
  const userData = getUserStore(store, userId);
  const existing = userData[dateKey];
  const record = buildRecord(dateKey, req.body || {}, existing);
  userData[dateKey] = record;
  saveStore(store);
  return res.json({ data: record });
});

app.get('/health/weekly', (req, res) => {
  const startKey = normalizeDateKey(req.query.startDate);
  const endKey = normalizeDateKey(req.query.endDate);
  if (!startKey || !endKey) {
    return res.status(400).json({ error: 'Invalid date range' });
  }

  const startDate = parseDateKey(startKey);
  const endDate = parseDateKey(endKey);
  if (!startDate || !endDate || startDate > endDate) {
    return res.status(400).json({ error: 'Invalid date range' });
  }

  const userId = getUserId(req);
  const store = loadStore();
  const userData = getReadableUserStore(store, userId);
  const records = [];

  const cursor = new Date(startDate);
  cursor.setHours(0, 0, 0, 0);
  const end = new Date(endDate);
  end.setHours(0, 0, 0, 0);

  while (cursor <= end) {
    const key = formatDate(cursor);
    if (userData[key]) {
      const original = userData[key];
      const fixed = {
        ...original,
        weight: normalizeWeight(original.weight, 0)
      };
      if (fixed.weight !== original.weight) {
        userData[key] = fixed;
      }
      records.push(fixed);
    }
    cursor.setDate(cursor.getDate() + 1);
  }

  saveStore(store);

  return res.json({ data: records });
});

app.get('/health/dates', (req, res) => {
  const startKey = normalizeDateKey(req.query.startDate);
  const endKey = normalizeDateKey(req.query.endDate);
  const userId = getUserId(req);

  const store = loadStore();
  const userData = getReadableUserStore(store, userId);
  let keys = Object.keys(userData);

  if (startKey) {
    keys = keys.filter((key) => key >= startKey);
  }
  if (endKey) {
    keys = keys.filter((key) => key <= endKey);
  }

  keys.sort();
  return res.json({ data: keys });
});

app.post('/health/assistant/chat', async (req, res) => {
  const message = typeof req.body.message === 'string' ? req.body.message.trim() : '';
  if (!message) {
    return res.status(400).json({ error: 'Message is required' });
  }

  const history = normalizeAssistantHistory(req.body.history);
  try {
    const result = await callOpenAI(message, history);
    return res.json(result);
  } catch (error) {
    console.error('Health assistant error:', error);
    return res.json({
      reply: buildFallbackReply(message),
      source: 'fallback',
      reason: error && error.message ? error.message : 'assistant unavailable'
    });
  }
});

const server = app.listen(PORT, () => {
  console.log(`Health server listening on http://localhost:${PORT}`);
});

server.on('error', (error) => {
  if (error && error.code === 'EADDRINUSE') {
    console.log(`Port ${PORT} is already in use. The health server may already be running.`);
    process.exit(0);
    return;
  }
  throw error;
});
