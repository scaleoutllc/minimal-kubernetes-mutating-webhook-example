#!/bin/bash

# create a kind cluster that supports mutating webhooks
kind delete cluster -n webhook
kind create cluster -n webhook --config <(cat <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
kubeadmConfigPatches:
- |
  apiVersion: kubeadm.k8s.io/v1beta2
  kind: ClusterConfiguration
  metadata:
    name: config
  apiServer:
    extraArgs:
      "enable-admission-plugins": "NamespaceLifecycle,LimitRanger,ServiceAccount,TaintNodesByCondition,Priority,DefaultTolerationSeconds,DefaultStorageClass,PersistentVolumeClaimResize,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota"
nodes:
- role: control-plane
EOF
)

# MutatingWebhookConfiguration resources define where the control plane should
# send incoming manifests for modification before they are applied to the
# cluster. TLS is required for services peforming this function (see main.go).
# The following generates the required PKI to allow that secure communication.
mkdir -p pki
openssl genrsa -out webhook/pki/ca.key 2048
openssl req -new -x509 -days 365 -key webhook/pki/ca.key -subj "/C=CN/ST=GD/L=SZ/O=Scaleout/CN=webhook.default.svc" -out webhook/pki/ca.crt
openssl req -newkey rsa:2048 -nodes -keyout webhook/pki/server.key -subj "/C=CN/ST=GD/L=SZ/O=Scaleout/CN=webhook.default.svc" -out webhook/pki/server.csr
openssl x509 -req -extfile <(printf "subjectAltName=DNS:labelmutation.default.svc") -days 365 -in webhook/pki/server.csr -CA webhook/pki/ca.crt -CAkey webhook/pki/ca.key -CAcreateserial -out webhook/pki/server.crt