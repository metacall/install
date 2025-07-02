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

if [ -n "${METACALL_INSTALL_DEBUG:-}" ]; then
	set -euxo pipefail
else
	set -eu
fi

# Program options
OPT_DOCKER_INSTALL=0
OPT_NO_CHECK_CERTIFICATE=0
OPT_NO_DOCKER_FALLBACK=0
OPT_UPDATE=0
OPT_UNINSTALL=0
OPT_FROM_PATH=0
OPT_FROM_PATH_TARGET=""
OPT_VERSION="latest"

# Program commands
CMD_DOWNLOAD=""
CMD_SHEBANG=""
CMD_SUDO=""

# Platform dependant variables
PLATFORM_OS=""
PLATFORM_ARCH=""
PLATFORM_PREFIX=""
PLATFORM_BIN=""

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
	if [ "$1" = '--version' ]; then
		shift
		OPT_VERSION="tag/v$1"
	fi
	# Get the next argument
	shift
done

# Check if program exists
program() {
	command -v $1 >/dev/null 2>&1
}

# List of colors
bold=""
normal=""
black=""
red=""
green=""
yellow=""
blue=""
magenta=""
cyan=""
white=""

# Set up colors
if program tput; then
	ncolors=$(tput colors 2>/dev/null || echo)
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
	printf "%b\n" "${yellow:-}⚠️ $@${normal:-}"
}

# Error message
err() {
	printf "%b\n" "${red:-}✘ $@${normal:-}"
}

# Print message
print() {
	printf "%b\n" "${normal:-}▷ $@"
}

# Success message
success() {
	printf "%b\n" "${green:-}✔️ $@${normal:-}"
}

# Debug message
debug() {
	if [ -n "${METACALL_INSTALL_DEBUG:-}" ]; then
		printf "%b\n" "${normal:-}⚙ $@"
	fi
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
	# Check common shells
	local sh_program=$(programs_required_one bash dash sh)

	if [ -z "${sh_program:-}" ]; then
		err "None of the following programs are installed: 'bash' 'dash' 'sh'. One of them is required at least to find the shell. Aborting installation."
		exit 1
	fi

	# Detect where is the 'env' found in order to set properly the shebang
	local env_program=$(programs_required_one env)

	if [ -z "${env_program:-}" ]; then
		CMD_SHEBANG="${env_program} ${sh_program}"
	else
		# Set up shebang command by default
		CMD_SHEBANG="/usr/bin/env ${sh_program}"
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
	programs_required uname tar grep echo printf rm id head chmod chown ln tee touch read

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
			PLATFORM_BIN="${PLATFORM_PREFIX}/bin"
			return
			;;
		# FreeBSD)
		# 	PLATFORM_OS="freebsd"
		# 	return
		# 	;;
		Linux)
			PLATFORM_OS="linux"
			PLATFORM_PREFIX="/gnu"
			PLATFORM_BIN="/usr/local/bin"
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
	local tag_url=$(${CMD_DOWNLOAD} --retry 10 -f -sL -o /dev/null -w %{url_effective} "https://github.com/metacall/distributable-${PLATFORM_OS}/releases/${OPT_VERSION}")
	local final_url=$(download_url "${tag_url}")

	${CMD_DOWNLOAD} --retry 10 -f --create-dirs -L ${final_url} --output "/tmp/metacall-tarball.tar.gz" || echo "true"
}

# Download tarball with wget
download_wget() {
	local tag_url=$(${CMD_DOWNLOAD} --tries 10 -S -O /dev/null "https://github.com/metacall/distributable-${PLATFORM_OS}/releases/${OPT_VERSION}" 2>&1 | grep Location: | tail -n 1 | awk '{print $2}')
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
		${CMD_SUDO} rm -rf "/tmp/metacall-tarball.tar.gz"
		err "The tarball metacall-tarball-${PLATFORM_OS}-${PLATFORM_ARCH}.tar.gz could not be downloaded." \
			"  Please, refer to https://github.com/metacall/install/issues and create a new issue." \
			"  Aborting installation."
		exit 1
	fi

	success "Tarball downloaded."
}

# Extract the tarball (requires root or sudo)
uncompress() {
	if [ $OPT_FROM_PATH -eq 1 ]; then
		local tmp="${OPT_FROM_PATH_TARGET}"
	else
		local tmp="/tmp/metacall-tarball.tar.gz"
	fi

	local share_dir="${PLATFORM_PREFIX}/share/metacall"
	local install_list="${share_dir}/metacall-binary-install.txt"
	local install_tmp_list="/tmp/metacall-binary-install.txt"

	print "Uncompress the tarball."

	# List the files inside the tar and store them into a txt for running
	# chown selectively and for uninstalling it later on, install files
	# that do not exist already in the system, this will allow to make the
	# installer idempotent, so later on we delete only our files
	${CMD_SUDO} rm -rf ${install_tmp_list}

	# Disable debug info
	if [ -n "${METACALL_INSTALL_DEBUG:-}" ]; then
		set +x
	fi

	# The sed is needed in order to store properly the paths because they
	# are listed always with prefix ./ and we have to check with -e if they
	# are present as absoulte path / in the system, then we write them again with
	# the dot . so they are written as ./ for uncompressing them
	${CMD_SUDO} tar -tf "${tmp}" | sed 's/^\.//' | while IFS= read -r file; do
		if [ ! -e "${file}" ]; then
			echo "${file}" >> ${install_tmp_list}
		fi
	done

	if [ -n "${METACALL_INSTALL_DEBUG:-}" ]; then
		set -x
	fi

	# Check if the file list was created properly
	if [ ! -f "${install_tmp_list}" ]; then
		err "The file list could not be created properly, this means that metacall was already installed but the command is not available. Aborting installation."
		${CMD_SUDO} rm -rf "/tmp/metacall-tarball.tar.gz"
		exit 1
	fi

	# Give read write permissions for all
	${CMD_SUDO} chmod 666 "${install_tmp_list}"

	# Uncompress the tarball. Use the install list to uncompress only the files that are new in the filesystem,
	# don't restore mtime (-m), don't restore user:group (-o) and avoid overwriting existing files (-k).
	local user="$(id -u)"
	local group="$(id -g)"
	${CMD_SUDO} tar xzf "${tmp}" -m -o -k -C /

	# Check for valid uncompression
	if [ ! -e "${PLATFORM_PREFIX}" ]; then
		err "The tarball could not be uncompressed properly. Aborting installation."
		${CMD_SUDO} rm -rf "/tmp/metacall-tarball.tar.gz"
		exit 1
	fi

	# Create shared directory
	if [ ! -d "${share_dir}" ]; then
		${CMD_SUDO} mkdir -p ${share_dir}
		${CMD_SUDO} chmod 775 ${share_dir}
	fi

	# Move the install list to the share directory
	${CMD_SUDO} mv "${install_tmp_list}" "${install_list}"

	# TODO: Tag with a timestamp the files in order to uninstall them later on
	# only if they have not been modified since the install time

	success "Tarball uncompressed successfully."

	# In Linux, add links for certificates
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

		# Store the certificate links in the install list
		echo "${openssl_cert_dir}" | ${CMD_SUDO} tee -a "${install_list}" > /dev/null
		echo "${openssl_cert_file}" | ${CMD_SUDO} tee -a "${install_list}" > /dev/null

	# In MacOS, create a binary list for allowing 'metacall npm ...' and other commands
	elif [ "${PLATFORM_OS}" = "macos" ]; then
		local bin_list="${share_dir}/metacall-binary-install-bin.txt"

		# Get the binary files installed, use the tar directly because if we use the ${install_list} it is
		# going to exclude the binaries that were already installed, also do not include metacall itself
		${CMD_SUDO} tar -tf "${tmp}" | sed 's/^\.//' \
			| grep -E "^${PLATFORM_BIN}/.+" \
			| grep -v "^${PLATFORM_BIN}/metacall" \
			| ${CMD_SUDO} tee "${bin_list}" > /dev/null

		# Give read write permissions for all
		${CMD_SUDO} chmod 666 "${bin_list}"

		# Add the bin list to the install list, this helper file will allow to handle package managers from metacall
		echo "${bin_list}" | ${CMD_SUDO} tee -a "${install_list}" > /dev/null
	fi

	# Clean the tarball
	if [ $OPT_FROM_PATH -eq 0 ]; then
		print "Cleaning the tarball."
		${CMD_SUDO} rm -rf "${tmp}"
		success "Tarball cleaned successfully."
	fi
}

# Install the CLI
cli() {
	print "Installing the Command Line Interface shortcut."

	if [ "${PLATFORM_OS}" = "linux" ]; then
		# Write shell script pointing to MetaCall CLI
		local pythonpath_base="${PLATFORM_PREFIX}/store/`ls ${PLATFORM_PREFIX}/store/ | grep python-3 | head -n 1`/lib"
		local pythonpath_dynlink="`ls -d ${pythonpath_base}/*/ | grep 'python3\.[0-9]*\/$'`lib-dynload"

		# Create folder and file
		${CMD_SUDO} mkdir -p "${PLATFORM_BIN}/"
		${CMD_SUDO} touch "${PLATFORM_BIN}/metacall"

		# Write the shebang
		printf "#!" | ${CMD_SUDO} tee "${PLATFORM_BIN}/metacall" > /dev/null
		echo "${CMD_SHEBANG}" | ${CMD_SUDO} tee -a "${PLATFORM_BIN}/metacall" > /dev/null

		# MetaCall Environment
		echo "export LOADER_SCRIPT_PATH=\"\${LOADER_SCRIPT_PATH:-\`pwd\`}\"" | ${CMD_SUDO} tee -a "${PLATFORM_BIN}/metacall" > /dev/null

		# Certificates
		echo "export GIT_SSL_FILE=\"${PLATFORM_PREFIX}/etc/ssl/certs/ca-certificates.crt\"" | ${CMD_SUDO} tee -a "${PLATFORM_BIN}/metacall" > /dev/null
		echo "export GIT_SSL_CAINFO=\"${PLATFORM_PREFIX}/etc/ssl/certs/ca-certificates.crt\"" | ${CMD_SUDO} tee -a "${PLATFORM_BIN}/metacall" > /dev/null

		# Locale
		echo "export GUIX_LOCPATH=\"${PLATFORM_PREFIX}/lib/locale\"" | ${CMD_SUDO} tee -a "${PLATFORM_BIN}/metacall" > /dev/null
		echo "export LANG=\"en_US.UTF-8\"" | ${CMD_SUDO} tee -a "${PLATFORM_BIN}/metacall" > /dev/null

		# Python
		echo "export PYTHONPATH=\"${pythonpath_base}:${pythonpath_dynlink}\"" | ${CMD_SUDO} tee -a "${PLATFORM_BIN}/metacall" > /dev/null

		# Guix generated environment variables (TODO: Move all environment variables to metacall/distributable-linux)
		echo ". ${PLATFORM_PREFIX}/etc/profile" | ${CMD_SUDO} tee -a "${PLATFORM_BIN}/metacall" > /dev/null

		# Set up command line
		echo "CMD=\`ls -a ${PLATFORM_PREFIX}/bin | grep \"\$1\" | head -n 1\`" | ${CMD_SUDO} tee -a "${PLATFORM_BIN}/metacall" > /dev/null

		echo "if [ \"\${CMD}\" = \"\$1\" ]; then" | ${CMD_SUDO} tee -a "${PLATFORM_BIN}/metacall" > /dev/null
		echo "	if [ -z \"\${PATH-}\" ]; then export PATH=\"${PLATFORM_PREFIX}/bin\"; else PATH=\"${PLATFORM_PREFIX}/bin:\${PATH}\"; fi" | ${CMD_SUDO} tee -a "${PLATFORM_BIN}/metacall" > /dev/null
		echo "	\$@" | ${CMD_SUDO} tee -a "${PLATFORM_BIN}/metacall" > /dev/null
		echo "	exit \$?" | ${CMD_SUDO} tee -a "${PLATFORM_BIN}/metacall" > /dev/null
		echo "fi" | ${CMD_SUDO} tee -a "${PLATFORM_BIN}/metacall" > /dev/null

		# CLI
		echo "${PLATFORM_PREFIX}/bin/metacallcli \$@" | ${CMD_SUDO} tee -a "${PLATFORM_BIN}/metacall" > /dev/null
		${CMD_SUDO} chmod 775 "${PLATFORM_BIN}/metacall"

	elif [ "${PLATFORM_OS}" = "macos" ]; then
		local share_dir="${PLATFORM_PREFIX}/share/metacall"
		local install_list="${share_dir}/metacall-binary-install.txt"
		local bin_list="${share_dir}/metacall-binary-install-bin.txt"

		# Remove last line of the shell script for the CLI
		${CMD_SUDO} sed -i '' -e '$d' "${PLATFORM_BIN}/metacall"

		# In case of having an argument
		echo "if [ \"\$1\" != \"\" ]; then" | ${CMD_SUDO} tee -a "${PLATFORM_BIN}/metacall" > /dev/null

		# Set up command line
		echo "	CMD=\"\$(grep \"${PLATFORM_BIN}/\$1\" \"${bin_list}\" | head -n 1)\"" | ${CMD_SUDO} tee -a "${PLATFORM_BIN}/metacall" > /dev/null

		# If we find a binary on the list, execute it
		echo "	if [ \"\${CMD}\" != \"\" ]; then" | ${CMD_SUDO} tee -a "${PLATFORM_BIN}/metacall" > /dev/null
		echo "		if [ -z \"\${PATH-}\" ]; then export PATH=\"${PLATFORM_BIN}\"; else PATH=\"${PLATFORM_BIN}:\${PATH}\"; fi" | ${CMD_SUDO} tee -a "${PLATFORM_BIN}/metacall" > /dev/null
		echo "		\$@" | ${CMD_SUDO} tee -a "${PLATFORM_BIN}/metacall" > /dev/null
		echo "		exit \$?" | ${CMD_SUDO} tee -a "${PLATFORM_BIN}/metacall" > /dev/null
		echo "	fi" | ${CMD_SUDO} tee -a "${PLATFORM_BIN}/metacall" > /dev/null
		echo "fi" | ${CMD_SUDO} tee -a "${PLATFORM_BIN}/metacall" > /dev/null

		# Execute the CLI
		echo "\${PREFIX}/metacallcli \$@" | ${CMD_SUDO} tee -a "${PLATFORM_BIN}/metacall" > /dev/null
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
	else
		# Check if the tarball is correct
		if [ ! -f "$OPT_FROM_PATH_TARGET" ]; then
			err "The tarball $OPT_FROM_PATH_TARGET does not exist, exiting..."
			exit 1
		fi

		case "$OPT_FROM_PATH_TARGET" in
			*.tar.gz)
				# Valid format (noop)
				:
				;;
			*.pkg)
				# Only valid in darwin
				if [ "${PLATFORM_OS}" != "macos" ]; then
					err "The tarball $OPT_FROM_PATH_TARGET has pkg format, and this is only valid on MacOS, exiting..."
					exit 1
				fi

				# TODO: Implement pkg for MacOS (https://superuser.com/a/525395)
				err "The tarball $OPT_FROM_PATH_TARGET has pkg format, and it is not implemented, use tar.gz instead for now, exiting..."
				exit 1
				;;
			*)
				# Invalid format
				err "The tarball $OPT_FROM_PATH_TARGET has an invalid format, exiting..."
				exit 1
				;;
		esac
	fi

	# Extract
	uncompress

	# Install CLI
	cli

	# Install additional dependencies
	additional_packages_install

	# Make metacall available into PATH
	path_install
}

docker_install() {
	# Show title
	title "MetaCall Docker Installer"

	# Check if Docker command is installed
	print "Checking Docker dependencies."

	# Dependencies
	programs_required docker echo chmod tee touch

	# Check platform
	platform

	# Locate shebang
	find_shebang

	# Pull MetaCall CLI Docker Image
	print "Pulling MetaCall CLI Image."

	if ! (docker pull metacall/cli:latest); then
		err "Docker image could not be pulled. Aborting installation."
		exit 1
	fi

	# Install Docker based CLI
	print "Installing the Command Line Interface shortcut."

	# Check for sudo permissions
	find_sudo

	local command="docker run --rm --network host -e \"LOADER_SCRIPT_PATH=/metacall/source\" -v \`pwd\`:/metacall/source -w /metacall/source -it metacall/cli \$@"

	# Write shell script wrapping the Docker run of MetaCall CLI image
	${CMD_SUDO} mkdir -p "${PLATFORM_BIN}/"
	${CMD_SUDO} touch "${PLATFORM_BIN}/metacall"
	printf '#!' | ${CMD_SUDO} tee "${PLATFORM_BIN}/metacall" > /dev/null
	echo "${CMD_SHEBANG}" | ${CMD_SUDO} tee -a "${PLATFORM_BIN}/metacall" > /dev/null
	echo "${command}" | ${CMD_SUDO} tee -a "${PLATFORM_BIN}/metacall" > /dev/null
	${CMD_SUDO} chmod 775 "${PLATFORM_BIN}/metacall"
	${CMD_SUDO} chown $(id -u):$(id -g) "${PLATFORM_BIN}/metacall"

	# Make metacall available into PATH
	path_install
}

check_path_env() {
	# Check if the PATH contains the install path (${PLATFORM_BIN} aka /usr/local/bin on Linux), checks 4 cases:
	#   1) /usr/local/bin
	#   2) /usr/local/bin:/usr/bin
	#   3) /usr/bin:/usr/local/bin
	#   4) /usr/bin:/usr/local/bin:/bin
	echo "${PATH}" | grep -e "\(^\|:\)${PLATFORM_BIN}\(:\|$\)"
}

uninstall() {
	# Show title
	title "MetaCall Uninstall"

	# Check dependencies
	programs_required rm cat awk sort cut read readlink

	# Check platform
	platform

	# Check for sudo permissions
	find_sudo

	print "Deleting MetaCall binary installation, this operation may take a while."

	# Delete the launcher
	${CMD_SUDO} rm -f "${PLATFORM_BIN}/metacall"

	# Delete shortcuts if any
	${CMD_SUDO} rm -f "/etc/profile.d/metacall.sh"

	# Delete all the previously installed files
	local install_list="$(readlink -f "${PLATFORM_PREFIX}/share/metacall/metacall-binary-install.txt")"
	local install_tmp_list="/tmp/metacall-binary-install.txt"

	# Move install list to temp folder
	${CMD_SUDO} mv "${install_list}" "${install_tmp_list}"

	# Disable debug info
	if [ -n "${METACALL_INSTALL_DEBUG:-}" ]; then
		set +x
	fi

	print "Deleting MetaCall symlinks."

	# First delete the symbolic links and get files and folders
	while IFS= read -r line; do
		# Reinterpret escaped unicode characters
		local path="$(printf "%b" "${line}")"

		# Delete symlink
		if [ -L "${path}" ]; then
			${CMD_SUDO} rm -f "${path}"
		fi
	done < "${install_tmp_list}"

	print "Deleting MetaCall files."

	# Then delete the files
	while IFS= read -r line; do
		# Reinterpret escaped unicode characters
		local path="$(printf "%b" "${line}")"

		# Delete file
		if [ -f "${path}" ]; then
			${CMD_SUDO} rm -f "${path}"
		fi
	done < "${install_tmp_list}"

	print "Deleting MetaCall folders."

	# Then delete the folders
	cat "${install_tmp_list}" | awk '{ print length, $0 }' | sort -r -n -s | cut -d ' ' -f2- | while IFS= read -r line; do
		# Reinterpret escaped unicode characters
		local path="$(printf "%b" "${line}")"

		# Delete folder only if it is empty
		if [ -d "${path}" ]; then
			if [ -n "${METACALL_INSTALL_DEBUG:-}" ]; then
				# Print debug information if the folder is not empty
				${CMD_SUDO} rmdir "${path}" || (warning "Invalid file type '${path}', expected empty folder." && ls -la -R "${path}")
			else
				# Skip if the folder is not empty
				${CMD_SUDO} rmdir "${path}" || true
			fi
		fi
	done

	if [ -n "${METACALL_INSTALL_DEBUG:-}" ]; then
		set -x
	fi

	# Remove the list itself
	${CMD_SUDO} rm -f "${install_tmp_list}"
}

package_install() {
	local package_name="$1"
	local install_dir="${PLATFORM_PREFIX}/lib/node_modules"
	local bin_dir="${PLATFORM_PREFIX}/bin"
	local install_list="${PLATFORM_PREFIX}/share/metacall/metacall-binary-install.txt"

	# Create additional dependencies folder
	${CMD_SUDO} mkdir -p "${install_dir}"
	${CMD_SUDO} mkdir -p "${bin_dir}"

	# Get full paths
	local package_install_dir="$(readlink -f "${install_dir}")/${package_name}"
	local package_bin_dir="$(readlink -f "${bin_dir}")/${package_name}"

	# Install package
	${CMD_SUDO} metacall npm install --global --prefix="${package_install_dir}" @metacall/${package_name}
	echo "#!${CMD_SHEBANG}" | ${CMD_SUDO} tee "${package_bin_dir}" > /dev/null
	echo "metacall node ${package_install_dir}/lib/node_modules/@metacall/${package_name}/dist/index.js \$@" | ${CMD_SUDO} tee -a "${package_bin_dir}" > /dev/null
	${CMD_SUDO} chmod 775 "${package_bin_dir}"
	${CMD_SUDO} chown $(id -u):$(id -g) "${package_bin_dir}"

	# Give permissions and ownership
	${CMD_SUDO} chmod -R 775 "${package_install_dir}"
	${CMD_SUDO} chown -R $(id -u):$(id -g) "${package_install_dir}"

	# Add the files to the install list
	${CMD_SUDO} find "${package_install_dir}" | ${CMD_SUDO} tee -a "${install_list}" > /dev/null
	${CMD_SUDO} echo "${package_bin_dir}" | ${CMD_SUDO} tee -a "${install_list}" > /dev/null

	# In MacOS, add package launcher to the binary list, so it can be found later on
	if [ "${PLATFORM_OS}" = "macos" ]; then
		local share_dir="${PLATFORM_PREFIX}/share/metacall"
		local bin_list="${share_dir}/metacall-binary-install-bin.txt"

		# Add the binary to the binary list without readlink, use the binary prefix instead
		echo "${bin_dir}/${package_name}" | ${CMD_SUDO} tee -a "${bin_list}" > /dev/null
	fi
}

additional_packages_install() {
	print "Installing additional dependencies."

	# Install Deploy
	package_install "deploy"

	# Install FaaS
	package_install "faas"

	success "Additional dependencies installed."
}

path_install() {
	debug "Checking if ${PLATFORM_BIN} is in PATH environment variable ($PATH)."

	local path="$(check_path_env)"

	# Check if ${PLATFORM_BIN} (aka /usr/local/bin in Linux) is in PATH
	if [ -z "${path}" ]; then
		# Add ${PLATFORM_BIN} to PATH
		echo "export PATH=\"\${PATH}:${PLATFORM_BIN}\"" | ${CMD_SUDO} tee "/etc/profile.d/metacall.sh" > /dev/null
		${CMD_SUDO} mkdir -p /etc/profile.d/
		${CMD_SUDO} chmod 644 /etc/profile.d/metacall.sh

		warning "MetaCall install path is not present in PATH so we added it for you." \
			"  The command 'metacall' will be available in your subsequent terminal instances." \
			"  Run 'source /etc/profile' to make 'metacall' command available to your current terminal instance."
	fi
}

main() {
	if ! program metacall; then
		if [ $OPT_UPDATE -eq 1 ] || [ $OPT_UNINSTALL -eq 1 ]; then
			err "MetaCall is not installed."
			exit 1
		fi
	else
		# Skip asking for updates if the update flag is enabled
		if [ $OPT_UPDATE -eq 0 ] && [ $OPT_UNINSTALL -eq 0 ]; then
			# Check if the shell is interactive
			case $- in
				*i*) local interactive=1;;
				*) local interactive=0;;
			esac

			if [ $interactive -ne 0 ]; then
				# Ask for Docker fallback if we are in a terminal
				ask "MetaCall is already installed. Do you want to update it?"
			else
				warning "MetaCall is already installed."
				exit 0
			fi
		fi

		uninstall

		# Exit if the user only wants to uninstall
		if [ $OPT_UNINSTALL -eq 1 ]; then
			success "MetaCall has been successfully uninstalled."
			exit 0
		fi
	fi

	if [ $OPT_DOCKER_INSTALL -eq 1 ]; then
		# Run docker install
		docker_install
	else
		# TODO: Remember to do MacOS install fallback to brew in order to compile metacall
		# spctl --status

		# Run binary install
		if ! (binary_install); then
			# Exit if Docker fallback is disabled
			if [ $OPT_NO_DOCKER_FALLBACK -eq 1 ]; then
				err "Binary installation has failed and fallback to Docker installation is disabled, exiting..."
				exit 1
			fi

			# Required program for ask question to the user
			programs_required read

			# Check if the shell is interactive
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
			docker_install
		fi
	fi

	# Show information
	success "MetaCall has been installed." \
		" Run 'metacall' command for start the CLI and type help for more information about CLI commands."
}

# Run main
main
