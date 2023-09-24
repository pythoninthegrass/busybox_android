#!/usr/bin/env bash

set -eo pipefail     				# strict error checking, capture pipe fails

# logging
log_time=$(date +%Y%m%d_%H%M%S)
log_name="$(basename "$0" | cut -d. -f1)_${log_time}.log"
log_file="/tmp/${log_name}"
exec &> >(tee -i "$log_file")		# redirect standard error (stderr) and stdout to log

# get os
OS=$(uname -s)

# read /etc/os-release if os is linux
if [[ "$OS" = "Linux" ]]; then
	. "/etc/os-release"
fi

# $USER
if [[ "$OS" = 'Darwin' ]]; then
    logged_in_user=$(echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ && ! /loginwindow/ {print $3}')
elif [[ "$OS" = 'Linux' ]]; then
    [[ -n $(logname >/dev/null 2>&1) ]] && logged_in_user=$(logname) || logged_in_user=$(whoami)
else
    echo "Unknown OS: $OS. Exiting..."
    exit 1
fi

# $HOME
logged_in_home=$(eval echo "~${logged_in_user}")

# check if task is installed
installed=$(command -v task 2>/dev/null; echo $?)

# help function showing description
help() {
	cat <<- 'DESCRIPTION' >&2
	Install taskfile

	USAGE
	    ./bootstrap.sh
	DOCS
	    https://taskfile.dev/#/installation
	DESCRIPTION
}

if [[ $# -ne 0 ]] || [[ "$1" = "-h" ]] || [[ "$1" = "--help" ]]; then
	help
	exit 0
fi

main() {
	# install by os if not present
	if [ "$installed" = 1 ]; then
		if [ "$OS" = "Darwin" ] && [[ $(command -v brew 2>/dev/null; echo $?) -eq 0 ]]; then
			brew install go-task
		elif [ "$OS" = "Linux" ]; then
			if [ "$ID" = "debian" ] || [ "$ID" = "ubuntu" ]; then
				sudo apt install -y golang-go
				sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b "${logged_in_home}/.local/bin"
			elif [ "$ID" = "fedora" ] || [ "$ID" = "centos" ]; then
				sudo dnf install -y golang-go
				sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b "${logged_in_home}/.local/bin"
			elif [ "$ID" = "arch" ] || [ "$ID" = "manjaro" ]; then
				sudo pacman -S --noconfirm go
				sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b "${logged_in_home}/.local/bin"
			else
				echo "Please install task manually. See: https://taskfile.dev/installation/"
				exit 1
			fi
		fi
	else
		echo "task is already installed"
		exit 0
	fi
}
main

exit 0
