FROM ubuntu:22.04

WORKDIR /root

ADD install-pdk-release.sh .
ADD install-onceover.sh .
ADD pdk-release.env .
COPY entrypoint.sh /.entrypoint.sh

RUN passwd -d root && \
    mkdir /cache && \
    chmod a+rwx /cache

RUN apt-get update && \
    apt-get install -y openssh-client && \
    ./install-pdk-release.sh && \
    ./install-onceover.sh && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

# Prep a module to make sure we have all of
# the required dependencies.
RUN pdk new module docker --skip-interview && \
    cd docker && \
    pdk new class test && \
    pdk validate

ENV PATH="${PATH}:/opt/puppetlabs/pdk/private/git/bin"
ENV PDK_DISABLE_ANALYTICS=true
ENV LANG=C.UTF-8

WORKDIR /workspace

ENTRYPOINT ["/.entrypoint.sh"]
