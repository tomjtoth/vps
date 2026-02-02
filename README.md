# k3s @ [Oracle](https://www.oracle.com/cloud/free/)

Tässä konfiguraatio joka palvelee k3s clusterissa Ruotsissa.
Aktiiviset sovellukset löytyvät [täältä](https://ttj.hu#apps).

## Clusterin konfig

Kusterin **control-plane node**ssä:

```sh
curl -sfL https://get.k3s.io | sh -s - \
    --disable traefik \
    --disable servicelb
```

Klusterin jokaisessa **agent node**ssa:

```sh
K3S_TOKEN=$(ssh control-plane-node "sudo cat /var/lib/rancher/k3s/server/node-token")

curl -sfL https://get.k3s.io | \
    K3S_URL=https://ora-amp-2.subnet03260926.vcn03260926.oraclevcn.com:6443 \
    K3S_TOKEN=$K3S_TOKEN \
    sh -s -
```

**Läppäri**ssä:

```sh
CONTROL_PLANE_NODE=
CLOUDFLARE_API_TOKEN=

# connect laptop to the cluster
ssh $CONTROL_PLANE_NODE \
    "sudo cat /etc/rancher/k3s/k3s.yaml" \
    > ~/.kube/config

# port-forward for the Kubernetes API
ssh -N -L 6443:127.0.0.1:6443 $CONTROL_PLANE_NODE &

kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.4/cert-manager.yaml
kubectl create secret generic cloudflare-api-token \
  --namespace cert-manager \
  --from-literal=api-token=$CLOUDFLARE_API_TOKEN

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.3/deploy/static/provider/cloud/deploy.yaml
kubectl -n ingress-nginx patch deploy ingress-nginx-controller \
  --type=json -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value":"--default-ssl-certificate=ingress-nginx/ttj-wildcard-tls"}]'
kubectl apply \
    -f manifests/vps/cert-manager.yml \
    -f manifests/vps/nginx.yml

kubectl create namespace prometheus
helm install prometheus-community/kube-prometheus-stack \
    --generate-name \
    --namespace prometheus
```

## Sovellukset tuotantoon

Tässä lähinnä muistutukset itselleni.

1.  Sovellusten vaatimat salaisuudet
    - avaa hakemisto, josta löytyy `.env.<APP>` tiedosto(t)
    - säädä arvoit oikein
    - sit aja alla komennot

    ```sh
    init_app_secrets(){
        local dotenv
        while [ $# -gt 0 ]; do
            dotenv=.env.$1

            if [ -f $dotenv ]; then
                kubectl create ns $1

                kubectl -n $1 create secret generic $1-secrets \
                    --from-env-file=$dotenv
            else
                echo "  ERROR: '$dotenv' is not a file"
            fi

            shift
        done
    }

    init_app_secrets saldo veripalvelu
    ```

2.  Laita [sovellukset](kustomization.yml) pyörimään

    ```sh
    kubectl apply -k .
    ```

Serti kattaa jokaisen subdomain:in `*.ttj.hu`, ja käyttää [Cloudflare:in API-tokenin](https://dash.cloudflare.com/profile/api-tokens).
