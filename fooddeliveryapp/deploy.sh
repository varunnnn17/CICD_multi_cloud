#!/bin/bash

# ==============================================================================
# Deployment Script for Food Delivery Application on AWS EC2
# Application runs on port 8083
# ==============================================================================

set -euo pipefail

# Configuration
IMAGE_NAME="${1:-${IMAGE_NAME:-}}"
CONTAINER_NAME="food-delivery"
APP_PORT="8083"

if [ -z "$IMAGE_NAME" ]; then
    echo "ERROR: Image name not provided."
    echo "Usage: ./deploy.sh <image_name>"
    exit 1
fi

echo "============================================================"
echo "Starting deployment for: $IMAGE_NAME"
echo "Target Container: $CONTAINER_NAME"
echo "Target Port: $APP_PORT"
echo "============================================================"

# Step 1: Pull Docker image
echo "--> Pulling Docker image: $IMAGE_NAME..."
docker pull "$IMAGE_NAME"

# Step 2: Stop existing container if running
echo "--> Stopping existing container ($CONTAINER_NAME) if running..."

if [ "$(docker ps -q -f name=^/${CONTAINER_NAME}$)" ]; then
    docker stop "$CONTAINER_NAME"
fi

# Step 3: Remove existing container
if [ "$(docker ps -aq -f name=^/${CONTAINER_NAME}$)" ]; then
    echo "--> Removing existing container ($CONTAINER_NAME)..."
    docker rm -f "$CONTAINER_NAME"
fi

# Step 4: Start new container
echo "--> Launching new container ($CONTAINER_NAME) on port $APP_PORT..."

docker run -d \
    --name "$CONTAINER_NAME" \
    --restart unless-stopped \
    -p "${APP_PORT}:${APP_PORT}" \
    -e SERVER_PORT="${APP_PORT}" \
    "$IMAGE_NAME"

# Step 5: Verify container is running
echo "--> Verifying container is running..."

if ! docker ps -f name=^/${CONTAINER_NAME}$ --format '{{.Status}}' | grep -i "Up"; then
    echo "ERROR: Container $CONTAINER_NAME failed to start!"
    docker logs "$CONTAINER_NAME" --tail 50
    exit 1
fi

echo "============================================================"
echo "APPLICATION DEPLOYMENT SUCCESSFUL"
echo "============================================================"
echo "Container : $CONTAINER_NAME"
echo "Port      : $APP_PORT"
echo "Image     : $IMAGE_NAME"
echo "Status    : Running"
echo "============================================================"

exit 0