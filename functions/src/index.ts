import { setGlobalOptions, logger } from "firebase-functions/v2";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue, Transaction } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { getAuth } from "firebase-admin/auth";
// Removed deprecated config import for Firebase Functions v2
import { createEmailTransporter, getSmtpFromAddress, SMTP_SECRET_NAMES } from "./smtp";

setGlobalOptions({
  region: "asia-south1",
  memory: "256MiB", // Increased from 128MiB to handle email operations
  timeoutSeconds: 60, // Increased timeout for email sending
  maxInstances: 5
});

initializeApp();

// Action Code Settings for password reset links
const ACTION_CODE_SETTINGS = {
  url: 'https://wedecorenquries.web.app/auth/completed',
  handleCodeInApp: false,
};

type InviteUserRequest = {
  email: string;
  name?: string;
  role: 'staff' | 'admin';
};

type InviteUserResponse = {
  uid: string;
  email: string;
  role: string;
  /** Only returned when the invitation email was NOT sent, so the admin can share it. */
  resetLink?: string;
  emailSent: boolean;
};

/** Escapes text for safe interpolation into the invitation email HTML. */
function escapeHtml(value: string): string {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

/** Users docs written before the isActive migration may still carry `active`. */
function isActiveUserData(data: FirebaseFirestore.DocumentData | undefined): boolean {
  const isActive = data?.isActive ?? data?.active ?? true;
  return isActive !== false;
}

// Utility function to check if user is admin
async function isAdmin(uid: string): Promise<boolean> {
  try {
    const db = getFirestore();
    const userDoc = await db.collection('users').doc(uid).get();
    
    if (!userDoc.exists) {
      return false;
    }
    
    const userData = userDoc.data();
    // Backward compatible: checks both 'isActive' and legacy 'active' (default active).
    return userData?.role === 'admin' && isActiveUserData(userData);
  } catch (error) {
    logger.error('Error checking admin status', { uid, error });
    return false;
  }
}

export const inviteUser = onCall<InviteUserRequest, Promise<InviteUserResponse>>(
  {
    cors: true, // Enable CORS for all origins in v2
    region: "asia-south1", // Explicit region
    memory: "256MiB", // Increased memory for this function
    timeoutSeconds: 60, // Increased timeout for email operations
    enforceAppCheck: false, // Disable AppCheck enforcement to avoid token issues
    secrets: [...SMTP_SECRET_NAMES],
  },
  async (request) => {
    // Ensure user is authenticated
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Must be signed in to invite users');
    }

    // Check if requesting user is admin
    const isRequestingUserAdmin = await isAdmin(request.auth.uid);
    if (!isRequestingUserAdmin) {
      throw new HttpsError('permission-denied', 'Admin privileges required to invite users');
    }

    const { name, role } = request.data ?? ({} as Partial<InviteUserRequest>);
    const email = typeof request.data?.email === 'string' ? request.data.email.trim() : '';

    // Validate input
    if (!email || !email.includes('@')) {
      throw new HttpsError('invalid-argument', 'Valid email is required');
    }

    if (!role || !['staff', 'admin'].includes(role)) {
      throw new HttpsError('invalid-argument', 'Role must be either "staff" or "admin"');
    }

    if (name !== undefined && typeof name !== 'string') {
      throw new HttpsError('invalid-argument', 'Name must be a string');
    }

    const displayName = (name && name.trim()) || email.split('@')[0];

    try {
      const auth = getAuth();
      const db = getFirestore();

      // Re-inviting must never silently change an existing user's role/status/phone.
      let authUserExists = false;
      try {
        await auth.getUserByEmail(email);
        authUserExists = true;
      } catch (error: any) {
        if (error?.code !== 'auth/user-not-found') {
          throw error;
        }
      }

      const emailLower = email.toLowerCase();
      const existingDocs = await db.collection('users').where('email', 'in', Array.from(new Set([email, emailLower]))).limit(1).get();

      if (authUserExists || !existingDocs.empty) {
        throw new HttpsError('already-exists', 'A user with this email already exists');
      }

      logger.info('Creating new Firebase user', { newUserCreation: true });
      const userRecord = await auth.createUser({
        email,
        emailVerified: false,
        disabled: false,
        displayName,
      });

      // Generate password reset link
      const resetLink = await auth.generatePasswordResetLink(email, ACTION_CODE_SETTINGS);

      await db.collection('users').doc(userRecord.uid).set({
        uid: userRecord.uid,
        name: displayName,
        email,
        phone: '', // UserModel expects string, not null
        role,
        isActive: true, // Standardized field name
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });

      logger.info('User invitation completed', {
        uid: userRecord.uid,
        role,
        resetLinkGenerated: !!resetLink,
      });

      const safeName = escapeHtml(name && name.trim() ? name.trim() : 'there');
      const safeEmail = escapeHtml(email);
      const safeLink = escapeHtml(resetLink);

      // Send invitation email when SMTP is configured (SMTP_USER + SMTP_PASS secret)
      let emailSent = false;
      
      try {
        const transporter = createEmailTransporter();
        if (!transporter) {
          logger.warn('Invitation email skipped — SMTP not configured', { emailProvided: true });
        } else {
        const mailOptions = {
          from: getSmtpFromAddress(),
          to: email,
          subject: '🏠 Welcome to WeDecor Events - Set Your Password',
          html: `
            <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 600px; margin: 0 auto; background: #f8fafc;">
              <!-- Header -->
              <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 40px 30px; text-align: center;">
                <h1 style="margin: 0; font-size: 28px; font-weight: 600;">🏠 WeDecor Events</h1>
                <p style="margin: 10px 0 0; opacity: 0.9; font-size: 16px;">Welcome to our team!</p>
              </div>
              
              <!-- Main Content -->
              <div style="background: white; padding: 40px 30px;">
                <h2 style="color: #1a202c; margin: 0 0 20px; font-size: 24px;">Hi ${safeName},</h2>
                
                <p style="color: #4a5568; line-height: 1.6; margin: 0 0 20px; font-size: 16px;">
                  You've been invited to join <strong>WeDecor Events</strong> as a <strong style="color: #667eea;">${role}</strong>.
                </p>
                
                <div style="background: #f7fafc; border-left: 4px solid #667eea; padding: 20px; margin: 20px 0;">
                  <h3 style="color: #2d3748; margin: 0 0 15px; font-size: 18px;">Getting Started:</h3>
                  <ol style="color: #4a5568; margin: 0; padding-left: 20px; line-height: 1.8;">
                    <li>Click the "Set Password" button below</li>
                    <li>Create a secure password for your account</li>
                    <li>Login with your email: <strong>${safeEmail}</strong></li>
                    <li>Start managing enquiries and events!</li>
                  </ol>
                </div>
                
                <!-- CTA Button -->
                <div style="text-align: center; margin: 35px 0;">
                  <a href="${safeLink}" 
                     style="display: inline-block; 
                            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
                            color: white; 
                            padding: 15px 35px; 
                            text-decoration: none; 
                            border-radius: 8px; 
                            font-weight: 600; 
                            font-size: 16px; 
                            box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);">
                    🔐 Set Your Password
                  </a>
                </div>
                
                <!-- Security Notice -->
                <div style="background: #fef5e7; border: 1px solid #f6e05e; border-radius: 8px; padding: 15px; margin: 25px 0;">
                  <p style="color: #744210; margin: 0; font-size: 14px;">
                    <strong>⏰ Security Notice:</strong> This link will expire in 1 hour for your protection.
                  </p>
                </div>
                
                <!-- Alternative Link -->
                <details style="margin: 25px 0;">
                  <summary style="color: #667eea; cursor: pointer; font-size: 14px;">Can't click the button? Use this link</summary>
                  <p style="background: #f7fafc; padding: 10px; border-radius: 4px; font-family: monospace; font-size: 12px; word-break: break-all; color: #4a5568; margin: 10px 0 0;">
                    ${safeLink}
                  </p>
                </details>
              </div>
              
              <!-- Footer -->
              <div style="background: #2d3748; color: #a0aec0; padding: 30px; text-align: center;">
                <p style="margin: 0 0 10px; font-size: 16px; font-weight: 600;">WeDecor Events Team</p>
                <p style="margin: 0; font-size: 14px; opacity: 0.8;">Making your events beautiful, one enquiry at a time.</p>
                
                <div style="margin: 20px 0 0; padding: 15px 0; border-top: 1px solid #4a5568;">
                  <p style="margin: 0; font-size: 12px; opacity: 0.7;">
                    If you didn't expect this invitation, please ignore this email.<br>
                    This is an automated message from WeDecor Events.
                  </p>
                </div>
              </div>
            </div>
          `,
          text: `Hi ${name && name.trim() ? name.trim() : 'there'},

You've been invited to join WeDecor Events as a ${role}.

Set your password here: ${resetLink}

This link will expire in 1 hour for security.

Login email: ${email}

Best regards,
WeDecor Events Team

If you didn't expect this invitation, please ignore this email.`
        };
        
        await transporter.sendMail(mailOptions);
        emailSent = true;
        
        logger.info('Invitation email sent successfully', {
          uid: userRecord.uid,
          role,
          hasResetLink: !!resetLink,
          emailDelivered: true
        });
        }
        
      } catch (emailError: any) {
        logger.error('Failed to send invitation email', {
          error: emailError?.message,
          uid: userRecord.uid,
          hasResetLink: !!resetLink
        });
        // Don't fail the function - admin can still share the link manually
      }
      
      // The reset link is a credential: only hand it back when the email did not go out,
      // so the admin can share it manually.
      return {
        uid: userRecord.uid,
        email,
        role,
        emailSent,
        ...(emailSent ? {} : { resetLink }),
      };

    } catch (error: any) {
      if (error instanceof HttpsError) {
        throw error;
      }
      if (error?.code === 'auth/email-already-exists') {
        throw new HttpsError('already-exists', 'A user with this email already exists');
      }

      logger.error('Error in inviteUser function', {
        role,
        error: error?.message,
        code: error?.code,
      });

      throw new HttpsError('internal', 'Failed to invite user. Please try again.');
    }
  }
);

// notifyOnEnquiryChange was removed: the app already queues a notification doc
// (users/{uid}/notifications) for every create / assign / status change / edit,
// and sendNotificationToUser below pushes it. The extra trigger caused duplicate
// pushes and pushes to the person who made the change.

// Sends the FCM push for every notification doc created under users/{userId}/notifications
// (queued by the app's NotificationService and by autoExpireEnquiries).
export const sendNotificationToUser = onDocumentCreated(
  "users/{userId}/notifications/{notificationId}",
  async (event) => {
    const after = event.data?.data();
    if (!after) {
      return;
    }

    const userId = event.params.userId;
    const title = after.title as string | undefined;
    const body = after.body as string | undefined;
    const data = (after.data as Record<string, unknown> | undefined) || {};

    if (!title || !body) {
      logger.warn("Notification missing title or body", { userId, notificationId: event.params.notificationId });
      return;
    }

    try {
      const db = getFirestore();

      // Deactivated users must not keep receiving customer pushes.
      const userSnap = await db.collection("users").doc(userId).get();
      if (userSnap.exists && !isActiveUserData(userSnap.data())) {
        logger.info("Skipping push for inactive user", {
          userId,
          notificationId: event.params.notificationId,
        });
        return;
      }

      // Get user's FCM tokens
      const tokensSnap = await db.collection("users").doc(userId)
        .collection("private").doc("notifications")
        .collection("tokens").limit(500).get();

      const tokens = Array.from(new Set(
        tokensSnap.docs.map(d => (d.get("token") as string | undefined) || d.id).filter(Boolean) as string[]
      ));

      if (tokens.length === 0) {
        logger.info("No FCM registrations found for user", {
          userId,
          notificationId: event.params.notificationId,
        });
        return;
      }

      // Convert data to strings (FCM requires string values)
      const fcmData: Record<string, string> = {};
      for (const [key, value] of Object.entries(data)) {
        if (value === null || value === undefined) continue;
        fcmData[key] = typeof value === "string" ? value : String(value);
      }
      if (typeof after.type === "string" && !fcmData.type) fcmData.type = after.type;
      if (typeof after.enquiryId === "string" && !fcmData.enquiryId) fcmData.enquiryId = after.enquiryId;
      fcmData.notificationId = event.params.notificationId;

      fcmData.title = title;
      fcmData.body = body;

      // Send FCM notification (high priority so Android shows it promptly)
      const res = await getMessaging().sendEachForMulticast({
        tokens,
        notification: { title, body },
        data: fcmData,
        android: {
          priority: "high",
          notification: { sound: "default", channelId: "enquiry_updates" },
        },
        apns: { payload: { aps: { sound: "default" } } },
      });

      // Remove tokens FCM reports as dead (uninstalled app, expired token).
      const dead: string[] = [];
      res.responses.forEach((r, i) => {
        const code = r.error?.code;
        if (
          code === "messaging/registration-token-not-registered" ||
          code === "messaging/invalid-registration-token"
        ) {
          dead.push(tokens[i]);
        }
      });
      if (dead.length > 0) {
        const tokenDocs = tokensSnap.docs.filter((d) => dead.includes((d.get("token") as string | undefined) || d.id));
        await Promise.all(tokenDocs.map((d) => d.ref.delete()));
        const removed = tokenDocs.length;
        logger.info("Removed dead FCM device registrations", { userId, removed });
      }

      logger.info("FCM notification sent to user", {
        userId,
        notificationId: event.params.notificationId,
        deviceCount: tokens.length,
        successCount: res.successCount,
        failureCount: res.failureCount,
      });
    } catch (error: any) {
      logger.error("Error sending FCM notification to user", {
        userId,
        notificationId: event.params.notificationId,
        error: error?.message,
      });
    }
  }
);

// sendNotificationToTopic was removed: nothing writes notifications/{topic}/messages.

type AdminUpdateUserRequest = {
  uid: string;
  name?: string;
  phone?: string | null;
  role?: 'admin' | 'staff';
  isActive?: boolean;
};

/**
 * Admin-only user edit (name / phone / role / active). Enforces:
 * - caller is an active admin and cannot change their own role or active status;
 * - at least one active admin always remains;
 * - deactivation also disables Auth, revokes sessions and removes FCM tokens.
 */
export const adminUpdateUser = onCall<AdminUpdateUserRequest, Promise<{ ok: true }>>(
  {
    cors: true,
    region: "asia-south1",
    enforceAppCheck: false,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Must be signed in to update users');
    }
    const callerUid = request.auth.uid;

    if (!(await isAdmin(callerUid))) {
      throw new HttpsError('permission-denied', 'Admin privileges required to update users');
    }

    const input = (request.data ?? {}) as Partial<AdminUpdateUserRequest>;
    const uid = typeof input.uid === 'string' ? input.uid.trim() : '';
    if (!uid) {
      throw new HttpsError('invalid-argument', 'uid is required');
    }

    const updates: Record<string, unknown> = {};

    if (input.name !== undefined) {
      if (typeof input.name !== 'string' || !input.name.trim() || input.name.trim().length > 100) {
        throw new HttpsError('invalid-argument', 'Name must be 1–100 characters');
      }
      updates.name = input.name.trim();
    }

    if (input.phone !== undefined) {
      if (input.phone !== null && typeof input.phone !== 'string') {
        throw new HttpsError('invalid-argument', 'Phone must be a string or null');
      }
      const phone = (input.phone ?? '').trim();
      if (phone.length > 30) {
        throw new HttpsError('invalid-argument', 'Phone number is too long');
      }
      // Stored as '' when cleared (same convention as inviteUser).
      updates.phone = phone;
    }

    if (input.role !== undefined) {
      if (input.role !== 'admin' && input.role !== 'staff') {
        throw new HttpsError('invalid-argument', 'Role must be either "staff" or "admin"');
      }
      updates.role = input.role;
    }

    if (input.isActive !== undefined) {
      if (typeof input.isActive !== 'boolean') {
        throw new HttpsError('invalid-argument', 'isActive must be a boolean');
      }
      updates.isActive = input.isActive;
    }

    if (Object.keys(updates).length === 0) {
      throw new HttpsError('invalid-argument', 'No changes provided');
    }

    const db = getFirestore();
    const userRef = db.collection('users').doc(uid);

    const before = await db.runTransaction(async (tx: Transaction) => {
      const snap = await tx.get(userRef);
      if (!snap.exists) {
        throw new HttpsError('not-found', 'User not found');
      }
      const current = snap.data() ?? {};
      const currentRole = current.role as string | undefined;
      const currentlyActive = isActiveUserData(current);

      const roleChanging = updates.role !== undefined && updates.role !== currentRole;
      const activeChanging = updates.isActive !== undefined && updates.isActive !== currentlyActive;

      if (uid === callerUid && (roleChanging || activeChanging)) {
        throw new HttpsError('failed-precondition', 'You cannot change your own role or active status');
      }

      const wasActiveAdmin = currentRole === 'admin' && currentlyActive;
      const willBeActiveAdmin =
        ((updates.role as string | undefined) ?? currentRole) === 'admin' &&
        ((updates.isActive as boolean | undefined) ?? currentlyActive);

      if (wasActiveAdmin && !willBeActiveAdmin) {
        // Read inside the transaction so two concurrent demotions cannot both pass.
        const admins = await tx.get(db.collection('users').where('role', '==', 'admin'));
        const otherActiveAdmins = admins.docs.filter(
          (d) => d.id !== uid && isActiveUserData(d.data())
        ).length;
        if (otherActiveAdmins === 0) {
          throw new HttpsError(
            'failed-precondition',
            'At least one active admin is required. Promote another user to admin first.'
          );
        }
      }

      tx.update(userRef, {
        ...updates,
        updatedAt: FieldValue.serverTimestamp(),
        updatedBy: callerUid,
      });

      tx.set(db.collection('admin_audit').doc(), {
        action: 'user_updated',
        user_id: callerUid,
        user_email: request.auth?.token?.email ?? 'unknown',
        timestamp: FieldValue.serverTimestamp(),
        data: {
          targetUid: uid,
          changes: updates,
          previous: {
            ...(updates.name !== undefined ? { name: current.name ?? null } : {}),
            ...(updates.phone !== undefined ? { phone: current.phone ?? null } : {}),
            ...(updates.role !== undefined ? { role: currentRole ?? null } : {}),
            ...(updates.isActive !== undefined ? { isActive: currentlyActive } : {}),
          },
        },
        source: 'adminUpdateUser',
      });

      return { currentlyActive };
    });

    if (updates.isActive !== undefined) {
      if (updates.isActive === false) {
        try {
          const tokensRef = userRef.collection('private').doc('notifications').collection('tokens');
          let removed = 0;
          while (true) {
            const page = await tokensRef.limit(400).get();
            if (page.empty) break;
            const batch = db.batch();
            page.docs.forEach((d) => batch.delete(d.ref));
            await batch.commit();
            removed += page.size;
            if (page.size < 400) break;
          }
          logger.info('adminUpdateUser: removed FCM device registrations', { uid, removed });
        } catch (error: any) {
          logger.error('adminUpdateUser: failed to remove FCM tokens', { uid, error: error?.message });
        }
      }

      const auth = getAuth();
      try {
        if (updates.isActive === false) {
          await auth.updateUser(uid, { disabled: true });
          await auth.revokeRefreshTokens(uid);
        } else {
          await auth.updateUser(uid, { disabled: false });
        }
      } catch (error: any) {
        if (error?.code === 'auth/user-not-found') {
          logger.warn('adminUpdateUser: no Auth account for user', { uid });
        } else {
          logger.error('adminUpdateUser: failed to update Auth account', {
            uid,
            error: error?.message,
            code: error?.code,
          });
          throw new HttpsError(
            'internal',
            'Profile saved, but sign-in access could not be updated. Please try again.'
          );
        }
      }
    }

    logger.info('adminUpdateUser completed', {
      uid,
      by: callerUid,
      fields: Object.keys(updates),
      wasActive: before.currentlyActive,
    });

    return { ok: true as const };
  }
);

export { autoExpireEnquiries } from "./autoExpireEnquiries";
export { lookupCustomer } from "./customers";
export { approvedOnDate } from "./bookings";
// Removed: migrateStatusFields - Migration complete, no longer needed
// Removed: notifyOverdueInTalks - 4-hour scheduled reminders disabled