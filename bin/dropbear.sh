#!/usr/bin/env bash

# SOURCES
# https://github.com/mkj/dropbear
# https://dtbaker.net/blog/howto-enable-ssh-on-android-and-network-adb/
# https://stackoverflow.com/a/67666567/15454191


fn="${1:-dropbear}"
src="../static-cross-bins/output/arm-linux-musleabi/bin/"
dest="/system/bin/"

# push dropbear binary to android device if present
adb shell mount -o rw,remount "/system"
[[ -f "${src}/${fn}" ]] && adb push "${src}/dropbear" "$dest"

# copy ssh key to android device
adb push ~/.ssh/id_rsa.pub "/sdcard/authorized_keys"

# setup su if root isn't tied to uid 0
adb shell grep -q "root:x:0:0:root:/root:/system/bin/sh" /etc/passwd
if [ $? -ne 0 ]; then
	adb shell <<-EOF
		su
		mount -o rw,remount "/system"
		echo "root:x:0:0:root:/root:/system/bin/sh" >> /etc/passwd
		exit
		exit
	EOF
fi

# create ssh directory and move key
adb shell <<-EOF
    su
    mount -o rw,remount "/system"
    mkdir -p "/data/dropbear"
    mv "/sdcard/authorized_keys" "/data/dropbear/.ssh/"
    chown root "/data/dropbear/.ssh/authorized_keys"
	exit
	exit
EOF

# create host keys
rsa_key="/data/dropbear/dropbear_rsa_host_key"
dss_key="/data/dropbear/dropbear_dss_host_key"
ecdsa_key="/data/dropbear/dropbear_ecdsa_host_key"
ed25519_key="/data/dropbear/dropbear_ed25519_host_key"
adb shell <<-EOF
	su
	[ ! -f "$rsa_key" ] && dropbearkey -t rsa -f "$rsa_key"
	[ ! -f "$dss_key" ] && dropbearkey -t dss -f "$dss_key"
	[ ! -f "$ecdsa_key" ] && dropbearkey -t ecdsa -f "$ecdsa_key"
	[ ! -f "$ed25519_key" ] && dropbearkey -t ed25519 -f "$ed25519_key"
	exit
	exit
EOF

# set permissions and start dropbear
adb shell <<-EOF
    su
    mount -o rw,remount "/system"
    chmod 755 "/data/dropbear"
    chmod 644 /data/dropbear/dropbear*host_key
    chmod 755 "/data/dropbear/.ssh"
    chmod 600 "/data/dropbear/.ssh/authorized_keys"
    killall dropbear
    dropbear -s -g
	exit
	exit
EOF

# create init.d script to start dropbear on boot
adb shell <<-EOF
    su
    mount -o rw,remount "/system"
    echo "#!/system/bin/sh" > "/system/etc/init.d/30sshd"
    echo "dropbear -s -g" >> "/system/etc/init.d/30sshd"
    chmod 755 "/system/etc/init.d/30sshd"
	exit
	exit
EOF
