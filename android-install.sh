#!/usr/bin/env bash

set -e
set -uo pipefail

LOCAL_DIR=$(dirname $0)
OUTPUT_DIR="${LOCAL_DIR}/static-cross-bins/output/arm-linux-musleabi/bin"
FN="${1:-busybox}"
LOCAL_FN="${OUTPUT_DIR}/${FN}"
SCRIPT='android-remote-install.sh'
# /data is preferred over /sdcard because it will allow us to execute BB
TMP="/data"
TMP_FN="${TMP}/${FN}"
TGT="/system/bin"
TGT_FN="${TGT}/${FN}"

# compile busybox if not present
if [[ ! -f "$LOCAL_FN" ]]; then
	(cd "${LOCAL_DIR}/static-cross-bins"; \
	./docker_build.sh TARGET=arm-linux-musleabi $FN; \
	cd -)
fi

main() {
	# try to remount /system r/w
	adb remount
	adb shell mount | grep "\bsystem\b" | grep "\brw\b"
	# this is a remount form that works on "partially rooted devices"
	if [ $? -ne 0 ]; then
		adb push "$LOCAL_FN" "$TMP_FN"
		adb shell <<-EOF
		# su 				# not present on all devices (uncomment if needed)
		mount -oremount,rw /system
		"$TMP_FN" mount -oremount,rw /system
		"$TMP_FN" rm "$TMP_FN"
		exit
		exit
		EOF
	fi

	# we should be mounted r/w, push BB
	adb push "$LOCAL_FN" "$TGT_FN"

	# if push fails, try to upload to /sdcard and copy from there
	if [ $? -ne 0 ]; then
		adb push "$LOCAL_FN" "$TMP_FN"
		adb push "$LOCAL_FN" /mnt/SDCARD/
		adb shell <<-EOF
		# su 				# not present on all devices (uncomment if needed)
		cp "/mnt/SDCARD/${FN}" "$TGT_FN"
		chmod 755 "$TGT_FN"
		rm "/mnt/SDCARD/${FN}"
		"$TMP_FN" cp "$TMP_FN" "$TGT_FN"
		"$TMP_FN" rm "$TMP_FN"
		exit
		exit
		EOF
	fi

	# move the files over to an adb writable location
	adb push "${LOCAL_DIR}/${SCRIPT}" /mnt/SDCARD/
	adb shell <<-EOF
	# su 				# not present on all devices (uncomment if needed)
	"$TGT_FN" ash "/mnt/SDCARD/${SCRIPT}"
	rm "/mnt/SDCARD/${SCRIPT}"
	sync
	exit
	exit
	EOF

	# needs to be done separately to avoid "device busy" error
	adb shell mount -o remount,ro /system
}

main
