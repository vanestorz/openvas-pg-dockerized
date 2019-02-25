FROM ubuntu:16.04

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && \
    apt-get install software-properties-common --no-install-recommends -yq

RUN apt-get install build-essential rsync cmake wget curl nmap apt-utils \
                    python-software-properties software-properties-common \
                    pkg-config python-dev git git-all \
                    libssh-dev libgnutls28-dev libglib2.0-dev libpcap-dev \
                    libgpgme11-dev uuid-dev bison libksba-dev libsnmp-dev \
                    libgcrypt20-dev libldap2-dev libxml2-dev libxslt1-dev \
                    gettext gnutls-bin libgcrypt20 \
                    python-software-properties \
                    xmltoman doxygen xsltproc libmicrohttpd-dev \
                    wapiti nsis rpm alien dnsutils libical-dev \
                    net-tools openssh-client sendmail vim nano apt-transport-https \
                    texlive-latex-extra texlive-latex-base texlive-latex-recommended \
                    htmldoc python2.7 python-setuptools python-pip sqlfairy python-polib \
                    perl-base heimdal-dev heimdal-multidev autoconf sqlite3 libsqlite3-dev redis-server \
                    libhiredis-dev libpopt-dev libxslt-dev gnupg wget \
                    postgresql-9.5 libpq-dev postgresql-server-dev-all postgresql-client-9.5 postgresql-contrib-9.5 unzip \
                    -yq --allow-downgrades --allow-remove-essential --allow-change-held-packages

RUN echo "Create auxiliary files and directories" && \
    mkdir -p /var/run/redis && \
    mkdir /openvas-temp && \
    mkdir -p /openvas
ADD scripts/install.sh /openvas/
ADD scripts/start.sh /openvas/
ADD configuration/redis.config /etc/redis/redis.config

RUN echo "[OpenVAS] Install OpenVAS..." && \
    cd /openvas-temp && \
    wget -nv --no-check-certificate https://wald.intevation.org/frs/download.php/2420/openvas-libraries-9.0.1.tar.gz && \
    wget -nv --no-check-certificate https://wald.intevation.org/frs/download.php/2423/openvas-scanner-5.1.1.tar.gz && \
    wget -nv --no-check-certificate https://wald.intevation.org/frs/download.php/2448/openvas-manager-7.0.2.tar.gz && \
    wget -nv --no-check-certificate https://wald.intevation.org/frs/download.php/2429/greenbone-security-assistant-7.0.2.tar.gz && \
    wget -nv --no-check-certificate https://wald.intevation.org/frs/download.php/2397/openvas-cli-1.4.5.tar.gz && \
    wget -nv --no-check-certificate https://wald.intevation.org/frs/download.php/2401/ospd-1.2.0.tar.gz && \
    echo "Untar all OpenVAS files" && \
    cat *.tar.gz | tar -xzvf - -i

RUN echo "Install OpenVAS Libraries" && \
    cd /openvas-temp/openvas-libraries-* && \
    mkdir build && cd build && \
    cmake .. && \
    make && make doc && make install && make rebuild_cache

RUN echo "Install OpenVAS Scanner" && \
    cd /openvas-temp/openvas-scanner-* && \
    mkdir build && cd build && \
    cmake .. && \
    make && make doc && make install && make rebuild_cache

RUN echo "Install OpenVAS Manager" && \
    cd /openvas-temp/openvas-manager-* && \
    mkdir build && cd build && \
    cmake -DBACKEND=POSTGRESQL .. && \
    make && make doc && make install && make rebuild_cache

RUN echo "Install OpenVAS CLI" && \
    cd /openvas-temp/openvas-cli-* && \
    mkdir build && cd build && \
    cmake .. && \
    make && make doc && make install && make rebuild_cache

RUN echo "Install Greenbone Web Interface" && \
    cd /openvas-temp/greenbone-security-assistant-* && \
    mkdir build && cd build && \
    cmake .. && \
    make && make doc && make install && make rebuild_cache

RUN apt-get autoremove -yq && \
    rm -rf /var/lib/apt/lists/*
RUN rm -rf /openvas-temp

RUN ldconfig
RUN chmod 700 /openvas/*.sh && \
    bash /openvas/install.sh

RUN sed -i 's|^# unixsocket perm 755|unixsocketperm 755|;s|^# unixsocket /var/run/redis/redis.sock|unixsocket /tmp/redis.sock|;s|^port 6379|#port 6379|' /etc/redis/redis.conf

RUN wget https://svn.wald.intevation.org/svn/openvas/trunk/tools/openvas-check-setup --no-check-certificate -O /openvas/openvas-check-setup && \
    chmod a+x /openvas/openvas-check-setup

CMD ["/bin/bash", "/openvas/start.sh"]

EXPOSE 4000 7432