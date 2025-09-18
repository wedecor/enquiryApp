import { z } from "zod";

export const DropdownItemSchema = z.object({
  value: z.string().min(1),
  label: z.string().min(1),
  order: z.number().int().nonnegative(),
  active: z.boolean(),
  color: z.string().regex(/^#([0-9A-Fa-f]{6})$/).optional()
});

export type DropdownItem = z.infer<typeof DropdownItemSchema>;

export const UserSchema = z.object({
  uid: z.string().min(1),
  name: z.string().min(1),
  email: z.string().email(),
  phone: z.string().optional().nullable(),
  role: z.enum(["admin", "staff"]),
  fcmToken: z.string().optional().nullable()
});

export type UserDoc = z.infer<typeof UserSchema>;

export const EnquirySchema = z.object({
  customerName: z.string().min(1),
  customerPhone: z.string().min(5),
  customerEmail: z.string().email().optional().nullable(),

  eventType: z.enum(["wedding","birthday","corporate_event","haldi","anniversary","others"]),
  eventDate: z.any().optional().nullable(),
  eventLocation: z.string().optional().nullable(),
  guestCount: z.number().int().nonnegative().optional().nullable(),
  budgetRange: z.string().optional().nullable(),
  description: z.string().optional().nullable(),

  eventStatus: z.enum(["new","in_progress","quote_sent","approved","scheduled","completed","cancelled","closed_lost"]),
  paymentStatus: z.enum(["pending","partial","paid","overdue"]),
  priority: z.enum(["low","medium","high","urgent"]),

  source: z.string().optional().nullable(),
  assignedTo: z.string().optional().nullable(),
  createdBy: z.string().min(1),

  totalCost: z.number().optional().nullable(),
  advancePaid: z.number().optional().nullable()
});

export type Enquiry = z.infer<typeof EnquirySchema>;

export const HistorySchema = z.object({
  field_changed: z.string().min(1),
  old_value: z.any(),
  new_value: z.any(),
  user_id: z.string().min(1),
  user_email: z.string().email().optional().nullable(),
});

export type History = z.infer<typeof HistorySchema>;

