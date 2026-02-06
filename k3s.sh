#!/bin/bash


USAGE="$(basename $0) OPTION [... OPTION]

where OPTION must be one of:
  --init-cluster      build the cluster from scratch
  --api               expose Kubernetes API on localhost:6443
  --prometheus        expose Prometheus on localhost:55525
  --argo              expose ArgoCD on localhost:55526
"

if [ $# -eq 0 ]; then
    printf '%s' "$USAGE"
    exit 1
fi

while [ $# -gt 0 ]; do
    case "$1" in
        (--init-cluster) INIT_CLUSTER=1;;
        (--api) FWD_API=1;;
        (--prometheus) FWD_PROM=1;;
        (--argo) FWD_ARGO=1;;

        (*) WRONG_FLAGS+=("$1")
    esac
    shift
done

if [ -v WRONG_FLAGS ]; then
    printf '%s' "$USAGE"
    exit 1
fi

if [ -v FWD_API ]; then
     if [ ! -v CONTROL_PLANE_NODE ]; then
        echo "CONTROL_PLANE_NODE must be defined"
        exit 1
    fi
    ssh -N -L 6443:127.0.0.1:6443 $CONTROL_PLANE_NODE &
fi

if [ -v FWD_PROM ]; then
    prometheus_svc=$(kubectl get svc -n prometheus | grep -Po '\S+prometheus(?= )')
    kubectl -n prometheus port-forward svc/$prometheus_svc 55525:80
fi

if [ -v FWD_ARGO ]; then
    kubectl -n argocd port-forward svc/argocd-server 55526:80
fi

if [ -v INIT_CLUSTER ]; then
    if [ ! -v CONTROL_PLANE_NODE ]; then
        echo "CONTROL_PLANE_NODE must be defined"
        exit 1
    fi

    if [ ! -v CLOUDFLARE_API_TOKEN ]; then
        echo "CLOUDFLARE_API_TOKEN must be defined"
        exit 1
    fi

    # install cluster and connect the laptop to it
    ssh $CONTROL_PLANE_NODE \
        "curl -sfL https://get.k3s.io | sh -s - \
        --disable traefik \
        --disable servicelb \
        && sudo cat /etc/rancher/k3s/k3s.yaml" \
        > ~/.kube/config

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
fi
