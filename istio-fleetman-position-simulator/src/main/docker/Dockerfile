FROM openjdk:8u212-jre-alpine

RUN apk --no-cache add curl

ADD maven/positionsimulator-0.0.1-SNAPSHOT.jar webapp.jar

CMD ["java", "-Xmx50m", "-jar","webapp.jar"]
