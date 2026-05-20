const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = Number(process.env.PORT) || 3000;
const DATA_DIR = path.join(__dirname, 'data');
const DATA_FILE = path.join(DATA_DIR, 'health-data.json');

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

function buildRecord(dateKey, payload, existing) {
  const fallback = existing || {};
  return {
    date: dateKey,
    steps: toNumber(payload.steps, fallback.steps),
    stepGoal: toNumber(payload.stepGoal, fallback.stepGoal),
    waterIntake: toNumber(payload.waterIntake, fallback.waterIntake),
    waterGoal: toNumber(payload.waterGoal, fallback.waterGoal),
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
  const userData = store.users[userId] || {};
  const record = userData[dateKey] || null;
  return res.json({ data: record });
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
  const userData = store.users[userId] || {};
  const records = [];

  const cursor = new Date(startDate);
  cursor.setHours(0, 0, 0, 0);
  const end = new Date(endDate);
  end.setHours(0, 0, 0, 0);

  while (cursor <= end) {
    const key = formatDate(cursor);
    if (userData[key]) {
      records.push(userData[key]);
    }
    cursor.setDate(cursor.getDate() + 1);
  }

  return res.json({ data: records });
});

app.get('/health/dates', (req, res) => {
  const startKey = normalizeDateKey(req.query.startDate);
  const endKey = normalizeDateKey(req.query.endDate);
  const userId = getUserId(req);

  const store = loadStore();
  const userData = store.users[userId] || {};
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

app.listen(PORT, () => {
  console.log(`Health server listening on http://localhost:${PORT}`);
});
