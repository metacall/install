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
		warning "None of the following programs are installed: $@}. Trying to detect common shells..."

		# Check common shells
		local shebang_program=$(programs_required_one /bin/sh /bin/bash /bin/dash)
		
		if [ -z "${shebang_program}" ]; then
			err "None of the following programs are installed: $@. One of them is required at least to find the shell. Aborting installation."
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

# Check all dependencies
dependencies() {
	print "Checking system dependencies."

	# Check if required programs are installed
	if [ $OPT_FROM_PATH -eq 0 ]; then
		programs_required tar grep tail awk rev cut uname echo printf rm id head chmod chown ln
	else
		programs_required tar grep echo printf rm id head chmod chown ln
	fi

	if [ $(id -u) -ne 0 ]; then
		programs_required tee
	fi

	# Check if download programs are installed
	if [ $OPT_FROM_PATH -eq 0 ]; then
		local download_program=$(programs_required_one curl wget)

		if [ -z "${download_program}" ]; then
			err "None of the following programs are installed: ${download_dependencies[@]}. One of them is required at least to download the tarball. Aborting installation."
			exit 1
		fi

		# Set up download command
		CMD_DOWNLOAD="${download_program}"
	fi

	# Locate shebang
	find_shebang

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

	# TODO: Implement other operative systems in metacall/distributable-linux
	case ${os} in
		Darwin)
			echo "osx"
			return
			;;
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

	# TODO: Implement other architectures in metacall/distributable-linux
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
	local url="https://github.com/metacall/distributable-linux/releases/latest"
	local tmp="/tmp/metacall-tarball.tar.gz"
	local os="$1"
	local arch="$2"

	print "Start to download the tarball."

	# TODO: Use ${CMD_DOWNLOAD} for improving this code?

	# Skip certificate checks
	if [ $OPT_NO_CHECK_CERTIFICATE -eq 1 ]; then
		if program curl; then
			local curl_cmd='curl --insecure'
		elif program wget; then
			local wget_cmd='wget --no-check-certificate'
		fi
	else
		if program curl; then
			local curl_cmd='curl'
		elif program wget; then
			local wget_cmd='wget'
		fi
	fi

	if program curl; then
		local tag_url=$(${curl_cmd} -Ls -o /dev/null -w %{url_effective} ${url})
	elif program wget; then
		local tag_url=$(${wget_cmd} -S -O /dev/null ${url} 2>&1 | grep Location: | tail -n 1 | awk '{print $2}')
	fi

	local version=$(printf "${tag_url}" | rev | cut -d '/' -f1 | rev)
	local final_url=$(printf "https://github.com/metacall/distributable-linux/releases/download/${version}/metacall-tarball-${os}-${arch}.tar.gz")
	local fail=false

	if program curl; then
		${curl_cmd} --retry 10 -f --create-dirs -LS ${final_url} --output ${tmp} || fail=true
	elif program wget; then
		${wget_cmd} --tries 10 -O ${tmp} ${final_url} || fail=true
	fi

	if "${fail}" == true; then
		rm -rf ${tmp}
		err "The tarball metacall-tarball-${os}-${arch}.tar.gz could not be downloaded." \
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

	print "Uncompress the tarball (needs sudo or root permissions)."

	if [ $(id -u) -eq 0 ]; then
		tar xzf ${tmp} -C /
		chmod -R 755 /gnu
	else
		sudo tar xzf ${tmp} -C /
		sudo chmod -R 755 /gnu
		sudo chown -R $(id -u):$(id -g) /gnu
	fi

	success "Tarball uncompressed successfully."

	# Add links for certificates
	local openssl_base="/gnu/store/`ls /gnu/store/ | grep openssl | head -n 1`/share"
	local openssl_dir="${openssl_base}/`ls ${openssl_base} | grep openssl`"
	local openssl_cert_dir="${openssl_dir}/certs"
	local openssl_cert_file="${openssl_dir}/cert.pem"
	local nss_cert_dir="/gnu/etc/ssl/certs"
	local nss_cert_file="/gnu/etc/ssl/certs/ca-certificates.crt"

	print "Linking certificates: ${openssl_cert_dir} => ${nss_cert_dir}"
	print "Linking certificate CA: ${openssl_cert_file} => ${nss_cert_file}"

	if [ $(id -u) -eq 0 ]; then
		rmdir ${openssl_cert_dir}
		ln -s ${nss_cert_dir} ${openssl_cert_dir}
		ln -s ${nss_cert_file} ${openssl_cert_file}
	else
		sudo rmdir ${openssl_cert_dir}
		sudo ln -s ${nss_cert_dir} ${openssl_cert_dir}
		sudo ln -s ${nss_cert_file} ${openssl_cert_file}
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
	local cli="/gnu/store/`ls /gnu/store/ | grep metacall | head -n 1`"
	local pythonpath_base="/gnu/store/`ls /gnu/store/ | grep python-next-3 | head -n 1`/lib"
	local pythonpath_dynlink="`ls -d ${pythonpath_base}/*/ | grep 'python3\.[0-9]*\/$'`lib-dynload"

	print "Installing the Command Line Interface shortcut (needs sudo or root permissions)."

	# Write shell script pointing to MetaCall CLI
	if [ $(id -u) -eq 0 ]; then
		# Create folder if it does not exist
		mkdir -p /usr/local/bin/

		# Write the shebang
		printf '#!' > /usr/local/bin/metacall
		echo "${CMD_SHEBANG}" >> /usr/local/bin/metacall

		# MetaCall Environment
		echo "export LOADER_LIBRARY_PATH=\"${cli}/lib\"" >> /usr/local/bin/metacall
		echo "export SERIAL_LIBRARY_PATH=\"${cli}/lib\"" >> /usr/local/bin/metacall
		echo "export DETOUR_LIBRARY_PATH=\"${cli}/lib\"" >> /usr/local/bin/metacall
		echo "export PORT_LIBRARY_PATH=\"${cli}/lib\"" >> /usr/local/bin/metacall
		echo "export CONFIGURATION_PATH=\"${cli}/configurations/global.json\"" >> /usr/local/bin/metacall
		echo "export LOADER_SCRIPT_PATH=\"\${LOADER_SCRIPT_PATH:-\`pwd\`}\"" >> /usr/local/bin/metacall

		# Certificates
		echo "export SSL_CERT_DIR=\"/gnu/etc/ssl/certs\"" >> /usr/local/bin/metacall
		echo "export SSL_CERT_FILE=\"/gnu/etc/ssl/certs/ca-certificates.crt\"" >> /usr/local/bin/metacall
		echo "export GIT_SSL_FILE=\"/gnu/etc/ssl/certs/ca-certificates.crt\"" >> /usr/local/bin/metacall
		echo "export GIT_SSL_CAINFO=\"/gnu/etc/ssl/certs/ca-certificates.crt\"" >> /usr/local/bin/metacall
		echo "export CURL_CA_BUNDLE=\"/gnu/etc/ssl/certs/ca-certificates.crt\"" >> /usr/local/bin/metacall

		# Locale
		echo "export GUIX_LOCPATH=\"/gnu/lib/locale\"" >> /usr/local/bin/metacall
		echo "export LANG=\"en_US.UTF-8\"" >> /usr/local/bin/metacall

		# Python
		echo "export PYTHONPATH=\"${pythonpath_base}:${pythonpath_dynlink}\"" >> /usr/local/bin/metacall

		# Set up command line
		echo "CMD=\`ls -a /gnu/bin | grep \"\$1\" | head -n 1\`" >> /usr/local/bin/metacall

		echo "if [ \"\${CMD}\" = \"\$1\" ]; then" >> /usr/local/bin/metacall
		echo "	if [ -z \"\${PATH-}\" ]; then export PATH=\"/gnu/bin\"; else PATH=\"/gnu/bin:\${PATH}\"; fi" >> /usr/local/bin/metacall
		echo "	\$@" >> /usr/local/bin/metacall
		echo "	exit \$?" >> /usr/local/bin/metacall
		echo "fi" >> /usr/local/bin/metacall

		# CLI
		echo "${cli}/metacallcli \$@" >> /usr/local/bin/metacall
		chmod 755 /usr/local/bin/metacall
	else
		# Create folder if it does not exist
		sudo mkdir -p /usr/local/bin/

		# Write the shebang
		printf "#!" | sudo tee /usr/local/bin/metacall > /dev/null
		echo "${CMD_SHEBANG}" | sudo tee -a /usr/local/bin/metacall > /dev/null

		# MetaCall Environment
		echo "export LOADER_LIBRARY_PATH=\"${cli}/lib\"" | sudo tee -a /usr/local/bin/metacall > /dev/null
		echo "export SERIAL_LIBRARY_PATH=\"${cli}/lib\"" | sudo tee -a /usr/local/bin/metacall > /dev/null
		echo "export DETOUR_LIBRARY_PATH=\"${cli}/lib\"" | sudo tee -a /usr/local/bin/metacall > /dev/null
		echo "export PORT_LIBRARY_PATH=\"${cli}/lib\"" | sudo tee -a /usr/local/bin/metacall > /dev/null
		echo "export CONFIGURATION_PATH=\"${cli}/configurations/global.json\"" | sudo tee -a /usr/local/bin/metacall > /dev/null
		echo "export LOADER_SCRIPT_PATH=\"\${LOADER_SCRIPT_PATH:-\`pwd\`}\"" | sudo tee -a /usr/local/bin/metacall > /dev/null

		# Certificates
		echo "export SSL_CERT_DIR=\"/gnu/etc/ssl/certs\"" | sudo tee -a /usr/local/bin/metacall > /dev/null
		echo "export SSL_CERT_FILE=\"/gnu/etc/ssl/certs/ca-certificates.crt\"" | sudo tee -a /usr/local/bin/metacall > /dev/null
		echo "export GIT_SSL_FILE=\"/gnu/etc/ssl/certs/ca-certificates.crt\"" | sudo tee -a /usr/local/bin/metacall > /dev/null
		echo "export GIT_SSL_CAINFO=\"/gnu/etc/ssl/certs/ca-certificates.crt\"" | sudo tee -a /usr/local/bin/metacall > /dev/null
		echo "export CURL_CA_BUNDLE=\"/gnu/etc/ssl/certs/ca-certificates.crt\"" | sudo tee -a /usr/local/bin/metacall > /dev/null

		# Locale
		echo "export GUIX_LOCPATH=\"/gnu/lib/locale\"" | sudo tee -a /usr/local/bin/metacall > /dev/null
		echo "export LANG=\"en_US.UTF-8\"" | sudo tee -a /usr/local/bin/metacall > /dev/null

		# Python
		echo "export PYTHONPATH=\"${pythonpath_base}:${pythonpath_dynlink}\"" | sudo tee -a /usr/local/bin/metacall > /dev/null

		# Set up command line
		echo "CMD=\`ls -a /gnu/bin | grep \"\$1\" | head -n 1\`" | sudo tee -a /usr/local/bin/metacall > /dev/null

		echo "if [ \"\${CMD}\" = \"\$1\" ]; then" | sudo tee -a /usr/local/bin/metacall > /dev/null
		echo "	if [ -z \"\${PATH-}\" ]; then export PATH=\"/gnu/bin\"; else PATH=\"/gnu/bin:\${PATH}\"; fi" | sudo tee -a /usr/local/bin/metacall > /dev/null
		echo "	\$@" | sudo tee -a /usr/local/bin/metacall > /dev/null
		echo "	exit \$?" | sudo tee -a /usr/local/bin/metacall > /dev/null
		echo "fi" | sudo tee -a /usr/local/bin/metacall > /dev/null

		# CLI
		echo "${cli}/metacallcli \$@" | sudo tee -a /usr/local/bin/metacall > /dev/null
		sudo chmod 755 /usr/local/bin/metacall
	fi

	success "CLI shortcut installed successfully."
}

binary_install() {
	# Show title
	title "MetaCall Self-Contained Binary Installer"

	# Check dependencies
	dependencies

	if [ $OPT_FROM_PATH -eq 0 ]; then
		# Detect operative system and architecture
		print "Detecting Operative System and Architecture."

		# Run to check if the operative system is supported
		operative_system > /dev/null 2>&1
		architecture > /dev/null 2>&1

		# Get the operative system and architecture into a variable
		local os="$(operative_system)"
		local arch="$(architecture)"

		success "Operative System (${os}) and Architecture (${arch}) detected."

		# Download tarball
		download ${os} ${arch}
	fi

	# Extract
	uncompress

	# Install CLI
	cli
}

docker_install() {
	# Show title
	title "MetaCall Docker Installer"

	# Check if Docker command is installed
	print "Checking Docker Dependency."

	programs_required docker echo chmod

	if [ $(id -u) -ne 0 ]; then
		programs_required tee
	fi

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
	print "Installing the Command Line Interface shortcut (needs sudo or root permissions)."

	local command="docker run --rm --network host -e \"LOADER_SCRIPT_PATH=/metacall/source\" -v \`pwd\`:/metacall/source -w /metacall/source -it metacall/cli \$@"

	# Write shell script wrapping the Docker run of MetaCall CLI image
	if [ $(id -u) -eq 0 ]; then
		mkdir -p /usr/local/bin/
		printf '#!' > /usr/local/bin/metacall
		echo "${CMD_SHEBANG}" >> /usr/local/bin/metacall
		echo "${command}" >> /usr/local/bin/metacall
		chmod 755 /usr/local/bin/metacall
	else
		sudo mkdir -p /usr/local/bin/
		printf '#!' | sudo tee /usr/local/bin/metacall > /dev/null
		echo "${CMD_SHEBANG}" | sudo tee -a /usr/local/bin/metacall > /dev/null
		echo "${command}" | sudo tee -a /usr/local/bin/metacall > /dev/null
		sudo chmod 755 /usr/local/bin/metacall
	fi
}

check_path_env() {
	# Check if the PATH contains the install path
	echo "${PATH}" | grep -i ":/usr/local/bin:"
	echo "${PATH}" | grep -i "^/usr/local/bin:"
	echo "${PATH}" | grep -i ":/usr/local/bin$"
	echo "${PATH}" | grep -i "^/usr/local/bin$"
}

uninstall() {
	# Delete all the previously installed files
	if [ $(id -u) -eq 0 ]; then
		rm -rf /usr/local/bin/metacall || true
		rm -rf /gnu || true
	else
		sudo rm -rf /usr/local/bin/metacall || true
		sudo rm -rf /gnu || true
	fi
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
		if [ $(id -u) -eq 0 ]; then
			mkdir -p /etc/profile.d/
			echo "export PATH=\"\${PATH}:/usr/local/bin\"" > /etc/profile.d/metacall.sh
			chmod 644 /etc/profile.d/metacall.sh
		else
			echo "export PATH=\"\${PATH}:/usr/local/bin\"" | sudo tee /etc/profile.d/metacall.sh > /dev/null
			sudo mkdir -p /etc/profile.d/
			sudo chmod 644 /etc/profile.d/metacall.sh
		fi

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
