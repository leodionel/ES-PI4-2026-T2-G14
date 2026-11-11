FROM eclipse-temurin:17-jdk AS build
WORKDIR /app
COPY src ./src
RUN mkdir out && javac -d out src/*.java

FROM eclipse-temurin:17-jre
WORKDIR /app
COPY --from=build /app/out .
EXPOSE 3000
CMD ["java", "Servidor"]