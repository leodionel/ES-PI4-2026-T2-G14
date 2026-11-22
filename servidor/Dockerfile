FROM eclipse-temurin:17-jdk AS build
WORKDIR /app
COPY src ./src
RUN mkdir out && javac -d out src/*.java

FROM eclipse-temurin:17-jre
ENV TZ=America/Sao_Paulo
WORKDIR /app
COPY --from=build /app/out .
RUN useradd --system --no-create-home app
USER app
EXPOSE 3000 3001
CMD ["java", "Servidor"]