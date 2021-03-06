FROM maven:3.5-jdk-9-slim as build

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
		git \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR /iri

RUN git clone https://github.com/iotaledger/iri.git /iri/
RUN git checkout refs/tags/v1.4.1.6 -b v1.4.1.6
RUN mvn clean package

#
# Execution image
#
FROM openjdk:8-slim

COPY --from=build /iri/target/iri*.jar /iri/target/
COPY conf/* /iri/conf/
COPY docker-entrypoint.sh /

# Allow change of ports in the container.
# See Issue #2 for description why this is needed (https://github.com/bluedigits/iota-node/issues/2)
ENV API_PORT 14265
ENV UDP_PORT 14600
ENV TCP_PORT 15600

# Default jvm arguments
ENV JAVA_OPTIONS "-XX:+DisableAttachMechanism -XX:+HeapDumpOnOutOfMemoryError"
# Example to make java use docker's memory limits to change its own memory configuration
# (https://blogs.oracle.com/java-platform-group/java-se-support-for-docker-cpu-and-memory-limits)
#
# ENV JAVA_OPTIONS "-XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap"

# Default java memory settings
ENV MIN_MEMORY 2G
ENV MAX_MEMORY 4G

# Default remote api limitations
ENV REMOTE_API_LIMIT "attachToTangle, addNeighbors, removeNeighbors"

# Mark ports for expose
EXPOSE $API_PORT
EXPOSE $UDP_PORT/UDP
EXPOSE $TCP_PORT

WORKDIR /iri/data

# Define volumes
VOLUME /iri/data
VOLUME /iri/conf

ENTRYPOINT ["/docker-entrypoint.sh"]
