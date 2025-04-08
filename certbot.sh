#!/bin/sh

# this script is invoked from within the certbot container

if [ ! -d "/etc/letsencrypt/live/ttj.hu" ]; then
    certbot certonly \
        --dns-cloudflare \
        --dns-cloudflare-credentials /etc/letsencrypt/cloudflare.ini \
        --email tomjtoth@gmail.com \
        --agree-tos \
        --non-interactive \
        -d *.ttj.hu
fi;

# renewal loop
trap exit TERM;
while :; do
    certbot renew \
        --dns-cloudflare \
        --dns-cloudflare-credentials /etc/letsencrypt/cloudflare.ini \
        --post-hook "echo Certificates renewed!";

    sleep 12h & wait $!;
done
