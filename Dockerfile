# syntax=docker/dockerfile:1.7

############################
# Build the Spring Boot JAR
############################
FROM eclipse-temurin:17-jdk AS builder
WORKDIR /workspace

# Copy Maven wrapper and pom first to leverage layer caching
COPY mvnw mvnw.cmd pom.xml ./
COPY .mvn .mvn
RUN chmod +x mvnw

# Download dependencies (go-offline) to speed up subsequent builds
RUN ./mvnw -B dependency:go-offline

# Copy the application source
COPY src src

# Build the application (skip tests for faster container builds)
RUN ./mvnw -B clean package -DskipTests

#################################
# Runtime image with the fat jar
#################################
FROM eclipse-temurin:17-jre
WORKDIR /app

# Copy the jar built in the previous stage
COPY --from=builder /workspace/target/upi-offline-mesh-0.0.1-SNAPSHOT.jar app.jar

# Render (and many platforms) set PORT; Spring reads server.port from PORT env var
ENV SPRING_PROFILES_ACTIVE=prod

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
