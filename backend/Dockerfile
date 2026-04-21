# Build stage
FROM maven:3.8.5-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
# Download dependencies first using a cache mount
RUN --mount=type=cache,target=/root/.m2 mvn dependency:go-offline -B
COPY src ./src
# Build the application using the same cache mount
RUN --mount=type=cache,target=/root/.m2 mvn package -DskipTests

# Run stage
FROM eclipse-temurin:17-jre
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar

# Expose the default Spring Boot port
EXPOSE 8080

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]
