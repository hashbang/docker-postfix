#!/bin/sh -e

postconf -e myhostname="$HOSTNAME"
postconf -e transport_maps="ldap:/etc/postfix/ldap-transport.cf"
postconf -e relay_domains="hashbang.sh"
postconf -e mynetworks="127.0.0.0/8 104.245.35.240 104.245.37.138 45.58.35.111 45.58.38.222"
postconf -e virtual_alias_maps="ldap:/etc/postfix/ldap-aliases.cf"

if [ -n "$LDAP_HOST" ]; then
    cat >> /etc/postfix/ldap-transport.cf <<EOF
server_host = $LDAP_HOST
search_base = ou=People,dc=hashbang,dc=sh
domain = hashbang.sh
query_filter = (&(objectclass=inetLocalMailRecipient)(uid=%U))
result_attribute = host
result_format = smtp:[%s]
EOF

    cat >> /etc/postfix/ldap-aliases.cf <<EOF
server_host = ldap.hashbang.sh
search_base = ou=People,dc=hashbang,dc=sh
domain = hashbang.sh
query_filter = (&(objectclass=inetLocalMailRecipient)(uid=%U))
result_attribute = host
result_format = %U@%s
EOF

fi

if [ -n "$(find /etc/postfix/certs -iname '*.crt')" -a \
     -n "$(find /etc/postfix/certs -iname '*.key')" -a \
     -n "$(find /etc/postfix/certs -iname '*.pem')"    \
   ]; then

    echo "Certificates found, enabling TLS."
    chmod 400 /etc/postfix/certs/*

    postconf -e smtpd_tls_cert_file="$(find /etc/postfix/certs -iname '*.crt')"
    postconf -e smtpd_tls_key_file="$(find /etc/postfix/certs -iname '*.key')"
    postconf -e smtpd_tls_CAfile="$(find /etc/postfix/certs -iname '*.pem')"
    postconf -e smtpd_tls_security_level=may
    postconf -e smtpd_tls_auth_only=no
    postconf -e smtpd_tls_loglevel=1
    postconf -e smtpd_tls_received_header=yes
    postconf -e smtpd_tls_session_cache_timeout=3600s

    # Enforce TLS if DANE record found
    postconf -e smtp_tls_security_level=dane
    postconf -e smtp_dns_support_level=dnssec

    postconf -e smtp_tls_note_starttls_offer=yes

    # Increase max. message size to 50 MiB
    postconf -e message_size_limit=52428800
elif [ -n "$MUST_SSL" ]; then
    echo "SSL is required, but files missing" >2
    exit 1
fi

ln /etc/services    /var/spool/postfix/etc/services
cp /etc/resolv.conf /var/spool/postfix/etc/resolv.conf

service rsyslog start
/usr/sbin/postfix -v -c /etc/postfix start

tail -f /var/log/mail.log
