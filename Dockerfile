FROM ubuntu:16.04

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && \
    apt-get install software-properties-common --no-install-recommends -yq

RUN apt-get install build-essential rsync cmake wget curl nmap apt-utils \
                    python-software-properties software-properties-common \
                    pkg-config python-dev git \
                    libssh-dev libgnutls28-dev libglib2.0-dev libpcap-dev \
                    libgpgme11-dev uuid-dev bison libksba-dev libsnmp-dev \
                    libgcrypt20-dev libldap2-dev libxml2-dev libxslt1-dev \
                    gettext gnutls-bin libgcrypt20 \
                    python-software-properties \
                    xmltoman doxygen xsltproc libmicrohttpd-dev \
                    wapiti nsis rpm alien dnsutils \
                    net-tools openssh-client sendmail vim nano \
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
    wget -nv https://github.com/greenbone/gvm-libs/archive/master.zip && \
    wget -nv https://github.com/greenbone/openvas-scanner/archive/master.zip && \
    wget -nv https://github.com/greenbone/gvmd/archive/master.zip && \
    wget -nv https://github.com/greenbone/gsa/archive/master.zip && \
    wget -nv https://github.com/greenbone/gvm-tools/archive/master.zip && \
    wget -nv https://github.com/greenbone/ospd/archive/master.zip && \
    echo "Unzip all OpenVAS files" && \
    cat *.zip | unzip master

RUN echo "Install GVM Libraries" && \
    cd /openvas-temp/gvm-libs-master && \
    mkdir build && cd build && \
    cmake .. && \
    make && make doc && make install && make rebuild_cache

RUN echo "Install OpenVAS Scanner" && \
    cd /openvas-temp/openvas-scanner-master && \
    mkdir build && cd build && \
    cmake .. && \
    make && make doc && make install && make rebuild_cache

RUN echo "Install GVMD" && \
    cd /openvas-temp/gvmd-master && \
    mkdir build && cd build && \
    cmake -DBACKEND=POSTGRESQL .. && \
    make && make doc && make install && make rebuild_cache

RUN echo "Install GVM-Tools" && \
    cd /openvas-temp/gvm-tools-master && \
    pip install .

RUN echo "Install OSPD" && \
    cd /openvas-temp/ospd-master && \
    pip install .

RUN echo "Install Greenbone Web Interface" && \
    cd /openvas-temp/gsa-master && \
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