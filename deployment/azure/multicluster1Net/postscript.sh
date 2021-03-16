#!/usr/bin/env sh
istioctl x create-remote-secret --context=cluster1 --name=cluster1 | kubectl apply -f - --context=cluster2
istioctl x create-remote-secret --context=cluster2 --name=cluster2 | kubectl apply -f - --context=cluster1
kubectl label ns default istio-injection=enabled --context=cluster1
kubectl label ns default istio-injection=enabled --context=cluster2