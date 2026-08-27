#!/bin/bash
set -euxo pipefail

# useradd misses groups defined in /usr/lib/group.
systemd-sysusers
for group in wheel video render input audio; do
    gid=$(getent group "$group" | cut -d: -f3)
    [[ -n "$gid" ]] || { echo "ERROR: missing group: $group" >&2; exit 1; }
    if ! grep -q "^${group}:" /etc/group; then
        echo "${group}:x:${gid}:christophe" >> /etc/group
    elif ! id -nG armada | grep -qw "$group"; then
        gpasswd -a armada "$group"
    fi
done

install -d -m 0700 -o christophe -g christophe /var/home/christophe
chmod 0700 /var/home/christophe
cp -af /etc/skel/. /var/home/christophe/
chown -R christophe:christophe /var/home/christophe

echo 'christophe:christophe' | chpasswd
