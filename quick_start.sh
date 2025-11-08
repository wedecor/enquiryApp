#!/bin/bash

# Quick Start Script for WeDecor Enquiries App
# This script runs the essential commands to get the app running quickly

set -e

echo "⚡ WeDecor Enquiries - Quick Start"
echo "================================="

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}📦 Installing dependencies...${NC}"
flutter pub get

echo -e "${BLUE}🔧 Generating code...${NC}"
flutter packages pub run build_runner build --delete-conflicting-outputs

echo -e "${BLUE}🔍 Checking available devices...${NC}"
flutter devices

echo ""
echo -e "${GREEN}✅ Quick start completed!${NC}"
echo ""
echo "🚀 To run the app:"
echo "  flutter run                 # Run on any device"
echo "  flutter run -d chrome       # Run on web"
echo "  flutter run -d android      # Run on Android"
echo ""
echo "📋 Need full setup? Run: ./setup.sh"






