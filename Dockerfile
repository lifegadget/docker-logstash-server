FROM debian:jessie
MAINTAINER LifeGadget, Ltd <contact-us@lifegadget.co>

# Download latest package lists & install dependencies
ENV DEBIAN_FRONTEND noninteractive
ENV ELASTIC_SEARCH_VERSION "1.3.4"
RUN echo 'deb http:// packages.elasticsearch.org/ logstash/ 1.4/ debian stable main' > /etc/apt/sources.list.d/ logstash.list
	&& apt-get update  \
    && apt-get install -yqq \
		openjdk-7-jre-headless \
		wget \
    	logstash \
		redis-server \
	&& wget -O/tmp/elasticsearch-${ELASTIC_SEARCH_VERSION}.deb https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-${ELASTIC_SEARCH_VERSION}.deb \
	&& dpkg -i /tmp/elasticsearch-${ELASTIC_SEARCH_VERSION}.deb \
	&& rm /tmp/elasticsearch-${ELASTIC_SEARCH_VERSION}.deb

# Move default configuration files into place
COPY resources/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml
COPY logstash.conf /etc/logstash/conf.d/central.conf

# Elasticsearch HTTP
EXPOSE 9200
# Elasticsearch transport
EXPOSE 9300
# Kibana
EXPOSE 9292
# Redis
EXPOSE 6379

# Start logstash
COPY resources/logstash-server /usr/local/bin/logstash-server
RUN chmod +x /usr/local/bin/logstash-server
ENTRYPOINT ["logstash-server"]
CMD ["start"]