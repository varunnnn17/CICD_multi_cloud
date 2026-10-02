#!/bin/bash

set -euo pipefail

IMAGE_NAME="${1:-}"

CONTAINER_NAME="food-delivery"
APP_PORT="8083"
HOST_PORT="80"

if [ -z "$IMAGE_NAME" ]; then
    echo "ERROR: Docker image name was not provided."
    echo "Usage: ./deploy.sh <image_name>"
    exit 1
fi

echo "============================================================"
echo "Starting deployment for Food Delivery Application"
echo "============================================================"
echo ""
echo "Docker Image : $IMAGE_NAME"
echo "Container    : $CONTAINER_NAME"
echo "Host Port    : $HOST_PORT"
echo "App Port     : $APP_PORT"
echo "============================================================"

echo ""
echo "--> Pulling Docker image..."
docker pull "$IMAGE_NAME"

echo "--> Docker image pulled successfully."

echo ""
echo "--> Checking existing container..."

if docker ps -q -f "name=^/${CONTAINER_NAME}$" | grep -q .; then
    echo "--> Stopping existing container..."
    docker stop "$CONTAINER_NAME"
fi

if docker ps -aq -f "name=^/${CONTAINER_NAME}$" | grep -q .; then
    echo "--> Removing existing container..."
    docker rm -f "$CONTAINER_NAME"
fi

echo "--> Existing container removed."

echo ""
echo "--> Starting new Docker container..."

docker run -d \
    --name "$CONTAINER_NAME" \
    --restart unless-stopped \
    -p "${HOST_PORT}:${APP_PORT}" \
    -e SERVER_PORT="${APP_PORT}" \
    "$IMAGE_NAME"

echo "--> Docker container started."

echo ""
echo "--> Checking container status..."

if ! docker ps \
    -f "name=^/${CONTAINER_NAME}$" \
    --format '{{.Status}}' | grep -qi "Up"; then

    echo ""
    echo "ERROR: Container failed to start."

    echo ""
    echo "Container logs:"
    docker logs "$CONTAINER_NAME" --tail 50 || true

    exit 1
fi

echo ""
echo "============================================================"
echo "APPLICATION DEPLOYMENT SUCCESSFUL"
echo "============================================================"
echo ""
echo "Container       : $CONTAINER_NAME"
echo "Docker Image    : $IMAGE_NAME"
echo "Host Port       : $HOST_PORT"
echo "Container Port  : $APP_PORT"
echo "Container Status: Running"
echo ""
echo "AWS application is running on port $HOST_PORT."
echo "============================================================"

exit 0