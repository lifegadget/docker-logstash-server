FROM debian:jessie
MAINTAINER LifeGadget, Ltd <contact-us@lifegadget.co>

# Download latest package lists & install dependencies
ENV DEBIAN_FRONTEND noninteractive
ENV ELASTIC_SEARCH_VERSION 1.3.4
RUN mkdir -p /app \
	&& mkdir -p /app/certs \
	&& cd /app \
	&& apt-key adv --keyserver pgp.mit.edu --recv-keys D27D666CD88E42B4 \
	&& echo 'deb http://packages.elasticsearch.org/logstash/1.4/debian stable main' > /etc/apt/sources.list.d/logstash.list \
	&& apt-get update  \
    && apt-get install -yqq --force-yes \
		openjdk-7-jre-headless \
		wget \
    	logstash \
		redis-server \
		vim \
		openssl \
	&& wget -O/tmp/elasticsearch-${ELASTIC_SEARCH_VERSION}.deb https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-${ELASTIC_SEARCH_VERSION}.deb \
	&& dpkg -i /tmp/elasticsearch-${ELASTIC_SEARCH_VERSION}.deb \
	&& update-rc.d elasticsearch defaults 95 10 \
	&& rm /tmp/elasticsearch-${ELASTIC_SEARCH_VERSION}.deb

# Move default configuration files into place
COPY resources/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml
COPY resources/logstash.conf /etc/logstash/conf.d/central.conf
RUN ln -s /etc/logstash/conf.d /app/conf

# Add conveniences to Bash shell when working within the container
ADD https://raw.githubusercontent.com/lifegadget/bashrc/master/snippets/history.sh /etc/bash.history
ADD https://raw.githubusercontent.com/lifegadget/bashrc/master/snippets/color.sh /etc/bash.color
ADD https://raw.githubusercontent.com/lifegadget/bashrc/master/snippets/shortcuts.sh /etc/bash.shortcuts
RUN { \
		echo ""; \
		echo 'source /etc/bash.history'; \ 
		echo 'source /etc/bash.color'; \
		echo 'source /etc/bash.shortcuts'; \
	} >> /etc/bash.bashrc

# Elasticsearch HTTP
EXPOSE 9200
# Elasticsearch transport
EXPOSE 9300
# Kibana
EXPOSE 9292
# Redis
EXPOSE 6379
# SysLog
EXPOSE 5514
# Lumberjack
EXPOSE 6782

# To remove annoying messages about no home directory (from vim, etc.)
RUN mkdir -p /home/ubuntu

# Add Lumberjack SSL cert (private key, csr, signed certificate)
RUN openssl genrsa -out /app/certs/server.key 2048	\
	&& openssl req -new -key /app/certs/server.key	-batch -out /app/certs/server.csr \
	&& openssl x509 -req -days 3650 -in /app/certs/server.csr -signkey /app/certs/server.key -out /app/certs/server.crt
VOLUME ["/app/certs"]
# rsyslog
# RUN apt-get install -yqq rsyslog
# COPY resources/rsyslog.conf /etc/rsyslog.conf

# Start logstash
COPY resources/logstash-server /usr/local/bin/logstash-server
RUN chmod +x /usr/local/bin/logstash-server
ENTRYPOINT ["logstash-server"]
CMD ["start"]