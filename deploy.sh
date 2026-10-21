#!/usr/bin/env bash
set -euo pipefail

DEPLOY_PATH="${DEPLOY_PATH:-/home/rizal/samudra}"

echo "🚀 [1/4] Masuk ke direktori: $DEPLOY_PATH/backend"
cd "$DEPLOY_PATH/backend"

echo "🐳 [2/4] Build image Docker backend..."
docker compose build samudra-backend

echo "🔄 [3/4] Recreate kontainer samudra-backend..."
docker compose up -d --force-recreate samudra-backend

echo "🧹 [4/4] Bersihkan image dangling..."
docker image prune -f

echo "✅ [Selesai] Status kontainer:"
docker compose ps samudra-backend
