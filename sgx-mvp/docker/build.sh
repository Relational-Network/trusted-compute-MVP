#!/usr/bin/env bash
# Nautilus Trusted Compute
# Copyright (C) 2025 Nautilus

set -euo pipefail

export DOCKER_BUILDKIT=1

usage() {
    echo "Usage: build.sh [ubuntu20|ubuntu22]"
    exit 1
}

if [ $# -ne 1 ]; then
    usage
fi

image=""
codename=""
key_path="../keys/enclave-key.pem"

case "$1" in
    ubuntu20)
        image="ubuntu:20.04"
        codename="focal"
        ;;
    ubuntu22)
        image="ubuntu:22.04"
        codename="jammy"
        ;;
    *)
        usage
        ;;
esac

if [ ! -f "$key_path" ]; then
    echo "ERROR: Signing key not found at $key_path"
    exit 1
fi

docker buildx build \
    --load \
    --build-arg UBUNTU_IMAGE="${image}" \
    --build-arg UBUNTU_CODENAME="${codename}" \
    --secret id=enclave_key,src="$key_path" \
    -t sgx-mvp:stable-"${codename}" \
    .

# Extract sig
container_id=$(docker create sgx-mvp:stable-"${codename}")
docker cp "$container_id":/app/sgx-mvp/sgx-mvp.sig docker-sgx-mvp.sig
docker rm "$container_id"

echo "Build complete!"