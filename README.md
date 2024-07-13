# VPS config

Running via Oracle Always Free cloud thingy, based in Stockholm.

## Reverse-proxy

The network called _nginx_ is what all apps should use.

## Deployment

Obtained initial cert via removing/commenting out all ssl related stuff from [here](./nginx/conf.d/default.conf) and running the below command:

```sh
docker run -it --rm \
  -v $(pwd)/nginx/certs:/etc/letsencrypt \
  -v $(pwd)/nginx/certs-data:/data/letsencrypt \
  certbot/certbot certonly --webroot \
  --webroot-path=/data/letsencrypt \
  -d apps.ttj.hu -d ora-amp-1.ttj.hu
```

Upon success restore the above lines.
