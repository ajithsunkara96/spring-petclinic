FROM eclipse-temurin:17-jre
WORKDIR /app
# copy the jar that Maven built in the previous stage
COPY target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java","-jar","/app/app.jar"]