#!/usr/bin/env bash

set -e
set -uo pipefail

# ryan:
# I modified the original script as below for use with my rooted Atrix phone.
# I'm using a retail build that still thinks it's a production device.
# The best way to state this is that ro.secure=1 in default.prop, but su
# executes under a shell on the device and yields root permissions
#
# Another oddity that I encountered is that mv can fail giving
# errors citing cross-device linkage:
#     It seems that this error is given because mv tries
#     to move the hard link to the data, but fails because
#     in this case, the src and dest filesystems aren't the same.
#
# Symptoms of this state are that the following adb commands fail (not an ordered list, but executing any atomically):
#   adb remount
#   adb ls /data/app/
#   adb root
# but executing this works fine:
#   adb shell
#   $ su
#   $ ls /data/app/
#
# Gnurou:
# Another issue is that some devices come with most basic commands like mount
# removed, which requires us to use BB to remount /system read-write. This is
# why we first upload BB to a temporary, executable location before moving it
# to /system/bin

LOCAL_DIR=$(dirname $0)
OUTPUT_DIR="${LOCAL_DIR}/static-cross-bins/output/arm-linux-musleabi/bin"
BBNAME="busybox"
LOCALBB="${OUTPUT_DIR}/${BBNAME}"
SCRIPT='android-remote-install.sh'
# /data is preferred over /sdcard because it will allow us to execute BB
TMP="/data"
TMPBB="${TMP}/busybox"
TGT="/system/bin"
TGTBB="${TGT}/busybox"

# compile busybox if not present
if [[ ! -f "$LOCALBB" ]]; then
	bash -c "${LOCAL_DIR}/static-cross-bins/docker_build.sh TARGET=arm-linux-musleabi busybox"
fi

main() {
	# try to remount /system r/w
	adb remount
	adb shell mount | grep "\bsystem\b" | grep "\brw\b"
	# this is a remount form that works on "partially rooted devices"
	if [ $? -ne 0 ]; then
		adb push "$LOCALBB" "$TMPBB"
		adb shell <<-EOF
		su
		mount -oremount,rw /system
		"$TMPBB" mount -oremount,rw /system
		"$TMPBB" rm "$TMPBB"
		exit
		exit
		EOF
	fi

	# we should be mounted r/w, push BB
	adb push "$LOCALBB" "$TGTBB"

	# if push fails, try to upload to /sdcard and copy from there
	if [ $? -ne 0 ]; then
		adb push "$LOCALBB" "$TMPBB"
		adb push "$LOCALBB" /mnt/SDCARD/
		adb shell <<-EOF
		su
		cp "/mnt/SDCARD/${BBNAME}" "$TGTBB"
		chmod 755 "$TGTBB"
		rm "/mnt/SDCARD/${BBNAME}"
		"$TMPBB" cp "$TMPBB" "$TGTBB"
		"$TMPBB" rm "$TMPBB"
		exit
		exit
		EOF
	fi

	# move the files over to an adb writable location
	adb push "${LOCAL_DIR}/${SCRIPT}" /mnt/SDCARD/
	adb shell <<-EOF
	su
	"$TGTBB" ash "/mnt/SDCARD/${SCRIPT}"
	rm "/mnt/SDCARD/${SCRIPT}"
	sync
	exit
	exit
	EOF

	# needs to be done separately to avoid "device busy" error
	adb shell mount -o remount,ro /system
}

main
