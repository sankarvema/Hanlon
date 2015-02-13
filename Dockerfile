# Hanlon server
#
# VERSION 2.0.0

FROM ubuntu:latest
MAINTAINER Joseph Callen <jcpowermac@gmail.com>

# Install the required dependancies
RUN apt-get -y update \
    && apt-get -y install ruby1.9.3 git build-essential libssl0.9.8 libssl-dev p7zip-full software-properties-common \
    && add-apt-repository -y ppa:nilarimogard/webupd8 \
    && apt-get -y update \
    && apt-get -y install wimtools \
    && apt-get autoremove \
    && apt-get clean \
    && rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/*

# We don't need gem docs
RUN echo "install: --no-rdoc --no-ri" > /etc/gemrc

RUN gem install bundle
RUN mkdir /home/hanlon 
RUN git clone https://github.com/csc/Hanlon.git /home/hanlon
WORKDIR /home/hanlon
RUN bundle install --system

# Hanlon by default runs at TCP 8026
EXPOSE 8026

ENV TEST_MODE true
ENV LANG en_US.UTF-8
ENV WIMLIB_IMAGEX_USE_UTF8 true

WORKDIR /home/hanlon/web
CMD (cd /home/hanlon && ./hanlon_init -j '{"hanlon_static_path": "'$HANLON_STATIC_PATH'", "hanlon_subnets": "'$HANLON_SUBNETS'", "hanlon_server": "'$DOCKER_HOST'", "persist_host": "'$MONGO_PORT_27017_TCP_ADDR'"}' ) && ./run-puma.sh
