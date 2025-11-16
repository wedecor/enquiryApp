#!/usr/bin/env bash
set -euo pipefail

echo "🔧 Setting up Node.js v20 for Firebase Functions..."

if command -v nvm >/dev/null 2>&1; then
  echo "📦 Installing Node.js v20 via nvm..."
  nvm install 20
  nvm use 20
  echo "✅ Switched to Node.js v20"
else
  echo "⚠️ nvm not found. Ensure your Node is v20: $(node -v 2>/dev/null || echo 'not installed')"
  echo "💡 Current Node version: $(node -v 2>/dev/null || echo 'not installed')"
  
  if [[ "$(node -v 2>/dev/null)" != "v20."* ]]; then
    echo "❌ Node.js v20 required for Firebase Functions"
    echo "🔗 Install nvm: https://github.com/nvm-sh/nvm#installation-and-update"
    exit 1
  fi
fi

echo "🎯 Current Node version: $(node -v)"
echo "✅ Ready for Firebase Functions development!"











