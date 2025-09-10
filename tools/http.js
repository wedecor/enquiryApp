/* Minimal fetch wrapper (kept for future extensibility) */
const fetch = global.fetch || require('node-fetch');
async function post(url, body, headers = {}) {
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type':'application/json', ...headers },
    body: JSON.stringify(body),
  });
  const text = await res.text();
  let json; try { json = JSON.parse(text); } catch (_) {}
  return { ok: res.ok, status: res.status, text, json };
}
module.exports = { post };
