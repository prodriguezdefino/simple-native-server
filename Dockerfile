FROM ubuntu:18.04 AS build-env
RUN apt-get update && apt-get install -y gcc zlib1g-dev wget

RUN wget https://github.com/graalvm/graalvm-ce-builds/releases/download/vm-19.3.0.2/graalvm-ce-java11-linux-amd64-19.3.0.2.tar.gz
RUN tar -vzxf graalvm-ce-java11-linux-amd64-19.3.0.2.tar.gz
ENV PATH /graalvm-ce-java11-19.3.0.2/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
RUN gu install native-image

WORKDIR /greeter
COPY src /greeter/src
COPY gradlew /greeter/.
COPY build.gradle /greeter/.
COPY settings.gradle /greeter/.
COPY gradle /greeter/gradle

RUN ./gradlew clean shadowJar
RUN native-image \
    -H:+ReportUnsupportedElementsAtRuntime \
    -H:+TraceClassInitialization \
    --verbose \
    --enable-http \
    --static \
    --no-fallback \
    --initialize-at-build-time=org.eclipse.jetty,org.slf4j,javax.servlet,org.sparkjava \
    -jar /greeter/build/libs/simple-native-server-1.0-SNAPSHOT.jar

FROM alpine:3.11.2
WORKDIR /
COPY --from=build-env /greeter/simple-native-server-1.0-SNAPSHOT .
COPY src/main/resources/public /public
RUN chmod +x simple-native-server-1.0-SNAPSHOT
EXPOSE 8080
ENTRYPOINT ["/simple-native-server-1.0-SNAPSHOT"]
