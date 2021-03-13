FROM openjdk:8u212-jre-alpine

ADD maven/positionreceiver-0.0.1-SNAPSHOT.jar webapp.jar

RUN apk --no-cache add curl

EXPOSE 8080

CMD ["java", "-Xmx50m", "-jar","webapp.jar"]
