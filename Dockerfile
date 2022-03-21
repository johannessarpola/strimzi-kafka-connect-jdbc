FROM alpine/git:v2.32.0 as cloner

WORKDIR /clone/
RUN git clone --depth 1 --branch v10.3.3 https://github.com/confluentinc/kafka-connect-jdbc.git

FROM maven:3-adoptopenjdk-8 as builder

WORKDIR /build/
COPY settings.xml /usr/share/maven/conf/
COPY --from=cloner /clone/kafka-connect-jdbc .
RUN mvn install -Dmaven.test.skip --quiet

FROM alpine:3.9.6 as dist
ARG VERSION=10.3.3

WORKDIR /dist/
COPY --from=builder /build/target/kafka-connect-jdbc-$VERSION-package/* .

FROM confluentinc/cp-kafka-connect:7.0.1 as cp
RUN confluent-hub install --no-prompt confluentinc/kafka-connect-avro-converter:7.0.1

FROM alpine:3.9.6 as jdbc
ARG MARIADB_VERSION=3.0.3
RUN wget -nv https://downloads.mariadb.com/Connectors/java/connector-java-$MARIADB_VERSION/mariadb-java-client-$MARIADB_VERSION.jar -O mariadb-java-client.jar

FROM quay.io/strimzi/kafka:0.27.1-kafka-2.8.1

COPY --from=dist /dist/java/kafka-connect-jdbc/ /opt/kafka/plugins/java/kafka-connect-jdbc/
COPY --from=jdbc mariadb-java-client.jar /opt/kafka/plugins/java/kafka-connect-jdbc/mariadb-java-client.jar
COPY --from=cp /usr/share/confluent-hub-components/confluentinc-kafka-connect-avro-converter/lib  /opt/kafka/plugins/java/avro/

