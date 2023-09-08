FROM debian

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get install -y apache2-utils

COPY bench.sh .
