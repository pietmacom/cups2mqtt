# To avoid incompatiblities build and run
# this with the same java release.
#

# --- BUILD ---
FROM maven:3.9.1-eclipse-temurin-11 AS builder
RUN mkdir /build
WORKDIR /build

# Having to create a Github Personal Access Token + settings.xml
# for just one dependency is making it hard to fix things!
#
# I'd rather deploy it to some maven public repository.
#
# This way everybody is able to build this from his
# docker-compose file.
#
ARG MQTT_GATEWAY_VERSION=2.1.2
RUN git clone --branch $MQTT_GATEWAY_VERSION https://github.com/mqtt-home/mqtt-gateway.git && \
    cd mqtt-gateway/src && \
    mvn versions:set -DnewVersion=$MQTT_GATEWAY_VERSION && \
    mvn clean install -DskipTests

RUN mkdir cups2mqtt
COPY ./ /build/cups2mqtt
RUN cd cups2mqtt/src && \
    mvn clean package -DskipTests

# --- RUNTIME ---
FROM eclipse-temurin:11-jre-alpine
RUN mkdir /opt/app
WORKDIR /opt/app

COPY --from=builder /build/cups2mqtt/src/de.rnd7.cupsmqtt/target/cupsmqtt.jar .
COPY --from=builder /build/cups2mqtt/src/logback.xml .

CMD java -jar ./cupsmqtt.jar /var/lib/cupsmqtt/config.json
