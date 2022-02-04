FROM ubuntu:focal
MAINTAINER Joachim Wickman <joachim@wickman.in>
ARG BUILD_DATE
ARG VCS_REF

ENV APACHE_LOG_DIR=/var/log/apache2 \
    DBNAME=mythtv \
    DBSERVER=mariadb \
    DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    LOCALHOSTNAME= \
    TZ=UTC

ARG APT_KEY=13551B881504888C
ARG MYTHTV_GID=100
ARG MYTHTV_UID=1026
ARG MYTHTV_PPA=http://ppa.launchpad.net/mythbuntu/32
ARG MYTHTV_VERSION=2:32.0+fixes.202202031804.769518c4c6~ubuntu20.04.1
ARG SSH_PORT=22
ARG MYTHWEB_PORT=80

RUN \
  apt-get -yq update && apt-get install -yq gnupg locales wget && \
  apt-key adv --recv-keys --keyserver keyserver.ubuntu.com $APT_KEY && \
  echo "deb $MYTHTV_PPA/ubuntu focal main" \
    > /etc/apt/sources.list.d/mythbuntu.list && \
  apt-get -yq update && \
  locale-gen $LANG && \
  apt-get -yq --no-install-recommends install \
    apache2 curl iputils-ping less lsb-release mariadb-client net-tools \
    openssh-client openssh-server mythtv-backend=$MYTHTV_VERSION \
    mythtv-common=$MYTHTV_VERSION mythtv-transcode-utils=$MYTHTV_VERSION \
    mythweb=$MYTHTV_VERSION libmyth-python php-mythtv psmisc sudo tzdata \
    v4l-utils vim w3m x11-utils xauth xmltv xterm

COPY src/ /root/

RUN \
  sed -i -e "s/Listen 80/Listen $MYTHWEB_PORT/" /etc/apache2/ports.conf && \
  sed -i -e "s/#Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config && \
  sed -i -e "s/#AddressFamily all/AddressFamily inet/" /etc/ssh/sshd_config && \
  mv /root/mythweb.conf /root/mythweb-settings.conf \
    /etc/apache2/sites-available/ && \
  usermod -u $MYTHTV_UID -s /bin/bash mythtv && \
  mkdir -p /var/lib/mythtv $APACHE_LOG_DIR && \
  echo "mythtv:mythtv" | chpasswd && \
  chown $MYTHTV_UID:$MYTHTV_GID /var/lib/mythtv
RUN \
  cat /etc/apache2/ports.conf

EXPOSE $MYTHWEB_PORT $SSH_PORT 5000/udp 5002/udp 5004/udp 6543 6544 6549 65001 65001/udp 
VOLUME $APACHE_LOG_DIR
ENTRYPOINT ["/root/entrypoint.sh"]
