# VPS config

Running via Oracle Always Free, based in Stockholm.

## Reverse-proxy

The network called _nginx_ is what all apps should use.

## Deployment

The below commands make creating the initial SSL certificate possible without nginx tripping on their absence. After the certs are created the other names are also served.

```sh
# delete any server definitions requiring ssl certs
# that would force nginx to exit with code 1
rm ./nginx/conf.d/{apps,root}.conf

# launch the server handling the certbot challenge
docker compose up -d

# request initial certs
# subdomains should be in sync with DNS settings
docker run -it --rm \
  -v ./nginx/certs:/etc/letsencrypt \
  -v ./nginx/certs-data:/data/letsencrypt \
  certbot/certbot certonly --webroot \
  --non-interactive --agree-tos \
  --email tomjtoth@gmail.com \
  --webroot-path=/data/letsencrypt \
  -d apps.ttj.hu \
  -d veripalvelu.ttj.hu \
  -d saldo.ttj.hu \
  -d bloglist.ttj.hu \
  -d puhelinluettelo.ttj.hu \
  -d done.ttj.hu

# restore the deleted config files
git restore .

# make those file visible to nginx
docker compose restart
```

## Include additional domains

```sh
# subdomains should be in sync with DNS settings
docker run -it --rm \
  -v ./nginx/certs:/etc/letsencrypt \
  -v ./nginx/certs-data:/data/letsencrypt \
  certbot/certbot certonly --webroot \
  --non-interactive --agree-tos \
  --email tomjtoth@gmail.com \
  --webroot-path=/data/letsencrypt \
  -d apps.ttj.hu \
  -d veripalvelu.ttj.hu \
  -d saldo.ttj.hu \
  -d bloglist.ttj.hu \
  -d puhelinluettelo.ttj.hu \
  -d done.ttj.hu \
  -d something-new.ttj.hu \
  -d something-new-2.ttj.hu
```
