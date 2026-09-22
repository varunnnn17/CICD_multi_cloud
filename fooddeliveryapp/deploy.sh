#!/bin/bash
# ==============================================================================
# Idempotent Deployment Script for Food Delivery Application on AWS EC2
# Exposes application on port 8083 (avoiding Jenkins port 8082)
# ==============================================================================

set -euo pipefail

# Configuration
IMAGE_NAME="${1:-${IMAGE_NAME:-}}"
CONTAINER_NAME="food-delivery"
APP_PORT="8083"
MAX_RETRIES=12
RETRY_INTERVAL=5

if [ -z "$IMAGE_NAME" ]; then
    echo "ERROR: Image name not provided. Usage: ./deploy.sh <image_name>"
    exit 1
fi

echo "============================================================"
echo "Starting deployment for: $IMAGE_NAME"
echo "Target Container: $CONTAINER_NAME"
echo "Target Port: $APP_PORT"
echo "============================================================"

# Step 1: Pull the latest image
echo "--> Pulling Docker image: $IMAGE_NAME..."
docker pull "$IMAGE_NAME"

# Step 2: Stop and remove existing container if present
echo "--> Stopping existing container ($CONTAINER_NAME) if running..."
if [ "$(docker ps -q -f name=^/${CONTAINER_NAME}$)" ]; then
    docker stop "$CONTAINER_NAME"
fi

if [ "$(docker ps -aq -f name=^/${CONTAINER_NAME}$)" ]; then
    echo "--> Removing existing container ($CONTAINER_NAME)..."
    docker rm -f "$CONTAINER_NAME"
fi

# Step 3: Start new container
echo "--> Launching new container ($CONTAINER_NAME) on port $APP_PORT..."
docker run -d \
    --name "$CONTAINER_NAME" \
    --restart unless-stopped \
    -p "${APP_PORT}:${APP_PORT}" \
    -e SERVER_PORT="${APP_PORT}" \
    "$IMAGE_NAME"

# Step 4: Verify container state
echo "--> Verifying container is running..."
if ! docker ps -f name=^/${CONTAINER_NAME}$ --format '{{.Status}}' | grep -i "Up"; then
    echo "ERROR: Container $CONTAINER_NAME failed to start!"
    docker logs "$CONTAINER_NAME" --tail 50
    exit 1
fi

# Step 5: Perform Actuator Health Check with retries
echo "--> Performing local Actuator health check on http://localhost:${APP_PORT}/actuator/health..."
HEALTHY=false

for i in $(seq 1 $MAX_RETRIES); do
    echo "    Attempt $i of $MAX_RETRIES: Checking health..."
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:${APP_PORT}/actuator/health" || true)
    
    if [ "$HTTP_STATUS" = "200" ]; then
        echo "--> Health check returned HTTP 200 OK!"
        HEALTHY=true
        break
    else
        echo "    Health check returned HTTP $HTTP_STATUS, retrying in ${RETRY_INTERVAL}s..."
        sleep $RETRY_INTERVAL
    fi
done

if [ "$HEALTHY" = "true" ]; then
    echo "============================================================"
    echo "Application deployment successful!"
    echo "Food Delivery App is running at port $APP_PORT"
    echo "============================================================"
    exit 0
else
    echo "============================================================"
    echo "ERROR: Application deployment failed! Health check timed out."
    echo "============================================================"
    docker logs "$CONTAINER_NAME" --tail 100
    exit 1
fi
