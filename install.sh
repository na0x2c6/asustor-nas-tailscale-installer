#!/bin/sh

set -euvo pipefail

PIDFILE="/var/run/tailscaled.pid"

__error() {
    echo "$@" >&2
    exit 1
}

if [[ $# -lt 1 ]] ; then
    __error "usage: $0 <init-file>"
fi

init_file="$1"

base_dir=$(dirname $0)
backup_dir="$base_dir/backup"

if [[ -e "$PIDFILE" ]] ; then
    sudo start-stop-daemon -K -p $PIDFILE || true
fi

__backup_if_exist() {
    backup_dir=$1
    shift
    mkdir -p $backup_dir
    for f in $@ ; do
        if [[ -e $f ]] ; then
            cp -r $f $backup_dir/
        fi
    done
}
__backup_if_exist $backup_dir /usr/local/bin/tailscale /usr/local/sbin/tailscaled /usr/local/etc/init.d/$init_file

sudo cp -f $base_dir/tailscale  /usr/local/bin/tailscale
sudo cp -f $base_dir/tailscaled /usr/local/sbin/tailscaled
sudo cp -f $base_dir/$init_file /usr/local/etc/init.d/$init_file
sudo chmod +x /usr/local/bin/tailscale
sudo chmod +x /usr/local/sbin/tailscaled
sudo chmod +x /usr/local/etc/init.d/$init_file

sudo /usr/local/etc/init.d/$init_file
