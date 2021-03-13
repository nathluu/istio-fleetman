FROM openjdk:8u212-jre-alpine

RUN apk --no-cache add curl

ADD maven/telemetry-0.0.1-SNAPSHOT.jar webapp.jar

EXPOSE 8080

CMD ["java", "-Xmx50m", "-jar","webapp.jar"]
