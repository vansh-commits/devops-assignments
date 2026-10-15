FROM eclipse-temurin:21-jdk-alpine AS build
WORKDIR /src
COPY HelloWorld.java .
RUN javac HelloWorld.java

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=build /src/HelloWorld.class .
EXPOSE 8080
CMD ["java", "HelloWorld"]
