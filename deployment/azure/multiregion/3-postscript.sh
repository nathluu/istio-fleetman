#!/usr/bin/env bash
ctxs=$(kubectl config view -o jsonpath='{.contexts[*].name}' | sed 's/ /\n/g' | grep -v "docker-desktop")
for ctx in $ctxs; do
    kubectl label ns default istio-injection=enabled --context="${ctx}"
done