#!/bin/bash

newaliases
chown -R root: /etc/aliases
chown -R root: /etc/aliases.db

chown -R root:root /var/spool/postfix
chown -R postfix:postdrop /var/spool/postfix/{deferred,active,incoming,bounce,defer,maildrop,public,flush,corrupt,private,saved,hold,trace}
chown -R root:root /etc/postfix
chmod 755 /etc/aliases.db

mkdir -p /var/spool/postfix/etc/
cp /etc/services    /var/spool/postfix/etc/services
cp /etc/resolv.conf /var/spool/postfix/etc/resolv.conf

service rsyslog start
/usr/sbin/postfix -v -c /etc/postfix start

tail -f /var/log/mail.log
