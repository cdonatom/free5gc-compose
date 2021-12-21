FROM registry.access.redhat.com/ubi8/ubi:latest AS builder

LABEL maintainer="Carlos Donato <cdonato@redhat.com>"

# Install dependencies
RUN yum -y update \
    && yum -y install gcc gcc-c++ cmake autoconf libtool pkg-config libmnl-devel libyaml-devel ca-certificates wget git python2 \
    && curl -sL https://rpm.nodesource.com/setup_14.x | bash - \
    && yum update \
    && yum install -y nodejs \
    && npm i -g corepack

# Install GO
RUN wget https://go.dev/dl/go1.14.4.linux-amd64.tar.gz \
    && tar -C /usr/local -zxvf go1.14.4.linux-amd64.tar.gz \
    && mkdir -p ~/go/{bin,pkg,src}

# Clean apt cache
RUN yum clean all

# Expose ENV variables
ENV HOME /root/
ENV GOPATH $HOME/go
ENV GOROOT /usr/local/go
ENV GO111MODULE on
ENV PATH $PATH:$GOPATH/bin:$GOROOT/bin

# Get Free5GC
RUN cd $GOPATH/src \
    && git clone --recursive -b v3.0.6 -j `nproc` https://github.com/free5gc/free5gc.git

# Build Free5GC NFs & WebUI
RUN cd $GOPATH/src/free5gc \
    && make all

# Final container based on UBI.
FROM registry.access.redhat.com/ubi8/ubi:latest

WORKDIR /free5gc
RUN mkdir -p config/ support/TLS/ public

# Copy executables
COPY --from=builder /root/go/src/free5gc/bin/* ./
COPY --from=builder /root/go/src/free5gc/NFs/upf/build/bin/* ./
COPY --from=builder /root/go/src/free5gc/webconsole/bin/webconsole ./webui

# Copy static files (webui frontend)
COPY --from=builder /root/go/src/free5gc/webconsole/public ./public

# Copy linked libs
COPY --from=builder /root/go/src/free5gc/NFs/upf/build/updk/src/third_party/libgtp5gnl/lib/libgtp5gnl.so.0 ./
COPY --from=builder /root/go/src/free5gc/NFs/upf/build/utlt_logger/liblogger.so ./

# Copy configuration files (not used for now)
COPY --from=builder /root/go/src/free5gc/config/* ./config/
COPY --from=builder /root/go/src/free5gc/NFs/upf/build/config/* ./config/

# Copy default certificates (not used for now)
COPY --from=builder /root/go/src/free5gc/support/TLS/* ./support/TLS/
