# Use the official OpenJDK 21 image as the base image
FROM openjdk:21
# Copy the built Spring Boot JAR from the target directory to the image and rename it
COPY target/hello-world-springboot-0.0.1-SNAPSHOT.jar hello-world-app.jar
# Set the default command to run the JAR when the container starts
ENTRYPOINT ["java", "-jar", "/hello-world-app.jar"]