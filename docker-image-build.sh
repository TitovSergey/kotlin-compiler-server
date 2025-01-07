#!/bin/sh

kotlinVersion=$(awk '{ if ($1 == "kotlin") { gsub(/"/, "", $2); print $2; } }' FS=' = ' ./gradle/libs.versions.toml)

echo "Kotlin Version for the docker: $kotlinVersion"

docker build . --file Dockerfile --tag registry.jetbrains.team/p/ml-4-se-lab/rlsa/reward_server:latest --build-arg KOTLIN_VERSION=$kotlinVersion --platform linux/amd64
docker push registry.jetbrains.team/p/ml-4-se-lab/rlsa/reward_server:latest


# java -noverify -Dserver.port=8080 -cp /kotlin-compiler-server:/kotlin-compiler-server/lib/* com.compiler.server.CompilerApplicationKt