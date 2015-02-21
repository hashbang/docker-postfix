# Docker Postfix

1. Put SSL certificate files in /home/$USER/slapd/ssl/

    Named as follows: 'cacert.pem' 'server.crt' 'server.key'

2. Edit systemd service and load/start on target server

    ```bash
    vim docker-postfix.conf
    sudo systemctl enable $PWD/docker-postfix.conf
    sudo systemctl start docker-postfix.service
    ```
