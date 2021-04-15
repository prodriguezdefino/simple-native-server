#FROM ghcr.io/graalvm/graalvm-ce:19.3.0.2 as native-builder

#RUN gu install native-image

#RUN mkdir -p /opt/maven
#RUN curl -s https://apache.osuosl.org/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz | tar xvz --strip-components=1 -C /opt/maven

#ENV PATH="/opt/maven/bin:${PATH}"

#WORKDIR /greeter

#COPY pom.xml .
#COPY src src
#RUN mvn package

#FROM ghcr.io/graalvm/graalvm-ce:19.3.0.2 as native-image

#COPY --from=native-builder /greeter/target/greeter /greeter
#COPY src/main/resources/public /public
#RUN chmod +x /greeter

#ENTRYPOINT ["/greeter"]

FROM ubuntu:18.04 AS build-env
RUN apt-get update && apt-get install -y gcc zlib1g-dev wget

RUN wget https://github.com/graalvm/graalvm-ce-builds/releases/download/vm-19.3.0.2/graalvm-ce-java11-linux-amd64-19.3.0.2.tar.gz
RUN tar -vzxf graalvm-ce-java11-linux-amd64-19.3.0.2.tar.gz
ENV PATH /graalvm-ce-java11-19.3.0.2/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
RUN gu install native-image

WORKDIR /sparkjava
COPY src /sparkjava/src
COPY gradlew /sparkjava/.
COPY build.gradle /sparkjava/.
COPY settings.gradle /sparkjava/.
COPY gradle /sparkjava/gradle
#COPY . /sparkjava

RUN ./gradlew clean shadowJar
RUN native-image \
    -H:+ReportUnsupportedElementsAtRuntime \
    -H:+TraceClassInitialization \
    --verbose \
    --enable-http \
    --static \
    --no-fallback \
    --initialize-at-build-time=org.eclipse.jetty,org.slf4j,javax.servlet,org.sparkjava \
    -jar /sparkjava/build/libs/simple-native-server-1.0-SNAPSHOT.jar

FROM alpine:3.11.2
WORKDIR /
COPY --from=build-env /sparkjava/simple-native-server-1.0-SNAPSHOT .
COPY src/main/resources/public /public
RUN chmod +x simple-native-server-1.0-SNAPSHOT
EXPOSE 8080
ENTRYPOINT ["/simple-native-server-1.0-SNAPSHOT"]
