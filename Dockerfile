FROM confluentinc/cp-kafka-connect:7.0.1 as confluentinc-hub
ARG JDBC_VERSION=10.3.3
ARG AVRO_VERSION=7.0.1

RUN confluent-hub install --no-prompt confluentinc/kafka-connect-avro-converter:${AVRO_VERSION}
RUN confluent-hub install --no-prompt confluentinc/kafka-connect-jdbc:$JDBC_VERSION

FROM curlimages/curl:latest as jdbc
ARG MARIADB_VERSION=3.0.3
WORKDIR /dl/
RUN curl https://downloads.mariadb.com/Connectors/java/connector-java-$MARIADB_VERSION/mariadb-java-client-$MARIADB_VERSION.jar --output mariadb-java-client.jar

FROM quay.io/strimzi/kafka:0.27.1-kafka-2.8.1

COPY --from=confluentinc-hub /usr/share/confluent-hub-components/confluentinc-kafka-connect-jdbc/lib  /opt/kafka/plugins/java/kafka-connect-jdbc/
COPY --from=confluentinc-hub /usr/share/confluent-hub-components/confluentinc-kafka-connect-avro-converter/lib  /opt/kafka/plugins/java/avro/
COPY --from=jdbc /dl/mariadb-java-client.jar /opt/kafka/plugins/java/kafka-connect-jdbc/mariadb-java-client.jar

