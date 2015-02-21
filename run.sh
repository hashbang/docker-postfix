#!/bin/bash

postconf -e myhostname=$HOSTNAME
postconf alias_maps=hash:/etc/aliases,ldap:/etc/postfix/ldap-aliases.cf

if [[ -n $LDAP_HOST ]]; then

    DC1=$( echo $LDAP_HOST | sed "s/[A-Za-z0-9-]\+\.\([A-Za-z0-9-]\+\)\.\([A-Za-z0-9-]\)\+/\1/g" )
    DC2=$( echo $LDAP_HOST | sed "s/[A-Za-z0-9-]\+\.\([A-Za-z0-9-]\+\)\.\([A-Za-z0-9-]\)\+/\2/g" )
    cat >> /etc/postfix/ldap-aliases.cf <<EOF
server_host = $LDAP_HOST
search_base = dc=$DC1, dc=$DC2
EOF

fi

if [[ -n "$(find /etc/postfix/certs -iname *.crt)" && \
      -n "$(find /etc/postfix/certs -iname *.key)" && \
      -n "$(find /etc/postfix/certs -iname *.pem)"
   ]]; then

    echo "Certificates found, enabling TLS."
    chmod 400 /etc/postfix/certs/*.*

    postconf -e mydestination="localhost, mail.hashbang.sh, hashbang.sh"
    postconf -e smtpd_tls_cert_file=$(find /etc/postfix/certs -iname *.crt)
    postconf -e smtpd_tls_key_file=$(find /etc/postfix/certs -iname *.key)
    postconf -e smtpd_tls_CAfile=$(find /etc/postfix/certs -iname *.pem)
    postconf -e smtpd_tls_security_level=may
    postconf -e smtpd_tls_auth_only=no
    postconf -e smtpd_tls_loglevel=1
    postconf -e smtpd_tls_received_header=yes
    postconf -e smtpd_tls_session_cache_timeout=3600s
    postconf -e smtp_tls_note_starttls_offer= yes
    postconf -e smtp_tls_security_level=may
fi

/usr/sbin/postfix -v -c /etc/postfix start
touch /var/log/mail.log
tail -f /var/log/mail.*
