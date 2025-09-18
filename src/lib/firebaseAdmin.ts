import { initializeApp, applicationDefault, cert, getApps } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import fs from "node:fs";
import { execSync } from "node:child_process";

function init() {
  if (getApps().length) return;
  
  // Firebase project configuration
  const projectId = "wedecorenquries";
  
  try {
    // Try to use Firebase CLI token for authentication
    const token = execSync('firebase auth:print-access-token', { encoding: 'utf8' }).trim();
    
    // Create a temporary service account-like object using the access token
    const credential = {
      projectId: projectId,
      clientEmail: "firebase-adminsdk@wedecorenquries.iam.gserviceaccount.com",
      privateKey: "process.env.PRIVATE_KEY_1\n",
    };
    
    // Use application default credentials with project ID
    initializeApp({ 
      credential: applicationDefault(),
      projectId: projectId
    });
  } catch (tokenError) {
    console.log("Firebase CLI [REDACTED] not available, trying other methods...");
    
    // Fallback to service account file if available
    const credsPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
    if (credsPath && fs.existsSync(credsPath)) {
      const svc = JSON.parse(fs.readFileSync(credsPath, "utf8"));
      initializeApp({ 
        credential: cert(svc),
        projectId: projectId
      });
    } else {
      // Last resort: try application default with explicit project ID
      process.env.GOOGLE_CLOUD_PROJECT = projectId;
      process.env.GCLOUD_PROJECT = projectId;
      initializeApp({ 
        credential: applicationDefault(),
        projectId: projectId
      });
    }
  }
}

export function db() {
  init();
  return getFirestore();
}
