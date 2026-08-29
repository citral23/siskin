#!/bin/bash
set -euxo pipefail

# useradd misses groups defined in /usr/lib/group.
systemd-sysusers
for group in wheel video render input audio seat; do
    gid=$(getent group "$group" | cut -d: -f3)
    [[ -n "$gid" ]] || { echo "ERROR: missing group: $group" >&2; exit 1; }
    if ! grep -q "^${group}:" /etc/group; then
        echo "${group}:x:${gid}:christophe" >> /etc/group
    elif ! id -nG christophe | grep -qw "$group"; then
        gpasswd -a christophe "$group"
    fi
done

install -d -m 0700 -o christophe -g christophe /var/home/christophe
chmod 0700 /var/home/christophe
chown -R christophe:christophe /var/home/christophe

echo 'christophe:christophe' | chpasswd

usermod --add-subuid 100000-165535 --add-subgid 100000-165535 christophe
