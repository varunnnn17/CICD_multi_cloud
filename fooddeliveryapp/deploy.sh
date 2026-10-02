#!/bin/bash

# ==============================================================================
# Multi-Cloud Application Deployment Script - AWS EC2
#
# Docker image is supplied by Jenkins.
#
# AWS public access:
#   Port 80
#
# Spring Boot application inside Docker:
#   Port 8083
#
# Usage:
#   ./deploy.sh <docker_image>
# ==============================================================================

set -euo pipefail

IMAGE_NAME="${1:-${IMAGE_NAME:-}}"

CONTAINER_NAME="food-delivery"

# Spring Boot application port inside the container
APP_PORT="8083"

# Public HTTP port on AWS EC2
HOST_PORT="80"

if [ -z "$IMAGE_NAME" ]; then
    echo "ERROR: Docker image name was not provided."
    echo "Usage: ./deploy.sh <image_name>"
    exit 1
fi

echo "============================================================"
echo "Starting AWS EC2 deployment"
echo "============================================================"
echo "Docker Image : $IMAGE_NAME"
echo "Container    : $CONTAINER_NAME"
echo "Public Port  : $HOST_PORT"
echo "App Port     : $APP_PORT"
echo "============================================================"

echo ""
echo "--> Pulling Docker image: $IMAGE_NAME..."

docker pull "$IMAGE_NAME"

echo "--> Docker image pulled successfully."

echo ""
echo "--> Checking for existing container..."

if [ "$(docker ps -q -f name=^/${CONTAINER_NAME}$)" ]; then

    echo "--> Stopping existing container: $CONTAINER_NAME..."

    docker stop "$CONTAINER_NAME"
fi

if [ "$(docker ps -aq -f name=^/${CONTAINER_NAME}$)" ]; then

    echo "--> Removing existing container: $CONTAINER_NAME..."

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

echo ""
echo "============================================================"
echo "AWS EC2 DEPLOYMENT SUCCESSFUL"
echo "============================================================"
echo "Container       : $CONTAINER_NAME"
echo "Docker Image    : $IMAGE_NAME"
echo "Public HTTP Port: $HOST_PORT"
echo "Container Port  : $APP_PORT"
echo "Container Status: Running"
echo ""
echo "AWS application is available through:"
echo "http://<EC2_ELASTIC_IP>"
echo "============================================================"

exit 0