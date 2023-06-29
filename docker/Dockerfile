## The context for this should be set as the parent so we have access to the java program
## That means when referencing something within this docker directory, you must use the path docker/path/to/file

#
# Build stage
#
FROM maven:3.9-eclipse-temurin-19-alpine AS build
# FROM maven:3.9-eclipse-temurin-11 AS build

# FROM maven:3.9-eclipse-temurin-19-alpine
# FROM maven:3.9-eclipse-temurin-11
WORKDIR /app
COPY pom.xml ./
## Fetch dependencies before adding source, docker will then reuse the cache for them
## Also use "--mount=type=cache,target=/root/.m2" to use docker's buildkit cache
## See: https://stackoverflow.com/questions/27767264/how-to-dockerize-maven-project-and-how-many-ways-to-accomplish-it
RUN --mount=type=cache,target=/root/.m2 mvn verify --fail-never
COPY src ./src
RUN --mount=type=cache,target=/root/.m2  mvn clean install -Dmaven.test.skip

#
# Wrapper stage
#
# 19-jre-alpine ~ 61MB
FROM eclipse-temurin:19-jre-alpine
## 11-jre-alpine ~ 55MB
# FROM eclipse-temurin:11-jre-alpine

RUN apk add --no-cache postgresql-client

COPY --from=build /app/target/fuseki-to-i2b2-*.jar /usr/local/share/java/fuseki-to-i2b2.jar
COPY --from=build /app/target/lib/* /usr/local/share/java/
EXPOSE 1042
WORKDIR /app

COPY docker/patient_count.sql /app/patient_count.sql
COPY docker/coordinate-metadata-update.sh /app/coordinate-metadata-update.sh

## Minimal listener to run the script
CMD while true ; do nc -l -p 1042 -e /bin/sh -c 'echo -e "HTTP/1.1 200 OK\n\n$(/app/coordinate-metadata-update.sh)"'; done
