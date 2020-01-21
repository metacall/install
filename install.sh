#!/usr/bin/env bash

#	MetaCall Install Script by Parra Studios
#	Cross-platform set of scripts to install MetaCall infrastructure.
#
#	Copyright (C) 2016 - 2020 Vicente Eduardo Ferrer Garcia <vic798@gmail.com>
#
#	Licensed under the Apache License, Version 2.0 (the "License");
#	you may not use this file except in compliance with the License.
#	You may obtain a copy of the License at
#
#		http://www.apache.org/licenses/LICENSE-2.0
#
#	Unless required by applicable law or agreed to in writing, software
#	distributed under the License is distributed on an "AS IS" BASIS,
#	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#	See the License for the specific language governing permissions and
#	limitations under the License.

# Set mode
set -eu -o pipefail

# Check if program exists
program() {
	command -v $1 >/dev/null 2>&1
}

# Set up colors
if program tput; then
	ncolors=$(tput colors)
	if [ -n "$ncolors" ] && [ "$ncolors" -ge 8 ]; then
		bold="$(tput bold		|| echo)"
		normal="$(tput sgr0		|| echo)"
		black="$(tput setaf 0	|| echo)"
		red="$(tput setaf 1		|| echo)"
		green="$(tput setaf 2	|| echo)"
		yellow="$(tput setaf 3	|| echo)"
		blue="$(tput setaf 4	|| echo)"
		magenta="$(tput setaf 5	|| echo)"
		cyan="$(tput setaf 6	|| echo)"
		white="$(tput setaf 7	|| echo)"
	fi
fi

# Title message
title() {
	printf "%b\n\n" "${bold:-}$@${normal:-}"
}

# Warning message
warning() {
	printf "%b\n" "${yellow:-}‼${normal:-} $@"
}

# Error message
err() {
	printf "%b\n" "${red:-}✘${normal:-} $@"
}

# Print message
print() {
	printf "%b\n" "${normal:-}▷ $@"
}

# Success message
success() {
	printf "%b\n" "${green:-}✔${normal:-} $@"
}

# Check if a list of programs exist or aborts
programs_required() {
	for prog in "$@"; do
		if ! program ${prog}; then
			err "The program '${prog}' is not found, it is required to run the installer. Aborting installation."
			exit 1
		fi
	done
}

# Check if at least one program exists in the list or aborts
programs_required_one() {
	for prog in "$@"; do
		if program ${prog}; then
			return
		fi
	done

	err "None of the following programs are installed: $@. One of them is required at least to download the tarball. Aborting installation."
	exit 1
}

# Check all dependencies
dependencies() {
	print "Checking system dependencies"

	# Check if required programs are installed
	programs_required tar grep tail awk rev cut uname echo rm id find head chmod

	if [ $(id -u) -ne 0 ]; then
		programs_required tee
	fi

	# Check if download programs are installed
	programs_required_one curl wget

	# Detect sudo or run with root
	if ! program sudo && [ $(id -u) -ne 0 ]; then
		err "You need either having sudo installed or running this script as root. Aborting installation."
		exit 1
	fi

	success "Dependencies satisfied."
}

# Get operative system name
operative_system() {
	local os=$(uname)

	# TODO: Implement other operative systems in metacall/distributable
	case ${os} in
		# Darwin)
		# 	echo "osx"
		# 	return
		# 	;;
		# FreeBSD)
		# 	echo "freebsd"
		# 	return
		# 	;;
		Linux)
			echo "linux"
			return
			;;
	esac

	err "Operative System detected (${os}) is not supported." \
		"  Please, refer to https://github.com/metacall/install/issues and create a new issue." \
		"  Aborting installation."
	exit 1
}

# Get architecture name
architecture() {
	local arch=$(uname -m)

	# TODO: Implement other architectures in metacall/distributable
	case ${arch} in
		x86_64)
			echo "amd64"
			return
			;;
		# armv7l)
		# 	echo "arm"
		# 	return
		# 	;;
		# aarch64)
		# 	echo "arm64"
		# 	return
		# 	;;
	esac

	err "Architecture detected (${arch}) is not supported." \
		"  Please, refer to https://github.com/metacall/install/issues and create a new issue." \
		"  Aborting installation."
	exit 1
}

# Download tarball
download() {
	local url="https://github.com/metacall/distributable/releases/latest"
	local tmp="/tmp/metacall-tarball.tar.gz"
	local os="$1"
	local arch="$2"

	print "Start to download the tarball."

	if program curl; then
		local tag_url=$(curl -Ls -o /dev/null -w %{url_effective} ${url})
	elif program wget; then
		local tag_url=$(wget -O /dev/null ${url} 2>&1 | grep Location: | tail -n 1 | awk '{print $2}')
	fi

	local version=$(printf "${tag_url}" | rev | cut -d '/' -f1 | rev)
	local final_url=$(printf "https://github.com/metacall/distributable/releases/download/${version}/metacall-tarball-${os}-${arch}.tar.gz")
	local fail=false

	if program curl; then
		curl --retry 10 -f --create-dirs -LS ${final_url} --output ${tmp} || fail=true
	elif program wget; then
		wget --tries 10 -O ${tmp} ${final_url} || fail=true
	fi

	if "${fail}" == true; then
		rm -rf ${tmp}
		err "The tarball metacall-tarball-${os}-${arch}.tar.gz could not be downloaded." \
			"  Please, refer to https://github.com/metacall/install/issues and create a new issue." \
			"  Aborting installation."
		exit 1
	fi

	success "Tarball downloaded."
}

# Extract the tarball (requires root or sudo)
uncompress() {
	local tmp="/tmp/metacall-tarball.tar.gz"

	print "Uncompress the tarball (needs sudo or root permissions)."

	if [ $(id -u) -eq 0 ]; then
		tar xzf ${tmp} -C /
		chmod -R 755 /gnu/store
	else
		sudo tar xzf ${tmp} -C /
		sudo chmod -R 755 /gnu/store
	fi

	success "Tarball uncompressed successfully."

	# Clean the tarball
	print "Cleaning the tarball."

	rm -rf ${tmp}

	success "Tarball cleaned successfully."
}

# Install the CLI
cli() {
	local cli="$(find /gnu/store/ -type d -name '*metacall*[^R]' | head -n 1)"

	print "Installing the Command Line Interface shortcut (needs sudo or root permissions)."

	# Write shell script pointing to MetaCall CLI
	if [ $(id -u) -eq 0 ]; then
		echo "#!/usr/bin/env sh" &> /bin/metacall
		echo "export LOADER_LIBRARY_PATH=\"${cli}/lib\"" >> /bin/metacall
		echo "export SERIAL_LIBRARY_PATH=\"${cli}/lib\"" >> /bin/metacall
		echo "export DETOUR_LIBRARY_PATH=\"${cli}/lib\"" >> /bin/metacall
		echo "export PORT_LIBRARY_PATH=\"${cli}/lib\"" >> /bin/metacall
		echo "export CONFIGURATION_PATH=\"${cli}/share/metacall/configurations/global.json\"" >> /bin/metacall
		echo "${cli}/metacallcli \$@" >> /bin/metacall
		chmod 755 /bin/metacall
	else
		echo "#!/usr/bin/env sh" | sudo tee /bin/metacall > /dev/null
		echo "export LOADER_LIBRARY_PATH=\"${cli}/lib\"" | sudo tee -a /bin/metacall > /dev/null
		echo "export SERIAL_LIBRARY_PATH=\"${cli}/lib\"" | sudo tee -a /bin/metacall > /dev/null
		echo "export DETOUR_LIBRARY_PATH=\"${cli}/lib\"" | sudo tee -a /bin/metacall > /dev/null
		echo "export PORT_LIBRARY_PATH=\"${cli}/lib\"" | sudo tee -a /bin/metacall > /dev/null
		echo "export CONFIGURATION_PATH=\"${cli}/share/metacall/configurations/global.json\"" | sudo tee -a /bin/metacall > /dev/null
		echo "${cli}/metacallcli \$@" | sudo tee -a /bin/metacall > /dev/null
		sudo chmod 755 /bin/metacall
	fi

	success "CLI shortcut installed successfully."
}

main() {
	# Show title
	title "MetaCall Self-Contained Binary Installer"

	# Check dependencies
	dependencies

	# Detect operative system and architecture
	print "Detecting Operative System and Architecture."

	local os="$(operative_system)"
	local arch="$(architecture)"

	success "Operative System (${os}) and Architecture (${arch}) detected."

	# Download tarball
	download ${os} ${arch}

	# Extract
	uncompress

	# Install CLI
	cli

	# Show information
	success "MetaCall has been installed." \
		"  Run 'metacall' command for start the CLI and type help for more information about CLI commands."
}

# Run main
main
