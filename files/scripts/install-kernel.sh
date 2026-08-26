#!/bin/bash
set -euxo pipefail
shopt -s nullglob

tarballs=(/tmp/kernel/armada-kernel-*.tar.zst)
if [ "${#tarballs[@]}" -ne 1 ]; then
    echo "ERROR: expected exactly one kernel tarball, found ${#tarballs[@]}" >&2
    printf '  %s\n' "${tarballs[@]}" >&2
    exit 1
fi

TARBALL="${tarballs[0]}"
KVER="${TARBALL##*/armada-kernel-}"
KVER="${KVER%.tar.zst}"
CHECKSUM="${TARBALL}.sha256"

dnf5 -y remove kernel kernel-core kernel-modules kernel-modules-core 2>/dev/null || true
rm -rf /usr/lib/modules/*

[ -f "${CHECKSUM}" ] || { echo "ERROR: kernel checksum missing at ${CHECKSUM}" >&2; exit 1; }
( cd /tmp/kernel && sha256sum -c "$(basename "${CHECKSUM}")" )

tar --extract --zstd -f "${TARBALL}" -C /usr/
depmod -a "${KVER}" -b /

rm -rf /tmp/kernel

echo "armada kernel ${KVER} installed at /usr/lib/modules/${KVER}/"
ls -la "/usr/lib/modules/${KVER}/" | head -10
