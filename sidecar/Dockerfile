FROM amazonlinux
RUN set -x && \
    mkdir /metric && \
    yum -y update && \
    yum -y install unzip wget sed curl jq less

# AWS CLI Install
RUN set -x && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install

# Java Install
RUN set -x && \
    yum -y install java-11-amazon-corretto-headless

# JMX Clinet Download
RUN set -x && \
    wget http://crawler.archive.org/cmdline-jmxclient/cmdline-jmxclient-0.10.3.jar && \
    mv cmdline-jmxclient-0.10.3.jar /metric/cmdline-jmxclient-0.10.3.jar

COPY ./put-metric-ecs.sh /metric/put-metric-ecs.sh
COPY ./put-metric-jvm.sh /metric/put-metric-jvm.sh
COPY ./put-metric-jvm-max.sh /metric/put-metric-jvm-max.sh
COPY ./run.sh /run.sh

RUN set -x && \
    chmod +755 metric/cmdline-jmxclient-0.10.3.jar && \
    chmod +755 /metric/put-metric-ecs.sh && \
    chmod +755 /metric/put-metric-jvm.sh && \
    chmod +755 /metric/put-metric-jvm-max.sh && \
    chmod +x /run.sh

ENTRYPOINT [ "/run.sh" ]
