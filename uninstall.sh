#!/bin/bash
set -e
kubectl delete -f manifests/statefulset.yaml --ignore-not-found
test -f manifests/persistentvolumeclaim.yaml && kubectl delete -f manifests/persistentvolumeclaim.yaml --ignore-not-found
test -f manifests/persistentvolume.yaml && kubectl delete -f manifests/persistentvolume.yaml --ignore-not-found
test -f manifests/storageclass.yaml && kubectl delete -f manifests/storageclass.yaml --ignore-not-found
test -f manifests/namespace.yaml && kubectl delete -f manifests/namespace.yaml --ignore-not-found
