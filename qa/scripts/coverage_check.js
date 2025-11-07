const fs = require('fs');
const path = process.argv[2];
const min = parseFloat(process.argv[3] || '60');
if (!fs.existsSync(path)) {
  console.error('lcov not found:', path);
  process.exit(1);
}
const txt = fs.readFileSync(path, 'utf8');
let pct = 0;
const m = txt.match(/\nTN:.*?\nLF:(\d+)\nLH:(\d+)/);
if (m) {
  const lf = parseFloat(m[1]);
  const lh = parseFloat(m[2]);
  pct = lf ? (lh / lf) * 100 : 0;
} else {
  const lines = Array.from(txt.matchAll(/DA:\d+,\d+/g)).length;
  const hits = Array.from(txt.matchAll(/DA:\d+,([1-9]\d*)/g)).length;
  pct = lines ? (hits / lines) * 100 : 0;
}
console.log(`Coverage: ${pct.toFixed(2)}% (min ${min}%)`);
if (pct < min) process.exit(2);

