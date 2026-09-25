# Multi-Cloud High-Availability CI/CD Platform

A DevOps and cloud engineering project focused on **multi-cloud deployment, high availability, traffic distribution, automated failover, CI/CD, observability, and intelligent incident analysis**.

A simple **food-delivery website is used only as the sample application** for demonstrating the infrastructure and DevOps architecture. The primary purpose of this project is **multi-cloud reliability**, not the food-delivery application itself.

---

## Project Objective

The main objective is to design a system that can continue serving users when traffic suddenly increases or when one cloud environment becomes unavailable.

The application is deployed across two independent cloud environments:

```text
                         Users
                           │
                           ▼
                  Traffic Management
                    /            \
                   /              \
                  ▼                ▼
             AWS EC2            Render
                  │                │
                  └───────┬────────┘
                          │
                    Same Application
                    Same Docker Image
```

The architecture is intended to provide:

- Multi-cloud deployment
- High availability
- Cross-cloud redundancy
- Traffic distribution
- Health-based routing
- Automatic failover
- Horizontal scaling
- Zero/near-zero manual intervention during failures
- Automated CI/CD
- Centralized monitoring
- Intelligent incident analysis

The target is **minimal service interruption during a cloud failure**, rather than claiming literally zero downtime.

---

## Why Multi-Cloud?

A single-cloud deployment creates a dependency on one cloud provider.

The project therefore uses:

```text
Cloud 1 → AWS
Cloud 2 → Render
```

The same containerized application can run in both environments.

If one environment becomes unhealthy, the traffic-management layer can route users toward the healthy environment.

### Normal operation

```text
                  Users
                    │
                    ▼
             Traffic Manager
                /       \
               /         \
              ▼           ▼
           AWS EC2      Render
             ▲             ▲
             └──── Load ───┘
                Distribution
```

### AWS failure scenario

```text
                  Users
                    │
                    ▼
             Traffic Manager
                    │
                    X
                 AWS DOWN
                    │
                    ▼
                  Render
                    │
                    ▼
                 Users
```

### Render failure scenario

```text
                  Users
                    │
                    ▼
             Traffic Manager
                    │
                    X
                Render DOWN
                    │
                    ▼
                  AWS
                    │
                    ▼
                 Users
```

---

## Sample Application

The project uses a **sample food-delivery website** as the workload deployed to the cloud environments.

The website is intentionally simple compared with the infrastructure surrounding it.

Its purpose is to provide a realistic HTTP workload so the project can demonstrate:

- Container deployment
- CI/CD
- Cloud deployment
- Traffic handling
- Health checks
- Monitoring
- Scaling
- Failover
- Recovery

The application itself is therefore a **demonstration workload for the multi-cloud platform**.

---

## High-Level Architecture

```text
                           ┌─────────────────────┐
                           │       GitHub        │
                           │   Source Control    │
                           └──────────┬──────────┘
                                      │
                                      │ Push / Webhook
                                      ▼
                           ┌─────────────────────┐
                           │       Jenkins       │
                           │     CI / CD         │
                           └──────────┬──────────┘
                                      │
                 ┌────────────────────┼────────────────────┐
                 │                    │                    │
                 ▼                    ▼                    ▼
              Maven               SonarQube              Trivy
             Test/Build          Code Quality        Security Scan
                 │                    │                    │
                 └────────────────────┼────────────────────┘
                                      │
                                      ▼
                           ┌─────────────────────┐
                           │       Docker        │
                           │    Image Build      │
                           └──────────┬──────────┘
                                      │
                                      ▼
                           ┌─────────────────────┐
                           │     Docker Hub      │
                           │  Versioned Images   │
                           └──────────┬──────────┘
                                      │
                         ┌────────────┴────────────┐
                         │                         │
                         ▼                         ▼
                ┌─────────────────┐       ┌─────────────────┐
                │     AWS EC2     │       │     Render      │
                │ Docker Runtime  │       │  Web Service    │
                └────────┬────────┘       └────────┬────────┘
                         │                         │
                         └────────────┬────────────┘
                                      │
                                      ▼
                           ┌─────────────────────┐
                           │ Traffic Management  │
                           │ Health + Failover   │
                           └──────────┬──────────┘
                                      │
                                      ▼
                                   Users

                         Observability Layer
                         ────────────────────

                   AWS ──────────┐
                                 ├── Datadog
                   Render ───────┘
                                      │
                                      ▼
                                  Dashboards
                                  & Alerts

                         Incident Intelligence
                         ──────────────────────

                   Logs ──► Python AI Analyzer
                                  │
                         ┌────────┴────────┐
                         ▼                 ▼
                    Root Cause       Fix Suggestion
                         │
                         ▼
                       Alert
```

---

## Core Components

| Component | Role |
|---|---|
| GitHub | Source-code management |
| Jenkins | CI/CD automation |
| Maven | Build and test automation |
| JUnit | Automated testing |
| SonarQube | Code-quality analysis |
| Docker | Application containerization |
| Docker Hub | Container image registry |
| AWS EC2 | Cloud deployment environment 1 |
| Render | Cloud deployment environment 2 |
| Traffic Management | Cross-cloud routing and failover |
| Trivy | Container security scanning |
| Datadog | Monitoring and observability |
| Python | Log analysis and incident intelligence |

---

## CI/CD Pipeline

The pipeline automates the path from source code to both cloud environments.

```text
GitHub
   │
   ▼
Jenkins
   │
   ├── Environment Validation
   │
   ├── Maven Test
   │
   ├── Maven Package
   │
   ├── SonarQube Analysis
   │
   ├── SonarQube Quality Gate
   │
   ├── Docker Build
   │
   ├── Docker Image Validation
   │
   ├── Trivy Security Scan
   │
   ├── Docker Hub Push
   │
   ├── AWS Deployment
   │
   ├── AWS Verification
   │
   ├── Render Deployment
   │
   ├── Render Verification
   │
   └── Multi-Cloud Status
```

The goal is to make deployment repeatable and reduce manual deployment operations.

---

## Versioned Container Images

Jenkins creates versioned Docker images such as:

```text
varun1716/food-delivery:25
```

and also maintains:

```text
varun1716/food-delivery:latest
```

The versioned image is important for multi-cloud consistency.

Both cloud environments should run the **same image version**:

```text
                  Docker Hub
                      │
          ┌───────────┴───────────┐
          ▼                       ▼
       AWS EC2                 Render
          │                       │
          └──── same version ─────┘
```

This prevents AWS and Render from accidentally running different application releases.

---

## AWS Deployment

AWS EC2 is the first cloud environment.

Current deployment configuration:

```text
Cloud: AWS
Service: EC2
User: ubuntu
Application container port: 8083
Public HTTP port: 80
```

The deployment script:

```text
deploy.sh
```

performs:

1. Pull the requested Docker image.
2. Stop the previous container.
3. Remove the previous container.
4. Start the new container.
5. Enable automatic container restart.
6. Map public port 80 to application port 8083.
7. Verify the container is running.

---

## Render Deployment

Render is the second cloud environment.

The Render deployment uses the same Docker image generated by Jenkins.

```text
Jenkins
   │
   ▼
Docker Hub
   │
   ▼
Render Deploy Hook
   │
   ▼
Render Web Service
```

Target configuration:

```text
Service Type: Web Service
Container Port: 8083
SERVER_PORT: 8083
Health Check: /actuator/health
```

Render is used as a managed cloud deployment platform.

It is **not presented as a Kubernetes/AKS cluster**. It replaces the second cloud deployment environment while keeping the multi-cloud objective.

---

## Traffic Distribution

The most important runtime component is the traffic-management layer.

It sits above AWS and Render:

```text
                     Users
                       │
                       ▼
              Traffic Management
                 /           \
                /             \
               ▼               ▼
             AWS             Render
```

The traffic layer is responsible for:

- Routing requests
- Checking endpoint health
- Removing unhealthy endpoints
- Restoring recovered endpoints
- Distributing traffic
- Supporting cross-cloud failover

Jenkins does not perform this runtime routing.

Jenkins is responsible for **deployment**.

The traffic layer is responsible for **runtime availability**.

---

## High Availability

High availability is achieved through multiple layers.

### Layer 1 — Multiple Instances

Instead of relying on one application process:

```text
Load Balancer
   ├── Instance 1
   ├── Instance 2
   └── Instance 3
```

### Layer 2 — Multiple Clouds

```text
AWS
 │
 └── Application

Render
 │
 └── Application
```

### Layer 3 — Health Checks

```text
Traffic Manager
      │
      ├── AWS → Healthy
      │
      └── Render → Healthy
```

If a target becomes unhealthy:

```text
Traffic Manager
      │
      ├── AWS → Unhealthy → Remove
      │
      └── Render → Healthy → Continue traffic
```

### Layer 4 — Automated Recovery

After the failed environment recovers:

```text
AWS → Healthy again
        │
        ▼
Traffic Manager
        │
        ▼
AWS can return to active traffic
```

---

## Sudden Traffic Spike Scenario

A key demonstration scenario is a large number of users accessing the application at the same time.

For example:

```text
Normal traffic:

       Users
         │
         ▼
   Traffic Manager
      /       \
     ▼         ▼
    AWS      Render
```

During a sudden spike:

```text
                Thousands of Users
                       │
                       ▼
               Traffic Manager
                  /          \
                 ▼            ▼
              AWS            Render
           multiple        multiple
           instances        instances
```

The objective is to distribute requests instead of allowing one server to become a single bottleneck.

If one cloud becomes unavailable during the spike:

```text
Thousands of Users
        │
        ▼
Traffic Manager
        │
        X
     AWS DOWN
        │
        ▼
     Render
        │
        ▼
    Application
```

---

## Monitoring and Observability

Datadog is planned as the central observability platform.

```text
AWS EC2 ──────┐
              │
              ├──── Datadog
              │
Render ───────┘
```

Important metrics include:

- CPU utilization
- Memory utilization
- Request volume
- Response behavior
- Container restarts
- Application errors
- Deployment activity
- Service availability
- Instance health

The objective is to observe both clouds from a centralized monitoring system.

---

## AI-Powered Incident Analysis

The project includes an AI-assisted log analysis concept.

```text
              Failure
                 │
                 ▼
              Logs
                 │
                 ▼
        Python AI Analyzer
                 │
        ┌────────┴────────┐
        ▼                 ▼
   Root Cause       Fix Suggestion
        │                 │
        └────────┬────────┘
                 ▼
              Alert
```

Example:

```text
Incident:
Container cannot start

Analyzer:
1. Inspect deployment logs.
2. Identify likely configuration or image problem.
3. Identify the affected cloud.
4. Suggest remediation.
5. Generate an incident report.
```

The goal is to reduce incident investigation time.

---

## Security

Security controls include:

- Jenkins credentials
- SSH private-key credentials
- Non-root Docker runtime
- Versioned container images
- SonarQube analysis
- Trivy image scanning
- Restricted cloud access
- Secret separation from source code

Never commit:

```text
*.pem
*.key
.env
AWS access keys
Docker Hub passwords/tokens
Render deploy-hook URLs
Datadog API keys
Jenkins secrets
SMTP passwords
```

---

## Sample Application Configuration

The sample website runs inside Docker on:

```text
8083
```

The Docker image is:

```text
varun1716/food-delivery
```

This application is only the workload used to demonstrate the multi-cloud platform.

The infrastructure and DevOps architecture are the primary focus of this repository.

---

## Repository Structure

```text
food_delivery_app/
│
├── README.md
│
├── fooddeliveryapp/
│   ├── src/
│   ├── pom.xml
│   ├── mvnw
│   ├── mvnw.cmd
│   ├── Dockerfile
│   ├── Jenkinsfile
│   ├── deploy.sh
│   ├── docker-compose.yml
│   └── .env.example
│
└── k8s/
    ├── configmap.yaml
    ├── deployment.yaml
    └── service.yaml
```

---

## Kubernetes

Kubernetes manifests are retained as an optional future deployment path:

```text
k8s/
├── configmap.yaml
├── deployment.yaml
└── service.yaml
```

The primary multi-cloud implementation uses:

```text
AWS EC2 + Render
```

rather than requiring Kubernetes on both clouds.

A future version can introduce AWS EKS if Kubernetes orchestration is required.

---

## Current Implementation Status

### Completed

- Sample Spring Boot website
- Docker containerization
- Maven build
- Automated tests
- Jenkins CI/CD
- Docker Hub image publishing
- AWS EC2 deployment
- Versioned Docker images
- Non-root Docker runtime
- Windows Jenkins SSH/SCP deployment

### In Progress

- Render deployment
- SonarQube quality gate
- Trivy scanning
- Datadog monitoring
- AI log analyzer
- Cross-cloud traffic management
- Automated cloud failover
- Multi-instance scaling
- Traffic-spike/load testing

---

## Future Enhancements

The multi-cloud platform can be extended with:

- AWS load balancing
- Multiple AWS instances
- Multiple Render instances
- Automated cross-cloud failover
- Terraform infrastructure as code
- GitOps / Argo CD
- Automated remediation
- ChatOps
- Incident history
- Predictive alerts
- Autoscaling
- Cost visibility
- Advanced security scanning
- Stress and load testing

---

## Final Architecture Goal

The final system is intended to demonstrate:

```text
              ┌──────────────────────┐
              │       GitHub         │
              └──────────┬───────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │       Jenkins        │
              │      CI / CD         │
              └──────────┬───────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │      Docker Hub      │
              └──────────┬───────────┘
                         │
              ┌──────────┴──────────┐
              ▼                     ▼
        ┌───────────┐         ┌───────────┐
        │  AWS EC2  │         │   Render  │
        └─────┬─────┘         └─────┬─────┘
              │                     │
              └──────────┬──────────┘
                         ▼
              ┌──────────────────────┐
              │ Traffic Management   │
              │ Health + Failover    │
              └──────────┬───────────┘
                         │
                         ▼
                       Users
```

### Main idea

> **The food-delivery website is only a sample workload. The real project is a multi-cloud, highly available, observable, automated deployment platform designed to distribute traffic and continue serving users when one cloud environment becomes unhealthy.**

---

## Repository

```text
https://github.com/varunnnn17/food_delivery_app
```
