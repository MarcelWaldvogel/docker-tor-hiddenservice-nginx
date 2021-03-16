#!/bin/bash
# Usage:
# 1. main.sh generate <regex for onion address>
# 2. main.sh serve

function save() {
  [ -f "$1" ] && mv "$1" "$1".`date +%s`-$RANDOM
}

if [ "$1" == "generate" ]
then
    if [ -f /web/private_key ]
    then
        echo '[-] You already have an private key, delete it if you want to generate a new key'
        exit 1
    fi
    if [ -z "$2" ]
    then
        echo '[-] You did not provide any mask, please add a mask to generate your address'
        exit 1
    else
        echo '[+] Generating the address with mask: '$2
        shallot -f /tmp/key $2
        echo '[+] '$(grep Found /tmp/key)
        grep 'BEGIN RSA' -A 99 /tmp/key > /web/private_key
    fi

    address=$(grep Found /tmp/key | cut -d ':' -f 2 )

    echo '[+] Generating nginx configuration for site '$address
    save /web/site.conf
    cat << EOF > /web/site.conf
server {
  listen 127.0.0.1:8080;
  root /web/www/;
  index index.html index.htm;
  server_name '$address';
}
EOF
    echo '[+] Creating www folder'
    mkdir -p /web/www
    chmod 755 /web/
    chmod 755 /web/www
    echo '[+] Generating index.html template'
    save /web/www/index.html
    echo '<html><head><title>Your very own hidden service is ready</title></head><body><h1>Well done!</h1></body></html>' > /web/www/index.html
    chown hidden:hidden -R /web/www
fi

if [ "$1" == "serve" ]
then
    if [ ! -f /web/private_key ]
    then
        echo '[-] Please run this container with "generate" argument to initialize your web site'
	echo '[-] (e.g., docker run tor generate ^pattern)'
        exit 1
    fi
    echo '[+] Starting tor'
    tor -f /etc/tor/torrc &
    echo '[+] Starting nginx'
    exec nginx
fi
