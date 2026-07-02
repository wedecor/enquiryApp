#!/usr/bin/env tsx
/**
 * GATE A fallback backup: dump enquiries and users to local JSON.
 *
 * Usage:
 *   npx tsx scripts/migrations/export_backup.ts
 */

import "dotenv/config";
import fs from "node:fs";
import path from "node:path";
import { db } from "../../src/lib/firebaseAdmin.js";

const firestore = db();
const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
const backupDir = path.join("backups", timestamp);

async function dumpCollection(name: string): Promise<number> {
  const snapshot = await firestore.collection(name).get();
  const docs = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  fs.writeFileSync(path.join(backupDir, `${name}.json`), JSON.stringify(docs, null, 2));
  return docs.length;
}

async function main() {
  fs.mkdirSync(backupDir, { recursive: true });
  const enquiries = await dumpCollection("enquiries");
  const users = await dumpCollection("users");
  console.log(`Backup written to ${backupDir}`);
  console.log(`enquiries: ${enquiries}, users: ${users}`);
}

main().catch((error) => {
  console.error("Backup export failed:", error);
  process.exit(1);
});
