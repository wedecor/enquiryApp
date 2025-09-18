import "dotenv/config";
import { db } from "../src/lib/firebaseAdmin.js";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { DropdownItemSchema, EnquirySchema, HistorySchema, UserSchema } from "../src/types/firestore.js";

const firestore = db();

const STATUSES = [
  { value: "new",          label: "New",           order: 1, active: true, color: "#9E9E9E" },
  { value: "in_progress",  label: "In Progress",   order: 2, active: true, color: "#2196F3" },
  { value: "quote_sent",   label: "Quote Sent",    order: 3, active: true, color: "#9C27B0" },
  { value: "approved",     label: "Approved",      order: 4, active: true, color: "#4CAF50" },
  { value: "scheduled",    label: "Scheduled",     order: 5, active: true, color: "#03A9F4" },
  { value: "completed",    label: "Completed",     order: 6, active: true, color: "#607D8B" },
  { value: "cancelled",    label: "Cancelled",     order: 7, active: true, color: "#F44336" },
  { value: "closed_lost",  label: "Closed Lost",   order: 8, active: true, color: "#795548" }
];

const EVENT_TYPES = [
  { value: "wedding",          label: "Wedding",          order: 1, active: true, color: "#E91E63" },
  { value: "birthday",         label: "Birthday",         order: 2, active: true, color: "#FF9800" },
  { value: "corporate_event",  label: "Corporate Event",  order: 3, active: true, color: "#3F51B5" },
  { value: "haldi",            label: "Haldi",            order: 4, active: true, color: "#FFC107" },
  { value: "anniversary",      label: "Anniversary",      order: 5, active: true, color: "#9C27B0" },
  { value: "others",           label: "Others",           order: 6, active: true, color: "#9E9E9E" }
];

const PRIORITIES = [
  { value: "low",     label: "Low",     order: 1, active: true, color: "#8BC34A" },
  { value: "medium",  label: "Medium",  order: 2, active: true, color: "#FFC107" },
  { value: "high",    label: "High",    order: 3, active: true, color: "#FF5722" },
  { value: "urgent",  label: "Urgent",  order: 4, active: true, color: "#F44336" }
];

const PAYMENT_STATUSES = [
  { value: "pending",  label: "Pending",  order: 1, active: true, color: "#FFC107" },
  { value: "partial",  label: "Partial",  order: 2, active: true, color: "#03A9F4" },
  { value: "paid",     label: "Paid",     order: 3, active: true, color: "#4CAF50" },
  { value: "overdue",  label: "Overdue",  order: 4, active: true, color: "#F44336" }
];

type Count = { written: number; skipped: number; };
const counts: Record<string, Count> = {
  dropdowns: { written: 0, skipped: 0 },
  users: { written: 0, skipped: 0 },
  enquiries: { written: 0, skipped: 0 },
  history: { written: 0, skipped: 0 }
};

const nowTS = () => FieldValue.serverTimestamp();

async function upsertDropdown(group: string, items: any[]) {
  for (const item of items) {
    const parsed = DropdownItemSchema.safeParse(item);
    if (!parsed.success) {
      console.error(`[DROP:${group}] INVALID`, item.value, parsed.error.flatten().fieldErrors);
      counts.dropdowns.skipped++;
      continue;
    }
    const ref = firestore.doc(`dropdowns/${group}/items/${item.value}`);
    await ref.set({ ...item, createdAt: nowTS(), updatedAt: nowTS() }, { merge: true });
    counts.dropdowns.written++;
    console.log(`[DROP:${group}] upsert -> ${ref.path}`);
  }
}

async function upsertAdminUser() {
  const ADMIN_UID = process.env.ADMIN_UID?.trim();
  if (!ADMIN_UID) throw new Error("ADMIN_UID missing in env");

  const payload = {
    uid: ADMIN_UID,
    name: "Admin User",
    email: "admin@wedecor.com",
    phone: "+91 9591232166",
    role: "admin" as const,
  };

  const parsed = UserSchema.safeParse(payload);
  if (!parsed.success) throw new Error(`Admin user invalid: ${parsed.error.message}`);

  const ref = firestore.doc(`users/${ADMIN_UID}`);
  await ref.set({ ...payload, createdAt: nowTS(), updatedAt: nowTS() }, { merge: true });
  counts.users.written++;
  console.log(`[USER] upsert -> ${ref.path}`);
  return ADMIN_UID;
}

async function createSampleEnquiry(ADMIN_UID: string) {
  // Uniqueness by phone + source
  const q = await firestore.collection("enquiries")
    .where("customerPhone", "==", "8880888832")
    .where("source", "==", "app")
    .limit(1)
    .get();

  if (!q.empty) {
    counts.enquiries.skipped++;
    const doc = q.docs[0];
    console.log(`[ENQ] exists -> ${doc.ref.path}`);
    return doc.ref.id;
  }

  const payload = {
    customerName: "Sample Customer",
    customerPhone: "8880888832",
    customerEmail: "sample@example.com",

    eventType: "wedding" as const,
    eventDate: nowTS(),
    eventLocation: "Bangalore",
    guestCount: 100,
    budgetRange: "50000-100000",
    description: "Beautiful wedding decoration",

    eventStatus: "new" as const,
    paymentStatus: "pending" as const,
    priority: "medium" as const,

    source: "app",
    assignedTo: null,
    createdBy: ADMIN_UID,

    totalCost: null,
    advancePaid: null
  };

  const parsed = EnquirySchema.safeParse(payload);
  if (!parsed.success) {
    throw new Error(`Sample enquiry invalid: ${parsed.error.message}`);
  }

  const ref = await firestore.collection("enquiries").add({
    ...payload,
    createdAt: nowTS(),
    updatedAt: nowTS()
  });

  counts.enquiries.written++;
  console.log(`[ENQ] create -> ${ref.path}`);
  return ref.id;
}

async function createInitialHistory(enquiryId: string, ADMIN_UID: string) {
  const histCol = firestore.collection(`enquiries/${enquiryId}/history`);
  const existing = await histCol.where("field_changed", "==", "eventStatus").where("new_value", "==", "new").limit(1).get();
  if (!existing.empty) {
    counts.history.skipped++;
    console.log(`[HIST] exists -> enquiries/${enquiryId}/history/${existing.docs[0].id}`);
    return;
  }

  const payload = {
    field_changed: "eventStatus",
    old_value: null,
    new_value: "new",
    user_id: ADMIN_UID,
    user_email: "admin@wedecor.com",
  };

  const parsed = HistorySchema.safeParse(payload);
  if (!parsed.success) throw new Error(`History invalid: ${parsed.error.message}`);

  const ref = await histCol.add({ ...payload, timestamp: nowTS() });
  counts.history.written++;
  console.log(`[HIST] create -> ${ref.path}`);
}

async function main() {
  console.log("🚀 == WeDecor Firestore Seeder ==");
  
  console.log("\n📋 Creating dropdown collections...");
  await upsertDropdown("statuses", STATUSES);
  await upsertDropdown("event_types", EVENT_TYPES);
  await upsertDropdown("priorities", PRIORITIES);
  await upsertDropdown("payment_statuses", PAYMENT_STATUSES);

  console.log("\n👤 Creating admin user...");
  const adminUid = await upsertAdminUser();
  
  console.log("\n📝 Creating sample enquiry...");
  const enquiryId = await createSampleEnquiry(adminUid);
  
  console.log("\n📈 Creating initial history...");
  await createInitialHistory(enquiryId, adminUid);

  // Summary
  console.log("\n🎉 == Summary ==");
  for (const [k, v] of Object.entries(counts)) {
    console.log(`${k}: written=${v.written}, skipped=${v.skipped}`);
  }
  console.log("\n✅ Done! Your app should now work without loading symbols.");
}

main().catch((e) => {
  console.error("❌ Seeder failed:", e);
  process.exit(1);
});

