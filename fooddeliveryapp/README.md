# Food Delivery Application - CI/CD & Production Deployment Guide

A production-ready Spring Boot microservice application featuring complete containerization, automated testing, and CI/CD deployment to AWS EC2 via Jenkins.

---

## 1. Project Overview

The **Food Delivery Application** is a Spring Boot web application providing an online ordering portal with an interactive menu, shopping cart, checkout flow, simulated payment gateway, and order administration.

### Architecture Highlights
- **Framework**: Spring Boot 3.5.x / Java 17 LTS
- **Templating**: Thymeleaf + HTML5/CSS3
- **Data Persistence**: Spring Data JPA with Hibernate
- **Database**: H2 In-Memory (development default with automatic schema initialization and preloaded catalog); fully configurable for MySQL/PostgreSQL in production via environment variables.
- **Monitoring & Observability**: Spring Boot Actuator exposing `/actuator/health` and `/actuator/info`.
- **Target Deployment**: AWS EC2 (`t3.micro`, Region: `us-east-1`, Public IP: `3.89.36.223`) on dedicated port **8083**.
- **CI/CD Automation**: Jenkins 2.541.2 on port **8082** using declarative pipelines.

---

## 2. Requirements

- **Operating System**: Linux (Ubuntu 22.04 LTS recommended for Jenkins agents and EC2) or Windows (development)
- **Java Development Kit (JDK)**: OpenJDK / Eclipse Temurin 17 LTS
- **Build Tool**: Apache Maven 3.9+ (or included `./mvnw` wrapper)
- **Container Runtime**: Docker Engine 24+ & Docker Compose v2+
- **CI/CD Server**: Jenkins 2.541.2+ (listening on `localhost:8082`)
- **Remote Access**: OpenSSH Client / Server (`ssh`, `scp`)
- **Cloud Infrastructure**: AWS EC2 instance (`t3.micro`)

---

## 3. Java Version

The project requires **Java 17 LTS**. Verify your installation:

```bash
java -version
```

Expected output:
```text
openjdk version "17.0.12" ...
OpenJDK Runtime Environment ...
```

---

## 4. Maven Version

The project supports both standalone Apache Maven 3.9+ and the bundled Maven Wrapper:

```bash
# Standalone Maven
mvn -version

# Maven Wrapper (Linux / macOS)
./mvnw -version

# Maven Wrapper (Windows PowerShell)
.\mvnw.cmd -version
```

---

## 5. Local Development

### Configuration
By default, the application runs on port `8083` using an in-memory H2 database.

> [!NOTE]
> In-memory H2 data is retained while the application runs and is reset upon restart. Pre-seeded food items are automatically inserted at startup if the catalog is empty.

To override configurations locally, copy `.env.example` to `.env` or set environment variables:

```bash
cp .env.example .env
```

Key environment variables:
- `SERVER_PORT`: Application HTTP port (default: `8083`)
- `SPRING_DATASOURCE_URL`: JDBC database connection URL
- `SPRING_DATASOURCE_USERNAME`: Database username
- `SPRING_DATASOURCE_PASSWORD`: Database password

---

## 6. Running Tests

Run all unit, integration, and Spring Boot context tests without skipping:

```bash
# Linux / macOS
./mvnw clean test

# Windows
.\mvnw.cmd clean test
```

### Test Coverage Summary
- `FoodDeliveryApplicationTests`: Verifies Spring Boot application context startup.
- `ActuatorHealthTest`: Validates that `GET /actuator/health` responds with HTTP 200 and `{"status":"UP"}`.
- `HomeControllerTest`: Tests home page rendering, cart operations, and checkout redirection.
- `FoodServiceTest`: Unit tests for catalog item queries and price calculations.

---

## 7. Running with Maven

To start the application locally with Maven:

```bash
# Linux / macOS
./mvnw spring-boot:run

# Windows
.\mvnw.cmd spring-boot:run
```

Package the executable Spring Boot JAR:

```bash
./mvnw clean package
```

The repackaged executable JAR will be located at:
`target/food-delivery-app-0.0.1-SNAPSHOT.jar`

Run the packaged JAR directly:

```bash
java -jar target/food-delivery-app-0.0.1-SNAPSHOT.jar
```

---

## 8. Building Docker Image

The application uses a secure, multi-stage Linux-compatible Dockerfile:
- **Build Stage**: `maven:3.9.6-eclipse-temurin-17` compiles and packages the app.
- **Runtime Stage**: `eclipse-temurin:17-jre-alpine` runs the application under a non-root user (`appuser`).
- **Exposed Port**: `8083`
- **Container Healthcheck**: Configured against `/actuator/health`.

Build the image locally:

```bash
docker build -t food-delivery:local .
```

---

## 9. Running Docker

Run the container in detached mode:

```bash
docker run -d \
  --name food-delivery \
  --restart unless-stopped \
  -p 8083:8083 \
  food-delivery:local
```

Verify container logs:

```bash
docker logs -f food-delivery
```

Stop and remove container:

```bash
docker stop food-delivery && docker rm food-delivery
```

---

## 10. Docker Compose

Run the entire application stack using Docker Compose:

```bash
# Validate configuration
docker compose config

# Build and start services in background
docker compose up -d --build

# Inspect running containers
docker compose ps

# View service logs
docker compose logs -f app

# Tear down services
docker compose down
```

The application will be accessible at `http://localhost:8083`.

---

## 11. Jenkins Configuration

Jenkins must be installed and running on port **8082**.

### Pipeline Setup
1. Open Jenkins at `http://localhost:8082`.
2. Navigate to **New Item** -> Enter `food-delivery-pipeline` -> Select **Pipeline** -> Click **OK**.
3. In the Pipeline configuration:
   - **Definition**: `Pipeline script from SCM`
   - **SCM**: `Git`
   - **Repository URL**: Your Git repository URL (e.g. `https://github.com/manyasreeya/fooddeliveryapp.git`)
   - **Branch Specifier**: `*/main`
   - **Script Path**: `Jenkinsfile`
4. Save the job.

---

## 12. Required Jenkins Credentials

Configure the following credentials in Jenkins (**Manage Jenkins** -> **Credentials** -> **System** -> **Global credentials**):

| Credential ID | Kind | Description / Usage |
| :--- | :--- | :--- |
| `dockercred1` | **Username with password** | Docker Hub account username and Personal Access Token / password. |
| `ec2-ssh-key` | **SSH Username with private key** | Username: `ubuntu` (or `ec2-user`), Private Key: AWS EC2 `.pem` key file. |

> [!CAUTION]
> Never commit `.pem` private keys or raw passwords into Git. Always inject them securely via Jenkins credentials.

---

## 13. Docker Hub Configuration

The Jenkins pipeline pushes images to Docker Hub:
- **Image Pattern**: `<DOCKERHUB_USER>/<IMAGE_NAME>:<BUILD_NUMBER>`
- **Latest Tag**: `<DOCKERHUB_USER>/<IMAGE_NAME>:latest`

Default values configured in the pipeline:
- `DOCKERHUB_USER`: `manyasreeya` (overridable per build parameter)
- `IMAGE_NAME`: `food-delivery`

---

## 14. AWS EC2 Requirements

- **Instance Type**: `t3.micro`
- **Region**: `us-east-1`
- **Target Public IP**: `3.89.36.223`
- **Operating System**: Ubuntu 22.04 LTS / Amazon Linux 2023
- **Prerequisites on EC2**:
  - Docker installed and running:
    ```bash
    sudo apt update && sudo apt install -y docker.io curl
    sudo systemctl enable --now docker
    sudo usermod -aG docker ubuntu
    ```

---

## 15. EC2 Deployment

The deployment is automated and idempotent via `deploy.sh`:

1. Jenkins securely authenticates via SSH into `ubuntu@3.89.36.223` using `ec2-ssh-key`.
2. Jenkins transfers `deploy.sh` to `/home/ubuntu/deploy.sh`.
3. Jenkins triggers the deployment script on the EC2 host:
   ```bash
   chmod +x deploy.sh && ./deploy.sh <DOCKERHUB_USER>/food-delivery:<BUILD_NUMBER>
   ```

### Idempotent Deployment Steps Executed on EC2:
1. Pulls the new Docker image from Docker Hub.
2. Stops and removes any pre-existing container named `food-delivery`.
3. Launches the new container with `--restart unless-stopped` mapping `8083:8083`.
4. Validates container status with `docker ps`.
5. Runs a local Actuator health check loop.

---

## 16. Health Check

The application exposes Spring Boot Actuator health status at:
`http://<EC2_IP>:8083/actuator/health`

### Automated Retry Mechanism
After deployment, Jenkins polls the health check endpoint:
- **Interval**: 5 seconds
- **Max Retries**: 12 attempts (total 60 seconds)
- **Success Criteria**: HTTP status code `200` with `{"status":"UP"}`

Expected JSON response:
```json
{
  "status": "UP",
  "components": {
    "db": {
      "status": "UP",
      "details": {
        "database": "H2",
        "validationQuery": "isValid()"
      }
    },
    "diskSpace": {
      "status": "UP"
    },
    "ping": {
      "status": "UP"
    }
  }
}
```

If the endpoint does not return HTTP 200 within 12 attempts, the Jenkins build fails and displays container logs.

---

## 17. Kubernetes Optional Deployment

Kubernetes manifests are located in `k8s/`:
- `k8s/configmap.yaml`: Configures `SERVER_PORT=8083` and active profiles.
- `k8s/deployment.yaml`: Defines 2 replicas, rolling updates, resource limits, and `startupProbe`, `readinessProbe`, and `livenessProbe` on port `8083`.
- `k8s/service.yaml`: Exposes the service via LoadBalancer on port `8083`.

### Conditional Pipeline Execution
In Jenkins, the build parameter `K8S_ENABLED` defaults to `false`.
When `K8S_ENABLED=false`:
- The Kubernetes stage is cleanly skipped.
When `K8S_ENABLED=true`:
- Jenkins verifies `kubectl` and cluster connectivity.
- Applies manifests and waits for rollout:
  ```bash
  kubectl apply -f k8s/configmap.yaml
  kubectl apply -f k8s/deployment.yaml
  kubectl apply -f k8s/service.yaml
  kubectl rollout status deployment/fooddelivery-deployment --timeout=180s
  ```

---

## 18. Troubleshooting

### Application Port Collision
- **Symptom**: `Port 8082 was already in use`
- **Cause**: Port 8082 is reserved for Jenkins.
- **Fix**: The application is configured to run strictly on port **8083**. Ensure `server.port=8083` in `application.properties` and Docker port mapping is `8083:8083`.

### Health Check Timeout on EC2
- **Symptom**: Jenkins displays `Application deployment failed - Health check timed out`.
- **Cause**: Security Group rule blocking port 8083, or Docker container crashed.
- **Fix**:
  1. Check AWS Security Group inbound rules for port `8083`.
  2. SSH to EC2: `ssh -i key.pem ubuntu@3.89.36.223`
  3. Inspect container logs: `docker logs food-delivery --tail 100`

### Docker Hub Push Authentication Failure
- **Symptom**: `denied: requested access to the resource is denied`
- **Cause**: Incorrect Docker Hub credentials or lack of repository write permissions.
- **Fix**: Verify credential `dockercred1` in Jenkins. Ensure the Docker Hub username matches the `DOCKERHUB_USER` pipeline parameter.

---

## 19. Ports & Security Group Rules

### Port Allocation Summary

| Service | Port | Protocol | Purpose | Access Scope |
| :--- | :--- | :--- | :--- | :--- |
| **Jenkins** | `8082` | TCP | Jenkins CI/CD Dashboard | Restricted (Admin IP / Localhost) |
| **Food Delivery App** | `8083` | TCP | Web UI & API traffic | Public / Inbound HTTP |
| **Actuator Health** | `8083` | TCP | `/actuator/health` endpoint | Jenkins / Monitoring |
| **SSH** | `22` | TCP | Remote EC2 Administration | Jenkins Server / Admin IP |

### AWS EC2 Security Group Inbound Configuration
Ensure the Security Group attached to instance `3.89.36.223` has the following inbound rules:

1. **SSH**: Port `22` -> Source: `Jenkins Agent IP` (or restricted admin CIDR)
2. **Custom TCP**: Port `8083` -> Source: `0.0.0.0/0` (for public web access)
