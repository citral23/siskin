#!/bin/bash
set -euxo pipefail

KVER="$(ls /usr/lib/modules)"
IMG="/usr/lib/modules/${KVER}/initramfs.img"

mkdir -p /var/roothome

dracut \
    --force \
    --no-hostonly \
    --reproducible \
    --kver "${KVER}" \
    --add ostree \
    "${IMG}" "${KVER}"

echo "initramfs generated for ${KVER}"
ls -la "${IMG}"
