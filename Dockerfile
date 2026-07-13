# ─────────────────────────────────────────────
# Stage 1: Build (uses Maven + JDK 17)
# ─────────────────────────────────────────────
FROM maven:3.9.6-eclipse-temurin-17 AS builder

WORKDIR /app

# Copy only dependency descriptors first (layer-cache trick)
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy the rest of the source and build the fat-jar
COPY src ./src
RUN mvn clean package -DskipTests -B

# ─────────────────────────────────────────────
# Stage 2: Runtime (slim JRE image)
# ─────────────────────────────────────────────
FROM eclipse-temurin:17-jre-jammy

LABEL maintainer="devops@example.com"
LABEL app="employeemanagement"

# Non-root user for security
RUN groupadd --system appgroup && useradd --system --gid appgroup appuser

WORKDIR /app

# Copy the jar from the build stage
COPY --from=builder /app/target/*.jar app.jar

# Adjust ownership
RUN chown -R appuser:appgroup /app

USER appuser

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
