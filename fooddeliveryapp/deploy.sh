#!/bin/bash

# ==============================================================================
# Deployment Script for Food Delivery Application on AWS EC2
#
# External access:
#   http://100.62.122.237
#
# EC2 port:
#   80
#
# Docker container port:
#   8083
# ==============================================================================

set -euo pipefail

# ==============================================================================
# Configuration
# ==============================================================================

IMAGE_NAME="${1:-${IMAGE_NAME:-}}"

CONTAINER_NAME="food-delivery"

# Spring Boot application port inside the container
APP_PORT="8083"

# Public HTTP port on EC2
HOST_PORT="80"

# ==============================================================================
# Validation
# ==============================================================================

if [ -z "$IMAGE_NAME" ]; then
    echo "ERROR: Image name not provided."
    echo "Usage: ./deploy.sh <image_name>"
    exit 1
fi

echo "============================================================"
echo "Starting deployment for Food Delivery Application"
echo "============================================================"
echo "Docker Image : $IMAGE_NAME"
echo "Container    : $CONTAINER_NAME"
echo "EC2 Port     : $HOST_PORT"
echo "App Port     : $APP_PORT"
echo "============================================================"

# ==============================================================================
# Step 1: Pull Docker image
# ==============================================================================

echo ""
echo "--> Pulling Docker image: $IMAGE_NAME..."

docker pull "$IMAGE_NAME"

echo "--> Docker image pulled successfully."

# ==============================================================================
# Step 2: Stop existing container
# ==============================================================================

echo ""
echo "--> Checking for existing container..."

if [ "$(docker ps -q -f name=^/${CONTAINER_NAME}$)" ]; then
    echo "--> Stopping existing container: $CONTAINER_NAME..."
    docker stop "$CONTAINER_NAME"
fi

# ==============================================================================
# Step 3: Remove existing container
# ==============================================================================

if [ "$(docker ps -aq -f name=^/${CONTAINER_NAME}$)" ]; then
    echo "--> Removing existing container: $CONTAINER_NAME..."
    docker rm -f "$CONTAINER_NAME"
fi

echo "--> Existing container removed."

# ==============================================================================
# Step 4: Start new container
# ==============================================================================

echo ""
echo "--> Starting new Docker container..."

docker run -d \
    --name "$CONTAINER_NAME" \
    --restart unless-stopped \
    -p "${HOST_PORT}:${APP_PORT}" \
    -e SERVER_PORT="${APP_PORT}" \
    "$IMAGE_NAME"

echo "--> Docker container started."

# ==============================================================================
# Step 5: Verify container is running
# ==============================================================================

echo ""
echo "--> Verifying Docker container..."

if ! docker ps \
    -f name=^/${CONTAINER_NAME}$ \
    --format '{{.Status}}' | grep -i "Up"; then

    echo "ERROR: Container $CONTAINER_NAME failed to start!"

    echo ""
    echo "Container logs:"
    docker logs "$CONTAINER_NAME" --tail 50 || true

    exit 1
fi

# ==============================================================================
# Step 6: Display deployment information
# ==============================================================================

echo ""
echo "============================================================"
echo "APPLICATION DEPLOYMENT SUCCESSFUL"
echo "============================================================"
echo "Container       : $CONTAINER_NAME"
echo "Docker Image    : $IMAGE_NAME"
echo "EC2 HTTP Port   : $HOST_PORT"
echo "Container Port  : $APP_PORT"
echo "Container Status: Running"
echo ""
echo "Application URL:"
echo "http://100.62.122.237"
echo "============================================================"

exit 0