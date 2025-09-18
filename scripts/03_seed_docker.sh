#!/bin/bash
set -euo pipefail

echo "🐳 WeDecor Docker Seeding"
echo ""

# Check if Docker is available
if ! command -v docker >/dev/null 2>&1; then
    echo "❌ Docker not found. Install from: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose >/dev/null 2>&1 && ! docker compose version >/dev/null 2>&1; then
    echo "❌ docker-compose not found. Install Docker Compose."
    exit 1
fi

# Use docker compose (modern) or docker-compose (legacy)
COMPOSE_CMD="docker compose"
if ! docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD="docker-compose"
fi

echo "✅ Docker available"

# Check required files
if [[ ! -f ".env" ]]; then
    echo "❌ .env file not found"
    echo "   Create it with: echo 'ADMIN_UID=your_firebase_auth_uid' > .env"
    exit 1
fi

if [[ ! -f "serviceAccountKey.json" ]]; then
    echo "❌ serviceAccountKey.json not found"
    echo "   Create it with: ./scripts/01_create_service_account_and_key.sh"
    exit 1
fi

echo "✅ Required files found"

# Build and run seeder
echo "🌱 Running seeder in Docker..."
$COMPOSE_CMD run --rm seeder || {
    echo "❌ Docker seeding failed"
    exit 1
}

echo ""
echo "🎉 Docker seeding completed successfully!"
echo ""
echo "🎯 Next steps:"
echo "   1. Restart your Flutter app"
echo "   2. Loading symbols should be eliminated"
echo "   3. All dropdowns should work perfectly"

