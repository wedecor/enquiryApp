#!/usr/bin/env python3
"""
Script to create OAuth 2.0 client IDs for We Decor Enquiries
Requires: pip install google-api-python-client google-auth-httplib2 google-auth-oauthlib
"""

import json
import sys
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError

PROJECT_ID = "wedecorenquries"

# OAuth client configurations
CLIENTS = [
    {
        "name": "We Decor Enquiries Web",
        "type": "WEB_APPLICATION",
        "redirect_uris": [
            "http://localhost:5000",
            "https://wedecorenquries.web.app",
            "https://wedecorenquries.firebaseapp.com"
        ],
        "javascript_origins": [
            "http://localhost:5000",
            "https://wedecorenquries.web.app",
            "https://wedecorenquries.firebaseapp.com"
        ]
    },
    {
        "name": "We Decor Enquiries Android",
        "type": "ANDROID",
        "package_name": "com.example.we_decor_enquiries",
        "sha1_fingerprint": None  # Will prompt user
    },
    {
        "name": "We Decor Enquiries iOS",
        "type": "IOS",
        "bundle_id": "com.example.weDecorEnquiries"
    }
]

def get_sha1_fingerprint():
    """Get SHA-1 fingerprint from user"""
    print("\n📱 Android SHA-1 Fingerprint")
    print("Run this command to get your SHA-1:")
    print("  keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android")
    print("\nOr for release keystore:")
    print("  keytool -list -v -keystore /path/to/your/keystore.jks -alias your-alias")
    sha1 = input("Enter SHA-1 fingerprint (or press Enter to skip Android client): ")
    return sha1.strip() if sha1 else None

def create_oauth_client(service, client_config):
    """Create an OAuth client"""
    try:
        body = {
            "displayName": client_config["name"]
        }
        
        if client_config["type"] == "WEB_APPLICATION":
            body["web"] = {
                "redirectUris": client_config["redirect_uris"],
                "javascriptOrigins": client_config["javascript_origins"]
            }
        elif client_config["type"] == "ANDROID":
            if not client_config.get("sha1_fingerprint"]:
                return None
            body["android"] = {
                "packageName": client_config["package_name"],
                "sha1Fingerprints": [client_config["sha1_fingerprint"]]
            }
        elif client_config["type"] == "IOS":
            body["ios"] = {
                "bundleId": client_config["bundle_id"]
            }
        
        request = service.projects().credentials().oauthClients().create(
            parent=f"projects/{PROJECT_ID}/locations/global",
            body=body
        )
        
        response = request.execute()
        return response
    except HttpError as e:
        print(f"❌ Error creating {client_config['name']}: {e}")
        return None

def main():
    print("🚀 Creating OAuth Client IDs for We Decor Enquiries")
    print(f"Project: {PROJECT_ID}\n")
    
    # Check if user wants to provide SHA-1
    for client in CLIENTS:
        if client["type"] == "ANDROID" and client["sha1_fingerprint"] is None:
            client["sha1_fingerprint"] = get_sha1_fingerprint()
            if not client["sha1_fingerprint"]:
                print("⏭️  Skipping Android client creation")
                continue
    
    print("\n⚠️  Note: This script requires Google Cloud API access.")
    print("   Alternative: Use Google Cloud Console (easier)")
    print("   https://console.cloud.google.com/apis/credentials\n")
    
    # Try to use Application Default Credentials
    try:
        credentials = service_account.Credentials.from_service_account_file(
            None, scopes=['https://www.googleapis.com/auth/cloud-platform']
        )
        service = build('iam', 'v1', credentials=credentials)
    except Exception as e:
        print(f"❌ Authentication error: {e}")
        print("\n💡 To authenticate:")
        print("   1. Run: gcloud auth application-default login")
        print("   2. Or set GOOGLE_APPLICATION_CREDENTIALS to service account JSON")
        print("\n📋 Manual creation recommended:")
        print("   https://console.cloud.google.com/apis/credentials?project=wedecorenquries")
        return
    
    # Create clients
    created = []
    for client_config in CLIENTS:
        if client_config["type"] == "ANDROID" and not client_config["sha1_fingerprint"]:
            continue
            
        print(f"\n📱 Creating {client_config['name']}...")
        result = create_oauth_client(service, client_config)
        if result:
            created.append({
                "name": client_config["name"],
                "client_id": result.get("clientId"),
                "client_secret": result.get("clientSecret")
            })
            print(f"✅ Created: {result.get('clientId')}")
        else:
            print(f"❌ Failed to create {client_config['name']}")
    
    if created:
        print("\n✅ Successfully created OAuth clients:")
        for client in created:
            print(f"   - {client['name']}: {client['client_id']}")
    else:
        print("\n⚠️  No clients were created. Use Google Cloud Console instead.")

if __name__ == "__main__":
    main():
    main()
