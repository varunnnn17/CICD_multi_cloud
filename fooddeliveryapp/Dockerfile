# Multi-stage build for Food Delivery Application

# ============================================================
# Stage 1: Build application with Maven
# ============================================================
FROM maven:3.9.6-eclipse-temurin-17 AS builder

WORKDIR /app

# Copy project files
COPY pom.xml .
COPY src src

# Build and package the application
RUN mvn clean package

# ============================================================
# Stage 2: Production runtime environment
# ============================================================
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

# Create non-root user for security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy the packaged JAR from builder
COPY --from=builder /app/target/*.jar app.jar

# Give application user ownership
RUN chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

# Expose application port
EXPOSE 8083

# Start Spring Boot application
ENTRYPOINT ["java", "-Djava.security.egd=file:/dev/./urandom", "-jar", "app.jar"]