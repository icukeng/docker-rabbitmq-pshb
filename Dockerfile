FROM ubuntu:16.04 as dev

RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y  \
    erlang-nox erlang-dev erlang-src make git ca-certificates curl python zip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/brc859844/rabbithub
RUN cd rabbithub && make deps && make && make package



FROM ubuntu:16.04 as prod

RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y  \
    erlang-nox logrotate socat ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ADD https://packagecloud.io/rabbitmq/rabbitmq-server/packages/ubuntu/xenial/rabbitmq-server_3.6.6-1_all.deb/download.deb /root/rabbitmq-server_3.6.6-1_all.deb
RUN dpkg -i /root/rabbitmq-server_3.6.6-1_all.deb
COPY --from=0 /rabbithub/dist/*.ez /usr/lib/rabbitmq/lib/rabbitmq_server-3.6.6/plugins

RUN rabbitmq-plugins enable --offline rabbitmq_management
RUN rabbitmq-plugins enable --offline rabbithub

COPY rabbitmq.config /var/lib/rabbitmq/
RUN ln -s /var/lib/rabbitmq/rabbitmq.config /etc/rabbitmq/ && chown rabbitmq: /var/lib/rabbitmq/rabbitmq.config

USER rabbitmq:rabbitmq

EXPOSE 15672 15670
VOLUME /var/lib/rabbitmq
CMD ["rabbitmq-server"]
