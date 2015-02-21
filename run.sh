#!/bin/bash

postconf -e myhostname=$HOSTNAME
postconf alias_maps=hash:/etc/aliases,ldap:/etc/postfix/ldap-aliases.cf
postconf -e mydestination="localhost, mail.hashbang.sh, hashbang.sh"

if [[ -n $LDAP_HOST ]]; then
    cat >> /etc/postfix/ldap-aliases.cf <<EOF
server_host = ldap.hashbang.sh
search_base = ou=People,dc=hashbang,dc=sh
query_filter = mailRoutingAddress=%s
result_attribute = host
result_format = %U@%s
EOF

fi

if [[ -n "$(find /etc/postfix/certs -iname *.crt)" && \
      -n "$(find /etc/postfix/certs -iname *.key)" && \
      -n "$(find /etc/postfix/certs -iname *.pem)"
   ]]; then

    echo "Certificates found, enabling TLS."
    chmod 400 /etc/postfix/certs/*.*

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
