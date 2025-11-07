import fs from "node:fs";
import path from "node:path";

const p = path.join(".github", "workflows", "seed.yml");
let ok = true;

function fail(msg: string) {
  console.error("❌", msg);
  ok = false;
}

function tip(msg: string) {
  console.log("💡", msg);
}

if (!fs.existsSync(p)) {
  fail(`Workflow file not found at ${p}`);
} else {
  const y = fs.readFileSync(p, "utf8");
  if (!/name:\s*Seed Firestore \(WeDecor\)/.test(y)) {
    fail(`Workflow 'name' missing or different. Expected: Seed Firestore (WeDecor)`);
  }
  if (!/workflow_dispatch:/.test(y)) {
    fail(`'workflow_dispatch' trigger missing. The Run workflow button won't appear.`);
  }
  if (!/admin_uid:/.test(y)) {
    fail(`Input 'admin_uid' missing under workflow_dispatch.`);
  }
}

if (!ok) {
  tip("Commit this file on the DEFAULT branch (main/master). If not default, merge it to default.");
  tip("Then: push, refresh GitHub Actions tab, or make a tiny commit to re-index.");
  process.exit(1);
}

console.log("✅ Workflow file looks good.");
console.log("Next:");
console.log("1) Repo → Settings → Secrets → Actions → add repository [REDACTED] GOOGLE_CREDENTIALS (service account JSON).");
console.log('2) Actions → Seed Firestore (WeDecor) → Run workflow → enter admin_uid (your Firebase [REDACTED] UID).');

