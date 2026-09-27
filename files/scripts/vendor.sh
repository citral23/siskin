#!/bin/bash
set -euxo pipefail

install -Dpm 0755 "/tmp/files/vendor/mkbootimg/mkbootimg.py" /usr/libexec/armada/mkbootimg.py
install -Dpm 0755 "/tmp/files/vendor/mkbootimg/gki/generate_gki_certificate.py" /usr/libexec/armada/gki/generate_gki_certificate.py
sha256sum -c <<'EOF'
37d84b3d162e0bc62e36c1f4e1c63c85ea0caa9f29be023eb2f8efe006ad948c  /usr/libexec/armada/mkbootimg.py
1bb1feec68a13da18d581aa2c631798f86f6bc10b55d587b2dd31446a0f8a203  /usr/libexec/armada/gki/generate_gki_certificate.py
EOF

source "/tmp/files/abl/release.env"
abl_releases=/tmp/files/abl/releases.tsv
abl_src=/tmp/files/abl
manifest=/usr/lib/armada/abl/manifest
install -Dpm 0644 /dev/null "${manifest}"
install -Dpm 0644 "${abl_releases}" /usr/lib/armada/abl/releases.tsv
printf 'ARMADA_ABL_VERSION=%s\nARMADA_ABL_AUTO=%s\n' \
    "${ARMADA_ABL_VERSION}" "${ARMADA_ABL_AUTO}" >> "${manifest}"
for soc in SM8250 SM8550 SM8650 SM8750; do
    approved=$(ARMADA_ABL_RELEASES="${abl_releases}" \
        python3 /usr/lib/armada/abl-version --lookup "${ARMADA_ABL_VERSION}" "${soc}") || {
        echo "ERROR: missing approved ${ARMADA_ABL_VERSION} ${soc} payload" >&2
        exit 1
    }
    read -r approved_size approved_hash <<<"${approved}"
    payload="/usr/lib/armada/abl/abl_signed-${soc}.elf"
    install -Dpm 0644 "${abl_src}/abl_signed-${soc}.elf" \
        "${payload}"
    [[ $(stat -c %s "${payload}") == "${approved_size}" ]] || {
        echo "ERROR: ${soc} payload size does not match the approved release" >&2
        exit 1
    }
    actual_hash=$(sha256sum "${payload}" | cut -d ' ' -f 1)
    [[ ${actual_hash} == "${approved_hash}" ]] || {
        echo "ERROR: ${soc} payload hash does not match the approved release" >&2
        exit 1
    }
    identity=$(ARMADA_ABL_RELEASES=/usr/lib/armada/abl/releases.tsv \
        python3 /usr/lib/armada/abl-version --with-soc "${payload}")
    [[ ${identity} == "${ARMADA_ABL_VERSION} ${soc}" ]] || {
        echo "ERROR: ${soc} payload catalog identity is ${identity:-unknown}" >&2
        exit 1
    }
    printf 'ARMADA_ABL_SHA256_%s=%s\n' "${soc}" \
        "${actual_hash}" \
        >> "${manifest}"
done

chmod 0755 /usr/libexec/armada/*
