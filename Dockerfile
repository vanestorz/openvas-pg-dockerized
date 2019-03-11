FROM fedora

LABEL maintainer="andhika.haeruman@andhikahs.tech"

RUN dnf -y update
RUN dnf -y install openvas-* redis bzip2 which findutils sqlite procps-ng nmap mingw32-nsis texlive-latex-bin-bin openssh gnutls-utils net-tools alien nikto ike-scan net-snmp-utils openldap-clients samba-client ncrack ssmtp gnupg less
RUN sed -i 's|# unixsocket |unixsocket |' /etc/redis.conf
RUN sed -i 's|daemonize no|daemonize yes|' /etc/redis.conf
RUN sed -i 's|port 6379|port 0|' /etc/redis.conf
RUN mkdir -p /var/lib/openvas/openvasmd/gnupg

COPY startd update /usr/sbin/

RUN dnf -y install dnf-plugins-core
RUN dnf download --source openvas-manager
RUN rpm -i openvas-manager-*.src.rpm
COPY openvas-manager.spec-*-postgresql.patch /
RUN patch $HOME/rpmbuild/SPECS/openvas-manager.spec openvas-manager.spec-*-postgresql.patch
RUN dnf -y builddep $HOME/rpmbuild/SPECS/openvas-manager.spec
RUN rpmbuild -bb $HOME/rpmbuild/SPECS/openvas-manager.spec
RUN dnf -y reinstall $HOME/rpmbuild/RPMS/x86_64/openvas-manager-*.x86_64.rpm
RUN echo "/usr/lib/openvasmd/pg" > /etc/ld.so.conf.d/openvas-manager.conf
RUN ldconfig

# Add Tini for best performance management
ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini.asc /tini.asc
RUN gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 595E85A6B1B4779EA4DAAEC70B588DFF0527A9B7 \
 && gpg --verify /tini.asc
RUN chown -R ${user} /usr/sbin/startd && chown -R ${user} /usr/sbin/update
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

CMD ["/usr/sbin/startd"]