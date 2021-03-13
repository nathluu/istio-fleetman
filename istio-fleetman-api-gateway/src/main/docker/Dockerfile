FROM openjdk:8u212-jre-alpine

EXPOSE 8080

WORKDIR /usr/local/bin/

RUN apk --no-cache add curl

COPY maven/fleetman-api-gateway-0.0.1-SNAPSHOT.jar webapp.jar

CMD ["java", "-Xmx50m", "-jar","webapp.jar"]
