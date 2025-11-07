#!/bin/bash

# Setup SMTP configuration for WeDecor email sending
# This script configures the Cloud Functions environment for email sending

echo "🔧 Setting up SMTP configuration for WeDecor..."

# Set the SMTP environment variables for Cloud Functions
firebase functions:config:set \
  smtp.host="smtp.gmail.com" \
  smtp.port="587" \
  smtp.user="connect2wedecor@gmail.com" \
  smtp.pass="sdit fdqa gfee nzdy" \
  smtp.from="WeDecor Events <connect2wedecor@gmail.com>"

echo "✅ SMTP configuration set successfully!"
echo ""
echo "📧 Email sending is now configured with:"
echo "   📮 Host: smtp.gmail.com"
echo "   👤 User: connect2wedecor@gmail.com"
echo "   📨 From: WeDecor Events <connect2wedecor@gmail.com>"
echo ""
echo "🚀 Next steps:"
echo "   1. Deploy functions: npm run deploy:functions"
echo "   2. Test invite flow in the app"
echo "   3. Check that emails are sent automatically"
echo ""
echo "⚠️  Note: Gmail app password is configured for automatic email delivery"






