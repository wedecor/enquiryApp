# Terraform configuration to create OAuth client IDs
# Run: terraform init && terraform plan && terraform apply

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = "wedecorenquries"
  region  = "us-central1"
}

# Enable required APIs
resource "google_project_service" "drive_api" {
  service = "drive.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "oauth2_api" {
  service = "oauth2.googleapis.com"
  disable_on_destroy = false
}

# OAuth Consent Screen Configuration
resource "google_iap_client" "oauth_consent" {
  brand = google_iap_brand.project_brand.brand_id
  display_name = "We Decor Enquiries"
}

resource "google_iap_brand" "project_brand" {
  support_email     = "connect2wedecor@gmail.com"
  application_title = "We Decor Enquiries"
  project           = "wedecorenquries"
}

# Note: OAuth client creation via Terraform requires the google_iap_client resource
# However, this is for IAP (Identity-Aware Proxy), not standard OAuth clients
# Standard OAuth clients still need to be created via web console

# Alternative: Use google_oauth2_client resource (if available in provider)
# This is a workaround - standard OAuth clients are typically created via console

output "instructions" {
  value = <<-EOT
    ⚠️  OAuth Client Creation:
    
    Terraform cannot directly create standard OAuth 2.0 client IDs.
    You need to create them manually via web console:
    
    1. Go to: https://console.cloud.google.com/apis/credentials?project=wedecorenquries
    2. Click "Create Credentials" > "OAuth client ID"
    3. Create:
       - Web application (with redirect URIs)
       - Android application (with SHA-1)
       - iOS application (with bundle ID)
    
    Or use the gcloud command with proper permissions (requires Owner role):
    gcloud projects add-iam-policy-binding wedecorenquries \\
      --member='user:connect2wedecor@gmail.com' \\
      --role='roles/owner'
  EOT
}

