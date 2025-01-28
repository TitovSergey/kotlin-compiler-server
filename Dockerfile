FROM amazoncorretto:17 as build_step

RUN mkdir -p /kotlin-compiler-server-build
WORKDIR /kotlin-compiler-server-build
ADD . /kotlin-compiler-server-build

RUN ./gradlew clean build -x test

FROM amazoncorretto:17 as run_step

RUN mkdir /kotlin-compiler-server-run
WORKDIR /kotlin-compiler-server-run

COPY --from=build_step /kotlin-compiler-server-build/ /kotlin-compiler-server-run/

ENV PORT=8080

CMD ["./gradlew", "bootRun", "-Dserver.port=${PORT}"]
