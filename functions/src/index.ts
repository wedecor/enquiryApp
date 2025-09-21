import { setGlobalOptions, logger } from "firebase-functions/v2";
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { getAuth } from "firebase-admin/auth";
// Removed deprecated config import for Firebase Functions v2
import * as nodemailer from "nodemailer";

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

// SMTP Configuration using environment variables (Firebase Functions v2)
const createEmailTransporter = () => {
  // Try to get SMTP config from environment variables
  const smtpHost = process.env.SMTP_HOST;
  const smtpUser = process.env.SMTP_USER;
  const smtpPass = process.env.SMTP_PASS;
  const smtpPort = process.env.SMTP_PORT;
  
  if (smtpHost && smtpUser && smtpPass) {
    logger.info('Using custom SMTP configuration from environment variables');
    return nodemailer.createTransport({
      host: smtpHost,
      port: parseInt(smtpPort || '587'),
      secure: smtpPort === '465',
      auth: {
        user: smtpUser,
        pass: smtpPass,
      }
    });
  }

  // Fallback to Gmail with app password
  logger.info('Using Gmail SMTP configuration');
  return nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: 'connect2wedecor@gmail.com',
      pass: 'sdit fdqa gfee nzdy' // App password
    }
  });
};

type Enquiry = {
  assignedTo?: string | null;
  eventStatus?: string | null;
  paymentStatus?: string | null;
  customerName?: string | null;
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
  resetLink: string;
  emailSent?: boolean;
};

// Utility function to check if user is admin
async function isAdmin(uid: string): Promise<boolean> {
  try {
    const db = getFirestore();
    const userDoc = await db.collection('users').doc(uid).get();
    
    if (!userDoc.exists) {
      return false;
    }
    
    const userData = userDoc.data();
    return userData?.role === 'admin' && userData?.active === true;
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

    const { email, name, role } = request.data;

    // Validate input
    if (!email || !email.includes('@')) {
      throw new HttpsError('invalid-argument', 'Valid email is required');
    }

    if (!role || !['staff', 'admin'].includes(role)) {
      throw new HttpsError('invalid-argument', 'Role must be either "staff" or "admin"');
    }

    try {
      const auth = getAuth();
      const db = getFirestore();

      let userRecord;
      let isExistingUser = false;

      // Check if user already exists in Firebase Auth
      try {
        userRecord = await auth.getUserByEmail(email);
        isExistingUser = true;
        logger.info('User already exists in Firebase', { emailProvided: true, userFound: true });
      } catch (error: any) {
        if (error.code === 'auth/user-not-found') {
          // Create new user in Firebase Auth
          logger.info('Creating new Firebase user', { emailProvided: true, newUserCreation: true });
          userRecord = await auth.createUser({
            email,
            emailVerified: false,
            disabled: false,
            displayName: name || email.split('@')[0],
          });
          logger.info('Firebase user created successfully', { userCreated: true, hasUid: !!userRecord.uid });
        } else {
          throw error;
        }
      }

      // Generate password reset link
      const resetLink = await auth.generatePasswordResetLink(email, ACTION_CODE_SETTINGS);

      // Create/update Firestore user document
      const userData = {
        uid: userRecord.uid,
        name: name || email.split('@')[0],
        email,
        phone: '', // UserModel expects string, not null
        role,
        // Remove 'active' field as UserModel doesn't have it
        createdAt: isExistingUser ? undefined : FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      };

      // Remove undefined fields for existing users
      if (isExistingUser) {
        delete userData.createdAt;
      }

      await db.collection('users').doc(userRecord.uid).set(userData, { merge: true });

      logger.info('User invitation completed', {
        uid: userRecord.uid,
        email,
        role,
        isExistingUser,
        resetLinkGenerated: !!resetLink,
      });

      // Send invitation email via Gmail SMTP
      let emailSent = false;
      
      try {
        const transporter = createEmailTransporter();
        
        const mailOptions = {
          from: '"WeDecor Events" <connect2wedecor@gmail.com>',
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
                <h2 style="color: #1a202c; margin: 0 0 20px; font-size: 24px;">Hi ${name || 'there'},</h2>
                
                <p style="color: #4a5568; line-height: 1.6; margin: 0 0 20px; font-size: 16px;">
                  You've been invited to join <strong>WeDecor Events</strong> as a <strong style="color: #667eea;">${role}</strong>.
                </p>
                
                <div style="background: #f7fafc; border-left: 4px solid #667eea; padding: 20px; margin: 20px 0;">
                  <h3 style="color: #2d3748; margin: 0 0 15px; font-size: 18px;">Getting Started:</h3>
                  <ol style="color: #4a5568; margin: 0; padding-left: 20px; line-height: 1.8;">
                    <li>Click the "Set Password" button below</li>
                    <li>Create a secure password for your account</li>
                    <li>Login with your email: <strong>${email}</strong></li>
                    <li>Start managing enquiries and events!</li>
                  </ol>
                </div>
                
                <!-- CTA Button -->
                <div style="text-align: center; margin: 35px 0;">
                  <a href="${resetLink}" 
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
                    ${resetLink}
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
          text: `Hi ${name || ''},

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
          to: email,
          role,
          hasResetLink: !!resetLink,
          emailDelivered: true
        });
        
      } catch (emailError: any) {
        logger.error('Failed to send invitation email', {
          error: emailError.message,
          to: email,
          hasResetLink: !!resetLink
        });
        // Don't fail the function - admin can still share the link manually
      }
      
      return {
        uid: userRecord.uid,
        email,
        role,
        resetLink,
        emailSent,
      };

    } catch (error: any) {
      logger.error('Error in inviteUser function', { 
        email: email.includes('@'), 
        role, 
        error: error.message,
        code: error.code 
      });
      
      if (error instanceof HttpsError) {
        throw error;
      }
      
      throw new HttpsError('internal', `Failed to invite user: ${error.message}`);
    }
  }
);

export const notifyOnEnquiryChange = onDocumentWritten(
  "enquiries/{id}",
  async (event) => {
    const before = (event.data?.before?.data() || null) as Enquiry | null;
    const after = (event.data?.after?.data() || null) as Enquiry | null;

    if (!after) {
      // Deleted doc: no-op
      return;
    }

    const changedAssigned = (before?.assignedTo ?? null) !== (after.assignedTo ?? null);
    const changedStatus   = (before?.eventStatus ?? null) !== (after.eventStatus ?? null);
    const changedPayment  = (before?.paymentStatus ?? null) !== (after.paymentStatus ?? null);

    if (!(changedAssigned || changedStatus || changedPayment)) {
      logger.debug("No meaningful change; skipping push", { id: event.params.id });
      return;
    }

    const uid = after.assignedTo;
    if (!uid) {
      logger.debug("No assignedTo on enquiry; skipping", { id: event.params.id });
      return;
    }

    const db = getFirestore();
    
    // NEW: Read private tokens from secure subcollection
    const tokensSnap = await db.collection("users").doc(uid)
      .collection("private").doc("notifications")
      .collection("tokens").limit(500).get();

    const tokens = Array.from(new Set(
      tokensSnap.docs.map(d => (d.get("token") as string | undefined) || d.id).filter(Boolean) as string[]
    ));

    if (tokens.length === 0) {
      logger.info("No FCM devices found for user; skipping notification", { 
        uid, 
        deviceCount: 0,
        enquiryId: event.params.id 
      });
      return;
    }

    const titleParts: string[] = [];
    if (changedAssigned) titleParts.push("Assigned");
    if (changedStatus)   titleParts.push(`Status: ${after.eventStatus ?? ""}`);
    if (changedPayment)  titleParts.push(`Payment: ${after.paymentStatus ?? ""}`);
    const title = titleParts.join(" • ") || "Enquiry Updated";

    const body  = after.customerName ? `Customer: ${after.customerName}` : "Open the app for details";
    const data  = {
      type: "enquiry_update",
      enquiryId: event.params.id,
      eventStatus: after.eventStatus ?? "",
      paymentStatus: after.paymentStatus ?? ""
    };

    const res = await getMessaging().sendEachForMulticast({
      tokens,
      notification: { title, body },
      data
    });

    logger.info("Push notification summary", {
      enquiryId: event.params.id,
      uid,
      deviceCount: tokens.length,
      successCount: res.successCount,
      failureCount: res.failureCount
    });

    // Optional in-app inbox doc
    await db.collection("notifications").doc(uid).collection("items").add({
      type: "enquiry_update",
      enquiryId: event.params.id,
      title,
      body,
      eventStatus: after.eventStatus ?? null,
      paymentStatus: after.paymentStatus ?? null,
      createdAt: FieldValue.serverTimestamp(),
      read: false,
      archived: false
    });
  }
);