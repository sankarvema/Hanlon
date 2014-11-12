FROM ubuntu:precise

MAINTAINER Joseph Callen <jcpowermac@gmail.com>

EXPOSE 8026

RUN apt-get -y update \
    && apt-get -y install ruby1.9.3 git build-essential libssl0.9.8 libssl-dev \
    && apt-get autoremove \
    && apt-get clean \
    && rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/*

RUN gem install bundle
RUN mkdir /home/hanlon 
RUN git clone https://github.com/csc/Hanlon.git /home/hanlon
WORKDIR /home/hanlon
RUN bundle install --system

WORKDIR /home/hanlon/web
CMD (cd /home/hanlon && ./hanlon_init) && sed -i "s/127.0.0.1/$MONGO_PORT_27017_TCP_ADDR/g" /home/hanlon/web/config/hanlon_server.conf && ./run-puma.sh
