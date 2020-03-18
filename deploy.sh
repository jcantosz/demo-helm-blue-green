#!/bin/bash
VERSION=$1
NAMESPACE=website
PREFIX="website-bg"
PREV_DEPLOYS=$(helm list -n $NAMESPACE | grep $PREFIX | awk '{ print $1 }')
DEPLOY_NAME=$(date +"%Y%m%d-%H%M%s")
RELEASE_NAME="${PREFIX}-${DEPLOY_NAME}"
kubectl create ns $NAMESPACE | true

# Deploy blue
helm install $RELEASE_NAME --wait \
  --namespace $NAMESPACE \
  --set image.tag=$VERSION \
  --set ingress.hosts[0].host=192.168.0.21.xip.io \
  --set ingress.hosts[0].paths[0]=/ \
  ./demo

read -p "deployed blue, move to green?" UPGRADE

if [ "${UPGRADE:0:1}" == "y" ]; then

  # Update ingress
  helm upgrade $RELEASE_NAME --wait \
    --namespace $NAMESPACE \
    --set image.tag=$VERSION \
    --set ingress.hosts[0].host=192.168.0.22.xip.io \
    --set ingress.hosts[0].paths[0]=/ \
    ./demo

  for deploy in $PREV_DEPLOYS; do
    helm delete -n $NAMESPACE $deploy
  done
else
  helm delete -n $NAMESPACE $RELEASE_NAME
fi
