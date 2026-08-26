#!/bin/bash
set -euxo pipefail

install -Dpm 0755 "/tmp/files/vendor/mkbootimg/mkbootimg.py" /usr/libexec/armada/mkbootimg.py
install -Dpm 0755 "/tmp/files/vendor/mkbootimg/gki/generate_gki_certificate.py" /usr/libexec/armada/gki/generate_gki_certificate.py
sha256sum -c <<'EOF'
37d84b3d162e0bc62e36c1f4e1c63c85ea0caa9f29be023eb2f8efe006ad948c  /usr/libexec/armada/mkbootimg.py
1bb1feec68a13da18d581aa2c631798f86f6bc10b55d587b2dd31446a0f8a203  /usr/libexec/armada/gki/generate_gki_certificate.py
EOF

source "/tmp/files/abl/release.env"
abl_archive=/tmp/rocknix-abl.tar.gz
curl --connect-timeout 30 --retry 3 -fsSL -o "${abl_archive}" \
    "https://github.com/ROCKNIX/abl/releases/download/v${ARMADA_ABL_VERSION}/rocknix-abl-v${ARMADA_ABL_VERSION}.tar.gz"
printf '%s  %s\n' "${ARMADA_ABL_ARCHIVE_SHA256}" "${abl_archive}" | sha256sum -c -
abl_src=/tmp/rocknix-abl
mkdir -p "${abl_src}"
tar -xzf "${abl_archive}" -C "${abl_src}" --strip-components=1
manifest=/usr/lib/armada/abl/manifest
install -Dpm 0644 /dev/null "${manifest}"
printf 'ARMADA_ABL_VERSION=%s\nARMADA_ABL_AUTO=%s\n' \
    "${ARMADA_ABL_VERSION}" "${ARMADA_ABL_AUTO}" >> "${manifest}"
abl_version=${ARMADA_ABL_VERSION}
for soc in SM8250 SM8550 SM8650 SM8750; do
    payload="/usr/lib/armada/abl/abl_signed-${soc}.elf"
    install -Dpm 0644 "${abl_src}/abl_signed-${soc}.elf" \
        "${payload}"
    reported=$(python3 /usr/lib/armada/abl-version "${payload}")
    [ "${reported}" = "${abl_version}" ] || {
        echo "ERROR: ${soc} payload reports ${reported}, expected ${abl_version}" >&2
        exit 1
    }
    printf 'ARMADA_ABL_SHA256_%s=%s\n' "${soc}" \
        "$(sha256sum "${payload}" | cut -d ' ' -f 1)" \
        >> "${manifest}"
done
rm -f "${abl_archive}"
rm -rf "${abl_src}"

chmod 0755 /usr/libexec/armada/*
