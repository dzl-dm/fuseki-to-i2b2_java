#
# Build stage
#
# FROM maven:3.9-eclipse-temurin-11 AS build
# FROM maven:3.9-eclipse-temurin-19-alpine AS build

FROM maven:3.9-eclipse-temurin-19-alpine
# FROM maven:3.9-eclipse-temurin-11
WORKDIR /home/app
COPY pom.xml ./
## Fetch dependencies before adding source, docker will then reuse the cache for them
## Also use "--mount=type=cache,target=/root/.m2" to use docker's buildkit cache
## See: https://stackoverflow.com/questions/27767264/how-to-dockerize-maven-project-and-how-many-ways-to-accomplish-it
RUN --mount=type=cache,target=/root/.m2 mvn verify --fail-never
COPY src ./src
RUN --mount=type=cache,target=/root/.m2  mvn -f ./pom.xml clean install
COPY config ./config

## DEBUG!
RUN mkdir -p /var/tmp/cometar/i2b2-sql

entrypoint tail -F any

#
# Package stage
#
## 11-jre-alpine ~ 55MB
# FROM eclipse-temurin:11-jre-alpine
# 19-jre-alpine ~ 61MB
# FROM eclipse-temurin:19-jre-alpine

# COPY --from=build /home/app/target/fuseki-to-i2b2-0.2-SNAPSHOT.jar /usr/local/lib/fuseki-to-i2b2.jar
# COPY --from=build /home/app/target/lib/* /usr/local/lib/fuseki-dependencies/
# EXPOSE 8080
## ENTRYPOINT ["java","-cp", "dependency/*", "de.dzl.cometar.SQLFileWriter", "ontology.properties"]
## The jar is packaged to include dependencies, the class is set as main, "properties.properties" is default (can be ommitted), so we just need to run like this:
# ENTRYPOINT ["java", "-jar", "/usr/local/lib/fuseki-to-i2b2.jar", "properties.properties"]
## Optional for testing...
# ENTRYPOINT ["java", "-jar", "/usr/local/lib/fuseki-to-i2b2.jar", "properties.properties", "true", "Test-multi-notation", "config/cometar-test-config.ttl"]
## New for separate jar and dependencies
# ENTRYPOINT ["java", "-jar", "/usr/local/lib/fuseki-to-i2b2.jar", "-cp", "/usr/local/lib/fuseki-dependencies/\*", "properties.properties", "true", "Test-multi-notation", "config/cometar-test-config.ttl"]
