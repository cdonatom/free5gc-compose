#! /bin/bash

POD_NAME=f5gc

echo "Stopping pods and destroying containers"
podman pod stop $POD_NAME
echo "y" | podman pod prune
echo "y" | podman container prune

