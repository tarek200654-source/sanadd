'use strict';

const http = require('node:http');
const { randomUUID } = require('node:crypto');

const PORT = Number(process.env.WEXORA_PROXY_PORT || 8787);
const API_BASE = 'https://wexora.pro/api/v1';
const API_KEY = process.env.WEXORA_API_KEY;
const SESSION_ID = process.env.WEXORA_SESSION_ID;
const phoneSends = new Map();
const ipRequests = new Map();

function json(response, status, value) {
  response.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Cache-Control': 'no-store',
    'X-Content-Type-Options': 'nosniff',
  });
  response.end(JSON.stringify(value));
}

function countRequest(map, key, windowMs, limit) {
  const now = Date.now();
  const recent = (map.get(key) || []).filter((stamp) => now - stamp < windowMs);
  if (recent.length >= limit) return false;
  recent.push(now);
  map.set(key, recent);
  return true;
}

async function readJson(request) {
  let raw = '';
  for await (const chunk of request) {
    raw += chunk;
    if (raw.length > 8192) throw Object.assign(new Error('Payload too large'), { status: 413 });
  }
  try {
    return JSON.parse(raw);
  } catch {
    throw Object.assign(new Error('Invalid JSON'), { status: 400 });
  }
}

async function wexora(path, { method = 'POST', body, idempotencyKey } = {}) {
  const response = await fetch(`${API_BASE}${path}`, {
    method,
    headers: {
      Authorization: `Bearer ${API_KEY}`,
      'Content-Type': 'application/json',
      ...(idempotencyKey ? { 'Idempotency-Key': idempotencyKey } : {}),
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
    signal: AbortSignal.timeout(15000),
  });
  const data = await response.json().catch(() => ({}));
  return { status: response.status, data };
}

async function handle(request, response) {
  if (request.method !== 'POST' || !['/api/otp/send', '/api/otp/verify'].includes(request.url)) {
    return json(response, 404, { code: 'not-found' });
  }
  if (!request.headers['content-type']?.toLowerCase().startsWith('application/json')) {
    return json(response, 415, { code: 'content-type-required' });
  }
  const ip = request.socket.remoteAddress || 'unknown';
  if (!countRequest(ipRequests, ip, 15 * 60_000, 20)) {
    return json(response, 429, { code: 'rate-limited' });
  }

  const body = await readJson(request);
  if (request.url === '/api/otp/send') {
    const phoneNumber = body.phoneNumber;
    if (typeof phoneNumber !== 'string' || !/^\+[1-9]\d{7,14}$/.test(phoneNumber)) {
      return json(response, 400, { code: 'invalid-phone' });
    }
    const sends = phoneSends.get(phoneNumber) || [];
    const recent = sends.filter((stamp) => Date.now() - stamp < 15 * 60_000);
    if (recent.length >= 3 || (recent.length && Date.now() - recent.at(-1) < 60_000)) {
      phoneSends.set(phoneNumber, recent);
      return json(response, 429, { code: 'rate-limited' });
    }
    const result = await wexora('/otp', {
      idempotencyKey: `sanad-otp-${randomUUID()}`,
      body: {
        session_id: SESSION_ID,
        to: phoneNumber,
        purpose: 'sanad_signup',
        reference: `sanad:${randomUUID()}`,
        language: body.language === 'ar' ? 'ar' : 'en',
      },
    });
    if (result.status !== 202 || typeof result.data.id !== 'string' || typeof result.data.expires_at !== 'string') {
      const code = result.status === 429 ? 'rate-limited' : 'wexora-send-failed';
      return json(response, result.status >= 400 ? result.status : 502, { code });
    }
    recent.push(Date.now());
    phoneSends.set(phoneNumber, recent);
    const expiry = new Date(`${result.data.expires_at.replace(' ', 'T')}Z`);
    return json(response, 200, {
      challengeId: result.data.id,
      expiresAt: Number.isNaN(expiry.getTime()) ? result.data.expires_at : expiry.toISOString(),
    });
  }

  const challengeId = body.challengeId;
  const code = body.code;
  if (typeof challengeId !== 'string' || !/^[a-f0-9]{32}$/.test(challengeId)
      || typeof code !== 'string' || !/^\d{6}$/.test(code)) {
    return json(response, 400, { code: 'invalid-code' });
  }
  const result = await wexora(`/otp/${challengeId}/verify`, { body: { code } });
  if (result.status === 422 && result.data.verified === false) {
    return json(response, 200, { verified: false });
  }
  if (result.status !== 200 || typeof result.data.verified !== 'boolean') {
    const code = result.status === 404 ? 'not-found'
      : result.status === 429 ? 'rate-limited'
      : 'wexora-verify-failed';
    return json(response, result.status >= 400 ? result.status : 502, { code });
  }
  return json(response, 200, { verified: result.data.verified === true });
}

if (!API_KEY || !SESSION_ID) {
  console.error('Set WEXORA_API_KEY and WEXORA_SESSION_ID before starting this server.');
  process.exit(1);
}

http.createServer((request, response) => {
  handle(request, response).catch((error) => {
    if (!response.headersSent) json(response, error.status || 503, { code: error.status ? 'invalid-request' : 'wexora-unavailable' });
  });
}).listen(PORT, '0.0.0.0', () => {
  console.log(`Wexora OTP proxy listening on port ${PORT}`);
});
