FROM ubuntu:18.04
RUN apt-get update; apt-get install -y curl 
RUN apt-get -y install cron
COPY update-cron /
COPY update_public_ip.sh /
COPY loop.sh /
RUN /usr/bin/crontab /update-cron
CMD ["/bin/bash", "-c", "/loop.sh"]
