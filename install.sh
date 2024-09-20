#!/usr/bin/env bash

#	MetaCall Install Script by Parra Studios
#	Cross-platform set of scripts to install MetaCall infrastructure.
#
#	Copyright (C) 2016 - 2024 Vicente Eduardo Ferrer Garcia <vic798@gmail.com>
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

# Program options
OPT_DOCKER_INSTALL=0
OPT_NO_CHECK_CERTIFICATE=0
OPT_NO_DOCKER_FALLBACK=0
OPT_UPDATE=0
OPT_UNINSTALL=0
OPT_FROM_PATH=0
OPT_FROM_PATH_TARGET=""

# Program commands
CMD_DOWNLOAD=""
CMD_SHEBANG=""
CMD_SUDO=""

# Platform dependant variables
PLATFORM_OS=""
PLATFORM_ARCH=""
PLATFORM_PREFIX=""

# Check for command line arguments
while [ $# -ne 0 ]
do
	if [ "$1" = '--docker-install' ]; then
		OPT_DOCKER_INSTALL=1
	fi
	if [ "$1" = '--no-check-certificate' ]; then
		OPT_NO_CHECK_CERTIFICATE=1
	fi
	if [ "$1" = '--no-docker-fallback' ]; then
		OPT_NO_DOCKER_FALLBACK=1
	fi
	if [ "$1" = '--update' ]; then
		OPT_UPDATE=1
	fi
	if [ "$1" = '--uninstall' ]; then
		OPT_UNINSTALL=1
	fi
	if [ "$1" = '--from-path' ]; then
		OPT_FROM_PATH=1
		shift
		OPT_FROM_PATH_TARGET="$1"
	fi
	# Get the next argument
	shift
done

# Check if program exists
program() {
	command -v $1 >/dev/null 2>&1
}

# Set up colors
if program tput; then
	ncolors=$(tput colors)
	if [ -n "$ncolors" ] && [ "$ncolors" -ge 8 ]; then
		bold="$(tput bold       || echo)"
		normal="$(tput sgr0     || echo)"
		black="$(tput setaf 0   || echo)"
		red="$(tput setaf 1     || echo)"
		green="$(tput setaf 2   || echo)"
		yellow="$(tput setaf 3  || echo)"
		blue="$(tput setaf 4    || echo)"
		magenta="$(tput setaf 5 || echo)"
		cyan="$(tput setaf 6    || echo)"
		white="$(tput setaf 7   || echo)"
	fi
fi

# Title message
title() {
	printf "%b\n\n" "${normal:-}${bold:-}$@${normal:-}"
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

# Ask message
ask() {
	while true; do
		printf "${normal:-}▷ $@? [Y/n] "
		read -r yn < /dev/tty
		case $yn in
			[Yy]* ) break;;
			[Nn]* ) exit 1;;
			* ) warning "Please answer yes [Yy] or no [Nn].";;
		esac
	done
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
			echo "${prog}"
			return
		fi
	done
}

# Find proper shebang for the launcher script
find_shebang() {
	# Detect where is the 'env' found in order to set properly the shebang
	local shebang_program=$(programs_required_one /usr/bin/env /bin/env)

	if [ -z "${shebang_program}" ]; then
		warning "None of the following programs are installed: /usr/bin/env /bin/env. Trying to detect common shells..."

		# Check common shells
		local shebang_program=$(programs_required_one /bin/sh /bin/bash /bin/dash)
		
		if [ -z "${shebang_program}" ]; then
			err "None of the following programs are installed: /bin/sh /bin/bash /bin/dash. One of them is required at least to find the shell. Aborting installation."
			exit 1
		else
			# Set up shebang command
			CMD_SHEBANG="${shebang_program}"
		fi
	else
		# Set up shebang command based on env
		CMD_SHEBANG="${shebang_program} sh"
	fi
}

# Detect sudo or run with root
find_sudo() {
	if ! program sudo && [ $(id -u) -ne 0 ]; then
		err "You need either having sudo installed or running this script as root. Aborting installation."
		exit 1
	fi

	if [ $(id -u) -ne 0 ]; then
		CMD_SUDO="sudo"
	fi
}

# Check all dependencies
dependencies() {
	print "Checking system dependencies."

	# Check if required programs are installed
	programs_required uname tar grep echo printf rm id head chmod chown ln tee touch xargs

	# Check if download programs are installed
	if [ $OPT_FROM_PATH -eq 0 ]; then
		programs_required tail awk rev cut

		local download_program=$(programs_required_one curl wget)

		if [ -z "${download_program}" ]; then
			err "None of the following programs are installed: curl wget. One of them is required at least to download the tarball. Aborting installation."
			exit 1
		fi

		# Set up download command
		CMD_DOWNLOAD="${download_program}"
	fi

	# Locate shebang
	find_shebang

	# Check for sudo permissions
	find_sudo

	success "Dependencies satisfied."
}

# Get operative system name
operative_system() {
	local os=$(uname)

	# TODO: Implement other operative systems (FreeBSD, ...)
	case ${os} in
		Darwin)
			PLATFORM_OS="macos"
			if [ "${PLATFORM_ARCH}" = "arm64" ]; then
				PLATFORM_PREFIX="/opt/homebrew"
			elif [ "${PLATFORM_ARCH}" = "amd64" ]; then
				PLATFORM_PREFIX="/usr/local"
			fi
			return
			;;
		# FreeBSD)
		# 	PLATFORM_OS="freebsd"
		# 	return
		# 	;;
		Linux)
			PLATFORM_OS="linux"
			PLATFORM_PREFIX="/gnu"
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

	# TODO: Implement other architectures in metacall/distributable-linux (armv7l, aarch64, ...)
	case ${arch} in
		x86_64)
			PLATFORM_ARCH="amd64"
			return
			;;
		arm64)
			PLATFORM_ARCH="arm64"
			return
			;;
	esac

	err "Architecture detected (${arch}) is not supported." \
		"  Please, refer to https://github.com/metacall/install/issues and create a new issue." \
		"  Aborting installation."
	exit 1
}

# Detect platform details
platform() {
	# Detect operative system and architecture
	print "Detecting Operative System and Architecture."

	# Get the operative system and architecture
	architecture
	operative_system

	success "Operative System (${PLATFORM_OS}) and Architecture (${PLATFORM_ARCH}) detected."
}

# Get download url from tag
download_url() {
	local version=$(printf "$1" | rev | cut -d '/' -f1 | rev)
	printf "https://github.com/metacall/distributable-${PLATFORM_OS}/releases/download/${version}/metacall-tarball-${PLATFORM_OS}-${PLATFORM_ARCH}.tar.gz"
}

# Download tarball with cURL
download_curl() {
	local tag_url=$(${CMD_DOWNLOAD} -Ls -o /dev/null -w %{url_effective} "https://github.com/metacall/distributable-${PLATFORM_OS}/releases/latest")
	local final_url=$(download_url "${tag_url}")

	${CMD_DOWNLOAD} --retry 10 -f --create-dirs -LS ${final_url} --output "/tmp/metacall-tarball.tar.gz" || echo "true"
}

# Download tarball with wget
download_wget() {
	local tag_url=$(${CMD_DOWNLOAD} -S -O /dev/null "https://github.com/metacall/distributable-${PLATFORM_OS}/releases/latest" 2>&1 | grep Location: | tail -n 1 | awk '{print $2}')
	local final_url=$(download_url "${tag_url}")

	${CMD_DOWNLOAD} --tries 10 -O "/tmp/metacall-tarball.tar.gz" ${final_url} || echo "true"
}

# Download tarball
download() {
	local download_func=download_${CMD_DOWNLOAD}

	print "Start to download the tarball."

	# Skip certificate checks
	if [ $OPT_NO_CHECK_CERTIFICATE -eq 1 ]; then
		local insecure_curl="--insecure"
		local insecure_wget="--no-check-certificate"
		CMD_DOWNLOAD="$CMD_DOWNLOAD $(eval echo -e \"\$insecure_$CMD_DOWNLOAD\")"
	fi

	# Download depending on the program selected
	local fail="$(eval echo -e \"\$\(${download_func}\)\")"

	if [ "${fail}" = "true" ]; then
		rm -rf "/tmp/metacall-tarball.tar.gz"
		err "The tarball metacall-tarball-${PLATFORM_OS}-${PLATFORM_ARCH}.tar.gz could not be downloaded." \
			"  Please, refer to https://github.com/metacall/install/issues and create a new issue." \
			"  Aborting installation."
		exit 1
	fi

	success "Tarball ${version} downloaded."
}

# Extract the tarball (requires root or sudo)
uncompress() {
	if [ $OPT_FROM_PATH -eq 1 ]; then
		local tmp="${OPT_FROM_PATH_TARGET}"
	else
		local tmp="/tmp/metacall-tarball.tar.gz"
	fi

	local share_dir="${PLATFORM_PREFIX}/share/metacall"
	local deps_dir="${PLATFORM_PREFIX}/deps"
	local install_list="${share_dir}/metacall-binary-install.txt"
	local install_tmp_list="/tmp/metacall-binary-install.txt"

	print "Uncompress the tarball."

	# List the files inside the tar and store them into a txt for running
	# chmod and chown selectively and for uninstalling it later on
	${CMD_SUDO} tar -tf ${tmp} > ${install_tmp_list}
	${CMD_SUDO} chmod 666 ${install_tmp_list}

	# Uncompress the tarball
	${CMD_SUDO} tar xzf ${tmp} -C /

	# Create shared directory
	if [ ! -d "${share_dir}" ]; then
		${CMD_SUDO} mkdir -p ${share_dir}
	fi

	# Move the install list to the share directory
	mv "${install_tmp_list}" "${install_list}"

	# Remove first char of the list
	${CMD_SUDO} sed -i 's/^.//' ${install_list}

	# Create additional dependencies folder and add it to the install list
	${CMD_SUDO} mkdir -p ${deps_dir}
	echo "${deps_dir}" | ${CMD_SUDO} tee -a ${install_list} > /dev/null

	# Store the install list itself
	printf "${install_list}" | ${CMD_SUDO} tee -a ${install_list} > /dev/null

	# Give execution permissions and ownership
	${CMD_SUDO} xargs -d '\n' -a ${install_list} -P 4 -I {} chown $(id -u):$(id -g) "{}"

	success "Tarball uncompressed successfully."

	# Add links for certificates
	if [ "${PLATFORM_OS}" = "linux" ]; then
		local openssl_base="${PLATFORM_PREFIX}/store/`ls ${PLATFORM_PREFIX}/store/ | grep openssl | head -n 1`/share"
		local openssl_dir="${openssl_base}/`ls ${openssl_base} | grep openssl`"
		local openssl_cert_dir="${openssl_dir}/certs"
		local openssl_cert_file="${openssl_dir}/cert.pem"
		local nss_cert_dir="${PLATFORM_PREFIX}/etc/ssl/certs"
		local nss_cert_file="${PLATFORM_PREFIX}/etc/ssl/certs/ca-certificates.crt"

		print "Linking certificates: ${openssl_cert_dir} => ${nss_cert_dir}"
		print "Linking certificate CA: ${openssl_cert_file} => ${nss_cert_file}"

		${CMD_SUDO} rmdir ${openssl_cert_dir}
		${CMD_SUDO} ln -s ${nss_cert_dir} ${openssl_cert_dir}
		${CMD_SUDO} ln -s ${nss_cert_file} ${openssl_cert_file}
	fi

	# Clean the tarball
	if [ $OPT_FROM_PATH -eq 0 ]; then
		print "Cleaning the tarball."
		rm -rf ${tmp}
		success "Tarball cleaned successfully."
	fi
}

# Install the CLI
cli() {
	print "Installing the Command Line Interface shortcut."

	if [ "${PLATFORM_OS}" = "linux" ]; then
		# Write shell script pointing to MetaCall CLI
		local pythonpath_base="/gnu/store/`ls /gnu/store/ | grep python-3 | head -n 1`/lib"
		local pythonpath_dynlink="`ls -d ${pythonpath_base}/*/ | grep 'python3\.[0-9]*\/$'`lib-dynload"

		# Create folder and file
		${CMD_SUDO} mkdir -p /usr/local/bin/
		${CMD_SUDO} touch /usr/local/bin/metacall

		# Write the shebang
		printf "#!" | ${CMD_SUDO} tee /usr/local/bin/metacall > /dev/null
		echo "${CMD_SHEBANG}" | ${CMD_SUDO} tee -a /usr/local/bin/metacall > /dev/null

		# MetaCall Environment
		echo "export LOADER_SCRIPT_PATH=\"\${LOADER_SCRIPT_PATH:-\`pwd\`}\"" | ${CMD_SUDO} tee -a /usr/local/bin/metacall > /dev/null

		# Certificates
		echo "export GIT_SSL_FILE=\"/gnu/etc/ssl/certs/ca-certificates.crt\"" | ${CMD_SUDO} tee -a /usr/local/bin/metacall > /dev/null
		echo "export GIT_SSL_CAINFO=\"/gnu/etc/ssl/certs/ca-certificates.crt\"" | ${CMD_SUDO} tee -a /usr/local/bin/metacall > /dev/null

		# Locale
		echo "export GUIX_LOCPATH=\"/gnu/lib/locale\"" | ${CMD_SUDO} tee -a /usr/local/bin/metacall > /dev/null
		echo "export LANG=\"en_US.UTF-8\"" | ${CMD_SUDO} tee -a /usr/local/bin/metacall > /dev/null

		# Python
		echo "export PYTHONPATH=\"${pythonpath_base}:${pythonpath_dynlink}\"" | ${CMD_SUDO} tee -a /usr/local/bin/metacall > /dev/null

		# Guix generated environment variables (TODO: Move all environment variables to metacall/distributable-linux)
		echo ". /gnu/etc/profile" | ${CMD_SUDO} tee -a /usr/local/bin/metacall > /dev/null

		# Set up command line
		echo "CMD=\`ls -a /gnu/bin | grep \"\$1\" | head -n 1\`" | ${CMD_SUDO} tee -a /usr/local/bin/metacall > /dev/null

		echo "if [ \"\${CMD}\" = \"\$1\" ]; then" | ${CMD_SUDO} tee -a /usr/local/bin/metacall > /dev/null
		echo "	if [ -z \"\${PATH-}\" ]; then export PATH=\"/gnu/bin\"; else PATH=\"/gnu/bin:\${PATH}\"; fi" | ${CMD_SUDO} tee -a /usr/local/bin/metacall > /dev/null
		echo "	\$@" | ${CMD_SUDO} tee -a /usr/local/bin/metacall > /dev/null
		echo "	exit \$?" | ${CMD_SUDO} tee -a /usr/local/bin/metacall > /dev/null
		echo "fi" | ${CMD_SUDO} tee -a /usr/local/bin/metacall > /dev/null

		# CLI
		echo "/gnu/bin/metacallcli \$@" | ${CMD_SUDO} tee -a /usr/local/bin/metacall > /dev/null
		${CMD_SUDO} chmod 755 /usr/local/bin/metacall
	fi

	success "CLI shortcut installed successfully."
}

binary_install() {
	# Show title
	title "MetaCall Self-Contained Binary Installer"

	# Check dependencies
	dependencies

	# Check platform
	platform

	if [ $OPT_FROM_PATH -eq 0 ]; then
		# Download tarball
		download
	fi

	# Extract
	uncompress

	# Install CLI
	cli

	# Install additional dependencies
	additional_packages_install
}

docker_install() {
	# Show title
	title "MetaCall Docker Installer"

	# Check if Docker command is installed
	print "Checking Docker Dependency."

	programs_required docker echo chmod tee touch

	# Locate shebang
	find_shebang

	# Pull MetaCall CLI Docker Image
	print "Pulling MetaCall CLI Image."

	docker pull metacall/cli:latest

	result=$?

	if [ $result -ne 0 ]; then
		err "Docker image could not be pulled. Aborting installation."
		exit 1
	fi

	# Install Docker based CLI
	print "Installing the Command Line Interface shortcut."

	# Check for sudo permissions
	find_sudo

	local command="docker run --rm --network host -e \"LOADER_SCRIPT_PATH=/metacall/source\" -v \`pwd\`:/metacall/source -w /metacall/source -it metacall/cli \$@"

	# Write shell script wrapping the Docker run of MetaCall CLI image
	${CMD_SUDO} mkdir -p /usr/local/bin/
	${CMD_SUDO} touch /usr/local/bin/metacall
	printf '#!' | ${CMD_SUDO} tee /usr/local/bin/metacall > /dev/null
	echo "${CMD_SHEBANG}" | ${CMD_SUDO} tee -a /usr/local/bin/metacall > /dev/null
	echo "${command}" | ${CMD_SUDO} tee -a /usr/local/bin/metacall > /dev/null
	${CMD_SUDO} chmod 755 /usr/local/bin/metacall
}

check_path_env() {
	# Check if the PATH contains the install path (/usr/local/bin), checks 4 cases:
	#   1) /usr/local/bin
	#   2) /usr/local/bin:/usr/bin
	#   3) /usr/bin:/usr/local/bin
	#   4) /usr/bin:/usr/local/bin:/bin
	echo "${PATH}" | grep -e '\(^\|:\)/usr/local/bin\(:\|$\)'
}

uninstall() {
	# Check for sudo permissions
	find_sudo

	# Delete all the previously installed files
	${CMD_SUDO} rm -rf /usr/local/bin/metacall || true
	${CMD_SUDO} rm -rf /gnu || true

	# TODO: This is super unsafe, we should store somewhere the list of installed files, and delete the list of files only.
	# This current methodology is going to destroy any Guix installation if present, we must avoid this...
}

additional_packages_install() {
	local install_dir="/gnu/deps"
	local bin_dir="/gnu/bin"

	print "Installing additional dependencies."

	# Install Deploy
	${CMD_SUDO} metacall npm install --global --prefix="${install_dir}/deploy" @metacall/deploy
	echo "#!${CMD_SHEBANG}" | ${CMD_SUDO} tee ${bin_dir}/deploy > /dev/null
	echo "metacall node ${install_dir}/deploy/lib/node_modules/@metacall/deploy/dist/index.js \$@" | ${CMD_SUDO} tee ${bin_dir}/deploy > /dev/null
	${CMD_SUDO} chmod 755 "${bin_dir}/deploy"
	${CMD_SUDO} chown $(id -u):$(id -g) "${bin_dir}/deploy"

	# Install FaaS
	${CMD_SUDO} metacall npm install --global --prefix="${install_dir}/faas" @metacall/faas
	echo "#!${CMD_SHEBANG}" | ${CMD_SUDO} tee ${bin_dir}/faas > /dev/null
	echo "metacall node ${install_dir}/faas/lib/node_modules/@metacall/faas/dist/index.js \$@" | ${CMD_SUDO} tee ${bin_dir}/faas > /dev/null
	${CMD_SUDO} chmod 755 "${bin_dir}/faas"
	${CMD_SUDO} chown $(id -u):$(id -g) "${bin_dir}/faas"

	# Give permissions and ownership
	${CMD_SUDO} chmod -R 755 "${install_dir}"
	${CMD_SUDO} chown -R $(id -u):$(id -g) "${install_dir}"

	success "Additional dependencies installed."
}

main() {
	# Check if the tarball is correct
	if [ $OPT_FROM_PATH -eq 1 ]; then
		if [ ! -f "$OPT_FROM_PATH_TARGET" ]; then
			err "The tarball $OPT_FROM_PATH_TARGET does not exist, exiting..."
			exit 1
		fi
	fi

	if program metacall; then
		# Skip asking for updates if the update flag is enabled
		if [ $OPT_UPDATE -eq 0 ] && [ $OPT_UNINSTALL -eq 0 ]; then
			ask "MetaCall is already installed. Do you want to update it?\n  ${red:-}${bold:-}Warning: This operation will delete the /gnu folder${normal:-}. Continue"
		fi

		uninstall
	fi

	# Exit if the user only wants to uninstall
	if [ $OPT_UNINSTALL -eq 1 ]; then
		success "MetaCall has been successfully uninstalled"
		exit 0
	fi

	# Required program for recursive calls
	programs_required wait

	if [ $OPT_DOCKER_INSTALL -eq 1 ]; then
		# Run docker install
		docker_install $@ &
		proc=$!
		wait ${proc}
		result=$?

		if [ $result -ne 0 ]; then
			exit 1
		fi
	else
		# Run binary install
		binary_install $@ &
		proc=$!
		wait ${proc}
		result=$?

		# TODO: Remember to do MacOs install fallback to brew in order to compile metacall

		if [ $result -ne 0 ]; then
			# Exit if Docker fallback is disabled
			if [ $OPT_NO_DOCKER_FALLBACK -eq 1 ]; then
				exit 1
			fi

			# Required program for ask question to the user
			programs_required read

			# Check if the sell is interactive
			case $- in
				*i*) local interactive=1;;
				*) local interactive=0;;
			esac

			if [ $interactive -ne 0 ]; then
				# Ask for Docker fallback if we are in a terminal
				ask "Binary installation has failed, do you want to fallback to Docker installation"
			else
				# Run Docker fallback otherwise
				warning "Binary installation has failed, fallback to Docker installation."
			fi

			# On error, fallback to docker install
			docker_install $@ &
			proc=$!
			wait ${proc}
			result=$?

			if [ $result -ne 0 ]; then
				exit 1
			fi
		fi
	fi

	local path="$(check_path_env)"

	# Check if /usr/local/bin is in PATH
	if [ -z "${path}" ]; then
		# Add /usr/local/bin to PATH
		echo "export PATH=\"\${PATH}:/usr/local/bin\"" | ${CMD_SUDO} tee /etc/profile.d/metacall.sh > /dev/null
		${CMD_SUDO} mkdir -p /etc/profile.d/
		${CMD_SUDO} chmod 644 /etc/profile.d/metacall.sh

		warning "MetaCall install path is not present in PATH so we added it for you." \
			"  The command 'metacall' will be available in your subsequent terminal instances." \
			"  Run 'source /etc/profile' to make 'metacall' command available to your current terminal instance."
	fi

	# Show information
	success "MetaCall has been installed." \
		"  Run 'metacall' command for start the CLI and type help for more information about CLI commands."
}

# Run main
main
