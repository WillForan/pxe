#!/usr/bin/env sh
set -ex

# setup network, iso mount, and pxe servers
# as described by https://wiki.archlinux.org/index.php/PXE

# expects network interface $iface to not otherwise be managed by network
# needs .iso
# will mount to /mnt/archiso
iso="$(pwd)/archlinux-2019.07.01-x86_64.iso"
mnt=/mnt/archiso
iface=enp4s0

# files
[ ! -d $mnt ] && mkdir -p $mnt
mount | grep $mnt || mount -o loop,ro $iso $mnt

# network
ip link set $iface up
#ip addr add 192.168.0.1/24 dev $iface

cat > dnsmasq.conf <<HEREDOC
port=0
interface=$iface
bind-interfaces
dhcp-range=192.168.0.50,192.168.0.150,12h
dhcp-boot=/arch/boot/syslinux/lpxelinux.0
dhcp-option-force=209,boot/syslinux/archiso.cfg
dhcp-option-force=210,/arch/
dhcp-option-force=66,192.168.0.1
enable-tftp
tftp-root=/mnt/archiso
server=192.168.1.1
HEREDOC

# services
pgrep dnsmasq || /usr/bin/dnsmasq -k --enable-dbus --user=dnsmasq --pid-file  -C ./dnsmasq.conf &
darkhttpd $mnt
