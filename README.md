# Kuvaus

Tässä konfiguraatio joka palvelee Ruotsissa (kiitos [Oracle Cloud Free Tier](https://www.oracle.com/cloud/free/)).
Aktiiviset sovellukset ovat listattuja [täällä](https://ttj.hu#apps).

## Tuotantoon

Tässä lähinnä muistutukset itselleni.

Aja alla komento joka luo alkuperaisen sertifikaatin ja huolehtii myös sen uusinnasta:

```sh
docker compose up -d
```

Serti kattaa jokaisen subdomain:in `*.ttj.hu`, ja käyttää [Cloudflare:in API-tokenin](https://dash.cloudflare.com/profile/api-tokens).
