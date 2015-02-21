FROM debian:jessie

ENV HOSTNAME mail.hashbang.sh

ENV LDAP_HOST ldap.hashbang.sh

RUN apt-get update && \
    LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get install -y postfix postfix-ldap && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

VOLUME /etc/postfix/certs

ADD run.sh /

EXPOSE 25

CMD ["bash","/run.sh"]
