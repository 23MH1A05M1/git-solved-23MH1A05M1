#!/usr/bin/env bash
# Unified Deployment Script - supports production, development, and experimental profiles
# Resolution: keep production config as primary, add development and experimental as separate profiles
# Usage:
#   ./deploy.sh                # defaults to production
#   ./deploy.sh production
#   ./deploy.sh development
#   ./deploy.sh experimental
#   DEPLOY_ENV=development ./deploy.sh

set -euo pipefail

# --- Determine environment (production by default) ---
DEPLOY_ARG="${1:-}"
DEPLOY_ENV="${DEPLOY_ARG:-${DEPLOY_ENV:-production}}"  # precedence: arg > env var > default

# Normalize to lowercase
DEPLOY_ENV="$(echo "$DEPLOY_ENV" | tr '[:upper:]' '[:lower:]')"

echo "====================================="
echo "DevOps Simulator - Deploy ($DEPLOY_ENV)"
echo "====================================="

# --- Common pre-deployment checks ---
CONFIG_FILE="config/app-config.yaml"
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Error: Configuration file not found at '$CONFIG_FILE'."
  exit 1
fi

# Helper: wait-for-http <url> <retries> <delay>
wait_for_http() {
  local url="$1"; local retries="${2:-12}"; local delay="${3:-5}"
  local i=0
  until curl -fsS "$url" >/dev/null 2>&1 || [ "$i" -ge "$retries" ]; do
    i=$((i + 1))
    echo "Waiting for $url (attempt $i/$retries)..."
    sleep "$delay"
  done
  if [ "$i" -ge "$retries" ]; then
    echo "ERROR: $url did not become available after $((retries*delay)) seconds."
    return 1
  fi
  return 0
}

# --- Environment-specific configuration & steps ---
if [ "$DEPLOY_ENV" = "production" ]; then
  DEPLOY_REGION="${DEPLOY_REGION:-us-east-1}"
  APP_PORT="${APP_PORT:-8080}"
  APP_URL="${APP_URL:-https://app.example.com}"
  DOCKER_IMAGE="${DOCKER_IMAGE:-devops-simulator:latest}"
  K8S_DEPLOYMENT="${K8S_DEPLOYMENT:-devops-simulator}"

  echo "Environment: production"
  echo "Region: $DEPLOY_REGION"
  echo "Port: $APP_PORT"
  echo "URL: $APP_URL"

  echo
  echo "Running production pre-deployment steps..."

  if command -v docker >/dev/null 2>&1; then
    echo "Pulling latest Docker image: $DOCKER_IMAGE"
    docker pull "$DOCKER_IMAGE" || echo "Warning: docker pull failed or image not found locally."
  else
    echo "docker not found - skipping docker pull."
  fi

  if command -v kubectl >/dev/null 2>&1; then
    echo "Performing Kubernetes rolling restart for deployment: $K8S_DEPLOYMENT"
    kubectl rollout restart deployment/"$K8S_DEPLOYMENT" || echo "kubectl rollout restart failed; ensure kubectl context is correct."
  else
    echo "kubectl not found - skipping Kubernetes rollout."
  fi

  echo "Production deployment completed (or simulated)."
  echo "Application should be available at: $APP_URL"

elif [ "$DEPLOY_ENV" = "development" ]; then
  APP_PORT="${APP_PORT:-3000}"
  DEPLOY_MODE="${DEPLOY_MODE:-docker-compose}"
  ENABLE_DEBUG="${ENABLE_DEBUG:-true}"
  APP_URL="${APP_URL:-http://localhost:$APP_PORT}"

  echo "Environment: development"
  echo "Mode: $DEPLOY_MODE"
  echo "Port: $APP_PORT"
  echo "Debug: $ENABLE_DEBUG"

  echo
  echo "Running development pre-deployment steps..."

  if [ -f "package.json" ] && command -v npm >/dev/null 2>&1; then
    echo "Installing npm dependencies..."
    npm install
  else
    echo "No package.json or npm not found - skipping npm install."
  fi

  if command -v npm >/dev/null 2>&1 && npm run | grep -q "test"; then
    echo "Running test suite..."
    npm test || { echo "Tests failed. Aborting deployment."; exit 1; }
  else
    echo "No test script detected or npm not available - skipping tests."
  fi

  if [ "$DEPLOY_MODE" = "docker-compose" ] && command -v docker-compose >/dev/null 2>&1; then
    echo "Starting services via docker-compose..."
    docker-compose up -d
  elif [ "$DEPLOY_MODE" = "docker-compose" ]; then
    echo "docker-compose not found - cannot bring up services with docker-compose."
  else
    echo "Deploy mode '$DEPLOY_MODE' is not recognized; skipping compose step."
  fi

  echo "Waiting for application to be ready at $APP_URL ..."
  if wait_for_http "$APP_URL/health" 12 5; then
    echo "Health check passed."
  else
    echo "Health check failed. See container logs or local server output for details."
    exit 1
  fi

  echo "Development deployment completed successfully!"
  echo "Application available at: $APP_URL"
  if [ "$ENABLE_DEBUG" = "true" ] || [ "$ENABLE_DEBUG" = "1" ]; then
    echo "Hot reload / debug mode is enabled (if supported by your stack)."
  fi

elif [ "$DEPLOY_ENV" = "experimental" ]; then
  # --- Experimental AI-Powered Deployment ---
  echo "================================================"
  echo "DevOps Simulator - EXPERIMENTAL AI-POWERED DEPLOY"
  echo "================================================"

  DEPLOY_STRATEGY="canary"
  DEPLOY_CLOUDS=("aws" "azure" "gcp")
  AI_OPTIMIZATION=true
  CHAOS_TESTING=false

  echo "Environment: experimental"
  echo "Strategy: $DEPLOY_STRATEGY"
  echo "Target Clouds: ${DEPLOY_CLOUDS[@]}"
  echo "AI Optimization: $AI_OPTIMIZATION"

  if [ "$AI_OPTIMIZATION" = true ]; then
      echo "🤖 Running AI pre-deployment analysis..."
      python3 scripts/ai-analyzer.py --analyze-deployment || echo "AI analysis skipped (script not found)."
      echo "✓ AI analysis complete"
  fi

  echo "Running advanced pre-deployment checks..."
  for cloud in "${DEPLOY_CLOUDS[@]}"; do
      echo "Validating $cloud configuration..."
  done

  echo "Starting multi-cloud deployment..."
  for cloud in "${DEPLOY_CLOUDS[@]}"; do
      echo "Deploying to $cloud..."
      echo "✓ $cloud deployment initiated"
  done

  echo "Initiating canary deployment strategy..."
  echo "- 10% traffic to new version"
  sleep 2
  echo "- 50% traffic to new version"
  sleep 2
  echo "- 100% traffic to new version"

  if [ "$AI_OPTIMIZATION" = true ]; then
      echo "🤖 AI monitoring activated"
      echo "- Anomaly detection: ACTIVE"
      echo "- Auto-rollback: ENABLED"
      echo "- Performance optimization: LEARNING"
  fi

  if [ "$CHAOS_TESTING" = true ]; then
      echo "⚠️  Running chaos engineering tests..."
  fi

  echo "================================================"
  echo "Experimental deployment completed!"
  echo "AI Dashboard: https://ai.example.com"
  echo "Multi-Cloud Status: https://clouds.example.com"
  echo "================================================"

else
  echo "Unknown DEPLOY_ENV: '$DEPLOY_ENV'. Supported values: production, development, experimental"
  exit 2
fi

echo
echo "Post-deployment: remember to check logs, monitoring dashboards and alerting."
echo "Done."
