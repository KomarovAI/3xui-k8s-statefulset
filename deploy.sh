#!/bin/bash
set -e
kubectl apply -f manifests/namespace.yaml
kubectl apply -f manifests/storageclass.yaml
kubectl apply -f manifests/persistentvolume.yaml
kubectl apply -f manifests/persistentvolumeclaim.yaml
kubectl apply -f manifests/statefulset.yaml
