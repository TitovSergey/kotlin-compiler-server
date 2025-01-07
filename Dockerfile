FROM amazoncorretto:17 as build

ARG KOTLIN_VERSION

RUN if [ -z "$KOTLIN_VERSION" ]; then \
        echo "Error: KOTLIN_VERSION argument is not set. Use docker-image-build.sh to build the image." >&2; \
        exit 1; \
    fi

ENV KOTLIN_LIB=$KOTLIN_VERSION
ENV KOTLIN_LIB_JS=${KOTLIN_VERSION}-js
ENV KOTLIN_LIB_WASM=${KOTLIN_VERSION}-wasm
ENV KOTLIN_LIB_COMPOSE_WASM=${KOTLIN_VERSION}-compose-wasm
ENV KOTLIN_COMPOSE_WASM_COMPILER_PLUGINS=${KOTLIN_VERSION}-compose-wasm-compiler-plugins

RUN mkdir -p /kotlin-compiler-server
WORKDIR /kotlin-compiler-server
ADD . /kotlin-compiler-server

RUN ./gradlew build -x test
RUN mkdir -p /build/libs && (cd /build/libs;  jar -xf /kotlin-compiler-server/build/libs/kotlin-compiler-server-${KOTLIN_LIB}-SNAPSHOT.jar)

FROM amazoncorretto:17

RUN yum update -y && \
    yum install -y shadow-utils && \
    yum clean all

RUN groupadd -g 1000 customgroup
RUN useradd -m -u 1000 -g root -G customgroup customuser

USER customuser

RUN mkdir /home/customuser/kotlin-compiler-server
WORKDIR /home/customuser/kotlin-compiler-server

COPY --from=build /build/libs/BOOT-INF/lib /home/customuser/kotlin-compiler-server/lib
COPY --from=build /build/libs/META-INF /home/customuser/kotlin-compiler-server/META-INF
COPY --from=build /build/libs/BOOT-INF/classes /home/customuser/kotlin-compiler-server
COPY --from=build /kotlin-compiler-server/${KOTLIN_LIB} /home/customuser/kotlin-compiler-server/${KOTLIN_LIB}
COPY --from=build /kotlin-compiler-server/${KOTLIN_LIB_JS} /home/customuser/kotlin-compiler-server/${KOTLIN_LIB_JS}
COPY --from=build /kotlin-compiler-server/${KOTLIN_LIB_WASM} /home/customuser/kotlin-compiler-server/${KOTLIN_LIB_WASM}
COPY --from=build /kotlin-compiler-server/${KOTLIN_LIB_COMPOSE_WASM} /home/customuser/kotlin-compiler-server/${KOTLIN_LIB_COMPOSE_WASM}
COPY --from=build /kotlin-compiler-server/${KOTLIN_COMPOSE_WASM_COMPILER_PLUGINS} /home/customuser/kotlin-compiler-server/${KOTLIN_COMPOSE_WASM_COMPILER_PLUGINS}
COPY --from=build /kotlin-compiler-server/executor.policy /home/customuser/kotlin-compiler-server/
COPY --from=build /kotlin-compiler-server/indexes.json /home/customuser/kotlin-compiler-server/
COPY --from=build /kotlin-compiler-server/indexesJs.json /home/customuser/kotlin-compiler-server/
COPY --from=build /kotlin-compiler-server/indexesWasm.json /home/customuser/kotlin-compiler-server/
COPY --from=build /kotlin-compiler-server/indexesComposeWasm.json /home/customuser/kotlin-compiler-server/

ENV PORT=8080

CMD ["java", "-noverify", \
    "-Dserver.port=${PORT}", \
    "-cp", "/home/customuser/kotlin-compiler-server:/home/customuser/kotlin-compiler-server/lib/*", \
    "com.compiler.server.CompilerApplicationKt"]