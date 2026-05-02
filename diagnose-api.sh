#!/bin/bash

# EchoVault API Connection Diagnostic Script
# Helps troubleshoot the "API Failed 5000" error

echo "╔════════════════════════════════════════╗"
echo "║  EchoVault API Diagnostics             ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get backend URL from user or use default
BACKEND_URL="${1:-http://localhost:5000}"

echo -e "${BLUE}Testing backend: ${BACKEND_URL}${NC}"
echo ""

# Test 1: Basic connectivity
echo -e "${BLUE}[1/5] Testing basic connectivity...${NC}"
if curl -s -m 5 "${BACKEND_URL}" > /dev/null 2>&1; then
  echo -e "${GREEN}✓ Backend is reachable${NC}"
else
  echo -e "${RED}✗ Cannot reach backend at ${BACKEND_URL}${NC}"
  echo "  Make sure your backend is running and the URL is correct"
  exit 1
fi
echo ""

# Test 2: Health check endpoint
echo -e "${BLUE}[2/5] Checking health endpoint...${NC}"
HEALTH_RESPONSE=$(curl -s -w "\n%{http_code}" "${BACKEND_URL}/api/health" 2>/dev/null)
HTTP_CODE=$(echo "$HEALTH_RESPONSE" | tail -n 1)
BODY=$(echo "$HEALTH_RESPONSE" | head -n -1)

if [ "$HTTP_CODE" = "200" ]; then
  echo -e "${GREEN}✓ Health check passed (HTTP 200)${NC}"
  echo "  Response: $BODY"
else
  echo -e "${YELLOW}⚠ Health endpoint returned HTTP $HTTP_CODE${NC}"
  if [ "$HTTP_CODE" = "404" ]; then
    echo "  Endpoint not found - your backend may not have /api/health"
  fi
fi
echo ""

# Test 3: CORS headers
echo -e "${BLUE}[3/5] Checking CORS headers...${NC}"
CORS_ORIGIN=$(curl -s -i -X OPTIONS "${BACKEND_URL}/api" 2>/dev/null | grep -i "access-control-allow-origin" | head -1)

if [ ! -z "$CORS_ORIGIN" ]; then
  echo -e "${GREEN}✓ CORS is configured${NC}"
  echo "  $CORS_ORIGIN"
else
  echo -e "${RED}✗ CORS headers not found${NC}"
  echo "  Add CORS middleware to your Express backend:"
  echo "  app.use(cors({ origin: '*' }));"
fi
echo ""

# Test 4: WebSocket connectivity
echo -e "${BLUE}[4/5] Checking WebSocket (Socket.IO)...${NC}"

# Extract host and port from URL
if [[ $BACKEND_URL =~ http://([^:/]+):([0-9]+) ]]; then
  HOST="${BASH_REMATCH[1]}"
  PORT="${BASH_REMATCH[2]}"
elif [[ $BACKEND_URL =~ http://([^/:]+) ]]; then
  HOST="${BASH_REMATCH[1]}"
  PORT="80"
else
  HOST="localhost"
  PORT="5000"
fi

echo "  Checking if port $PORT is open on $HOST..."
if timeout 2 bash -c "echo >/dev/tcp/$HOST/$PORT" 2>/dev/null; then
  echo -e "${GREEN}✓ Port $PORT is open${NC}"
else
  echo -e "${RED}✗ Cannot connect to port $PORT${NC}"
  echo "  Make sure your backend is listening on port $PORT"
fi
echo ""

# Test 5: Sample API call
echo -e "${BLUE}[5/5] Testing sample API endpoint...${NC}"
API_RESPONSE=$(curl -s -w "\n%{http_code}" "${BACKEND_URL}/api/gifts" 2>/dev/null)
HTTP_CODE=$(echo "$API_RESPONSE" | tail -n 1)

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "401" ]; then
  echo -e "${GREEN}✓ API is responding (HTTP $HTTP_CODE)${NC}"
else
  echo -e "${YELLOW}⚠ API returned HTTP $HTTP_CODE${NC}"
fi
echo ""

# Summary and recommendations
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}Recommendations:${NC}"
echo ""
echo "1. Update Flutter config with backend URL:"
echo "   File: lib/config/api_config.dart"
echo "   Change: return 'https://echovault-backend.azurewebsites.net/api';"
echo ""
echo "2. Ensure backend CORS is enabled:"
echo "   const cors = require('cors');"
echo "   app.use(cors({ origin: '*' }));"
echo ""
echo "3. Rebuild Flutter app:"
echo "   flutter clean && flutter pub get && flutter build web --release"
echo ""
echo "4. Rebuild Docker image:"
echo "   docker build -f Dockerfile.prod -t echovault:latest ."
echo ""
echo "5. Push to Azure:"
echo "   docker tag echovault:latest echovaultacr.azurecr.io/echo-vault-frontend:latest"
echo "   docker push echovaultacr.azurecr.io/echo-vault-frontend:latest"
echo ""
echo "6. Restart Azure container:"
echo "   az container restart --resource-group echovault-rg --name echovault-frontend"
echo ""
