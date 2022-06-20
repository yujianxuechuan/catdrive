#!/bin/sh

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

export DEBIAN_FRONTEND=noninteractive
apt_arg='-q -y -o Dpkg::Progress-Fancy="0"'

cat <<EOF > ./usr/sbin/policy-rc.d
#!/bin/sh
exit 101

EOF

chmod +x ./usr/sbin/policy-rc.d

/debootstrap/debootstrap --second-stage
apt clean

mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev
mount -t devpts none /dev/pts

cat <<EOF >> ./etc/apt/apt.conf
APT::Install-Recommends "0" ;
APT::Install-Suggests "0" ;

EOF

apt $apt_arg update && \
	apt $apt_arg install aptitude locales openssh-server net-tools parted u-boot-tools zram-tools
apt clean

aptitude search ~prequired ~pimportant -F "%p" |xargs apt $apt_arg install
apt clean

apt $apt_arg purge aptitude && apt $apt_arg autoremove --purge
apt clean

systemctl set-default multi-user.target

cat <<EOF > ./etc/network/interfaces
source /etc/network/interfaces.d/*
auto lo
iface lo inet loopback

allow-hotplug eth0
iface eth0 inet dhcp

EOF

cat <<EOF > ./etc/udev/rules.d/99-hdparm.rules
ACTION=="add", SUBSYSTEM=="block", KERNEL=="sd*",ENV{ID_BUS}=="ata", ENV{DEVTYPE}=="disk", RUN+="/sbin/hdparm -S 120 \$env{DEVNAME}"

EOF

echo "en_US.UTF-8 UTF-8" > ./etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > ./etc/default/locale
ln -sf /usr/share/zoneinfo/Asia/Shanghai ./etc/localtime
sed -i '/^#PermitRootLogin/cPermitRootLogin yes' ./etc/ssh/sshd_config
echo "ttyMV0" >> ./etc/securetty
echo "/dev/root / ext4 defaults,noatime,nodiratime,commit=600,errors=remount-ro 0 1" >> ./etc/fstab
echo "vm.zone_reclaim_mode=1" > ./etc/sysctl.d/99-vm-reclaim.conf
echo "/dev/mtd1 0x0000 0x10000 0x10000" > ./etc/fw_env.config
echo "CatDrive" > ./etc/hostname
echo "root:admin" |chpasswd

rm -f ./etc/ssh/ssh_host_*
rm -rf ./var/log/journal
rm -rf ./var/cache
rm -rf ./var/lib/apt/*
rm -f ./usr/sbin/policy-rc.d
rm -f ./var/lib/dbus/machine-id
: > ./etc/machine-id

umount /dev/pts
umount /dev
umount /sys
umount /proc

